import Foundation
import Network
import Darwin

/// 局域网共享服务：在 App 内启动一个轻量 HTTP 服务，
/// 同一 Wi-Fi 下的电脑可用浏览器访问并创建记录。
@MainActor
final class ShareServer: ObservableObject {
    static let shared = ShareServer()
    static let defaultPort: UInt16 = 8787

    @Published private(set) var isRunning = false
    @Published private(set) var port: UInt16 = defaultPort
    @Published private(set) var ipAddress: String?
    @Published private(set) var lastError: String?

    private let server = LanHTTPServer { request, respond in
        Task { @MainActor in
            ShareServer.shared.handle(request, respond: respond)
        }
    }

    var shareURL: URL? {
        guard isRunning, let ip = ipAddress else { return nil }
        return URL(string: "http://\(ip):\(port)")
    }

    var shareURLString: String? {
        shareURL?.absoluteString
    }

    // MARK: - 启动 / 停止

    func start() {
        guard !isRunning else { return }
        port = Self.defaultPort
        lastError = nil
        ipAddress = Self.deviceIPAddress()
        server.start(port: port) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.isRunning = false
                self.lastError = "启动失败：\(error.localizedDescription)"
            } else {
                self.isRunning = true
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        server.stop()
        isRunning = false
    }

    // MARK: - 路由

    private func handle(_ request: HTTPRequest, respond: @escaping (HTTPResponse) -> Void) {
        switch (request.method, request.path) {
        case ("GET", "/"), ("GET", "/index.html"):
            respond(.html(ShareHTML.page))
        case ("GET", "/api/items"):
            respond(itemListResponse())
        case ("POST", "/api/items"):
            handleCreate(request, respond: respond)
        default:
            respond(.error("接口不存在", status: 404, statusText: "Not Found"))
        }
    }

    /// 列表接口：出于安全考虑不返回密码内容
    private func itemListResponse() -> HTTPResponse {
        let formatter = ISO8601DateFormatter()
        let items: [[String: Any]] = VaultRepository.shared.items.map { item in
            [
                "id": item.id.uuidString,
                "project": item.displayName,
                "username": item.username,
                "updatedAt": Int(item.updatedAt.timeIntervalSince1970),
                "updatedText": formatter.string(from: item.updatedAt)
            ]
        }
        return .json(["items": items])
    }

    private func handleCreate(_ request: HTTPRequest, respond: @escaping (HTTPResponse) -> Void) {
        struct Payload: Decodable {
            var project: String?
            var username: String?
            var password: String?
            var data1: String?
            var data2: String?
            var note: String?
        }

        guard !request.body.isEmpty else {
            respond(.error("请求体为空"))
            return
        }

        let payload: Payload
        do {
            payload = try JSONDecoder().decode(Payload.self, from: request.body)
        } catch {
            respond(.error("数据格式不正确：\(error.localizedDescription)"))
            return
        }

        let project = (payload.project ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !project.isEmpty else {
            respond(.error("「项目」不能为空"))
            return
        }

        let item = PasswordItem(
            project: project,
            username: payload.username ?? "",
            password: payload.password ?? "",
            data1: payload.data1 ?? "",
            data2: payload.data2 ?? "",
            note: payload.note ?? ""
        )
        VaultRepository.shared.add(item)
        respond(.json(["ok": true, "project": project], status: 201, statusText: "Created"))
    }

    // MARK: - 获取本机局域网 IP

    nonisolated static func deviceIPAddress() -> String? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        var candidates: [(name: String, ip: String)] = []
        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            let interface = current.pointee
            let name = String(cString: interface.ifa_name)
            if let sockaddrPtr = interface.ifa_addr, sockaddrPtr.pointee.sa_family == UInt8(AF_INET) {
                var addr = sockaddr_in()
                memcpy(&addr, sockaddrPtr, MemoryLayout<sockaddr_in>.size)
                let ip = String(cString: inet_ntoa(addr.sin_addr))
                if !ip.isEmpty {
                    candidates.append((name, ip))
                }
            }
            pointer = interface.ifa_next
        }

        // 优先 en0（Wi-Fi），其次其它 en / bridge 接口
        if let en0 = candidates.first(where: { $0.name == "en0" }) {
            return en0.ip
        }
        return candidates
            .filter { $0.name.hasPrefix("en") || $0.name.hasPrefix("bridge") }
            .sorted { $0.name < $1.name }
            .first?.ip
    }
}
