import Foundation
import Security

/// 随机密码生成器（使用系统安全随机数 SecRandomCopyBytes）
enum PasswordGenerator {
    static func generate(length: Int = 16, useSymbols: Bool = true) -> String {
        let lower = "abcdefghijkmnopqrstuvwxyz"
        let upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
        let digits = "23456789"
        let symbols = "!@#$%^&*()-_=+[]{}?"

        var pool = lower + upper + digits
        if useSymbols { pool += symbols }

        let chars = Array(pool)
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        guard status == errSecSuccess else {
            return fallback(length: length, pool: chars)
        }
        return String(bytes.map { chars[Int($0) % chars.count] })
    }

    private static func fallback(length: Int, pool: [Character]) -> String {
        String((0..<length).compactMap { _ in pool.randomElement() })
    }
}
