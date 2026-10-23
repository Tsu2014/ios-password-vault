import Foundation
import Network

// MARK: - 请求 / 响应模型

/// 一个已解析的 HTTP 请求
struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data
}

/// 一个待发送的 HTTP 响应
struct HTTPResponse {
    var status: Int
    var statusText: String
    var contentType: String
    var body: Data

    init(status: Int = 200,
         statusText: String = "OK",
         contentType: String = "application/json; charset=utf-8",
         body: Data = Data()) {
        self.status = status
        self.statusText = statusText
        self.contentType = contentType
        self.body = body
    }

    static func json(_ value: Any, status: Int = 200, statusText: String = "OK") -> HTTPResponse {
        let data = (try? JSONSerialization.data(withJSONObject: value)) ?? Data()
        return HTTPResponse(status: status, statusText: statusText, body: data)
    }

    static func html(_ html: String) -> HTTPResponse {
        HTTPResponse(contentType: "text/html; charset=utf-8", body: Data(html.utf8))
    }

    static func error(_ message: String, status: Int = 400, statusText: String = "Bad Request") -> HTTPResponse {
        HTTPResponse.json(["error": message], status: status, statusText: statusText)
    }
}

enum HTTPServerError: LocalizedError {
    case invalidPort

    var errorDescription: String? {
        switch self {
        case .invalidPort:
            return "端口号无效"
        }
    }
}

// MARK: - 极简 HTTP 服务器（基于 Network.framework）

/// 面向局域网的轻量 HTTP 服务：每个连接只处理一个请求，响应后即断开（Connection: close），
/// 覆盖“手机开服务、电脑浏览器访问提交表单”的场景足够。
final class LanHTTPServer {
    typealias Handler = (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void

    private let handler: Handler
    private let queue = DispatchQueue(label: "com.tsu2014.keyvault.http")
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: ClientConnection] = [:]
    private let lock = NSLock()

    static let maxRequestSize = 4 * 1024 * 1024

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    /// 启动监听。onReady 在主线程回调，error 为 nil 表示成功。
    func start(port: UInt16, onReady: @escaping (_ error: Error?) -> Void) {
        queue.async { [weak self] in
            guard let self = self, self.listener == nil else {
                DispatchQueue.main.async { onReady(nil) }
                return
            }
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                DispatchQueue.main.async { onReady(HTTPServerError.invalidPort) }
                return
            }
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            do {
                let listener = try NWListener(using: parameters, on: nwPort)
                listener.newConnectionHandler = { [weak self] connection in
                    self?.accept(connection)
                }
                listener.stateUpdateHandler = { [weak self] state in
                    if case .failed(let error) = state {
                        self?.stopInternal()
                        DispatchQueue.main.async { onReady(error) }
                    }
                }
                self.listener = listener
                listener.start(queue: self.queue)
                DispatchQueue.main.async { onReady(nil) }
            } catch {
                DispatchQueue.main.async { onReady(error) }
            }
        }
    }

    /// 停止监听并断开所有连接
    func stop() {
        queue.async { [weak self] in
            self?.stopInternal()
        }
    }

    private func stopInternal() {
        listener?.cancel()
        listener = nil
        lock.lock()
        let current = Array(connections.values)
        connections.removeAll()
        lock.unlock()
        current.forEach { $0.close() }
    }

    private func accept(_ connection: NWConnection) {
        let client = ClientConnection(connection: connection, queue: queue) { [weak self] request, respond in
            guard let self = self else {
                respond(HTTPResponse.error("服务已关闭", status: 503, statusText: "Service Unavailable"))
                return
            }
            self.handler(request, respond)
        }
        lock.lock()
        connections[client.id] = client
        lock.unlock()
        client.onClose = { [weak self] id in
            guard let self = self else { return }
            self.lock.lock()
            self.connections.removeValue(forKey: id)
            self.lock.unlock()
        }
        client.start()
    }
}

// MARK: - 单个连接：解析请求、转发处理、写出响应

private final class ClientConnection {
    var id: ObjectIdentifier { ObjectIdentifier(self) }

    private let connection: NWConnection
    private let queue: DispatchQueue
    private let handler: (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void

    private var buffer = Data()
    private var responded = false
    private var finished = false

    var onClose: ((ObjectIdentifier) -> Void)?

    init(connection: NWConnection,
         queue: DispatchQueue,
         handler: @escaping (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void) {
        self.connection = connection
        self.queue = queue
        self.handler = handler
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.finish()
            default:
                break
            }
        }
        connection.start(queue: queue)
        receive()
    }

    func close() {
        finish()
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 512 * 1024) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let data = data, !data.isEmpty {
                self.buffer.append(data)
                if self.buffer.count > LanHTTPServer.maxRequestSize {
                    self.respond(.error("请求体过大", status: 413, statusText: "Payload Too Large"))
                    return
                }
                if self.dispatchIfReady() { return }
            }
            if error != nil {
                self.finish()
                return
            }
            if isComplete {
                self.finish()
                return
            }
            self.receive()
        }
    }

    /// 头部与请求体全部到齐后派发给 handler；返回 true 表示本连接结束读取
    private func dispatchIfReady() -> Bool {
        guard let headerRange = buffer.range(of: Data("\r\n\r\n".utf8)) else {
            if buffer.count > 64 * 1024 {
                respond(.error("请求头过大", status: 431, statusText: "Request Header Fields Too Large"))
                return true
            }
            return false
        }

        let headerText = String(decoding: buffer.subdata(in: buffer.startIndex..<headerRange.lowerBound), as: UTF8.self)
        var lines = headerText.components(separatedBy: "\r\n")
        guard !lines.isEmpty else {
            respond(.error("请求格式错误"))
            return true
        }

        let requestLine = lines.removeFirst()
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else {
            respond(.error("请求行格式错误"))
            return true
        }

        var headers: [String: String] = [:]
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[line.startIndex..<colon])
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            let value = String(line[line.index(after: colon)...])
                .trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }

        let method = String(parts[0]).uppercased()
        let path = String(parts[1])
        let contentLength = Int(headers["content-length"] ?? "0") ?? 0

        guard contentLength >= 0 else {
            respond(.error("Content-Length 无效"))
            return true
        }
        let bodyStart = headerRange.upperBound
        let bodyEnd = bodyStart + contentLength
        guard bodyEnd <= buffer.endIndex else { return false } // 请求体尚未接收完整

        let body = buffer.subdata(in: bodyStart..<bodyEnd)
        let request = HTTPRequest(method: method, path: path, headers: headers, body: body)
        handler(request) { [weak self] response in
            self?.respond(response)
        }
        return true
    }

    private func respond(_ response: HTTPResponse) {
        guard !responded else { return }
        responded = true

        let head = """
        HTTP/1.1 \(response.status) \(response.statusText)\r
        Content-Type: \(response.contentType)\r
        Content-Length: \(response.body.count)\r
        Cache-Control: no-store\r
        Access-Control-Allow-Origin: *\r
        Connection: close\r
        \r

        """
        var payload = Data(head.utf8)
        payload.append(response.body)

        connection.send(content: payload, completion: .contentProcessed { [weak self] _ in
            self?.finish()
        })
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onClose?(id)
        connection.cancel()
    }
}
