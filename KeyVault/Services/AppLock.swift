import Foundation
import LocalAuthentication

/// App 解锁：可选用 Face ID / Touch ID / 设备密码保护整个保险库。
@MainActor
final class AppLock: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var lastErrorMessage: String?

    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    var isEnabled: Bool { settings.lockEnabled }

    func lock() {
        guard settings.lockEnabled else { return }
        isUnlocked = false
    }

    func unlockIfNeeded() async {
        guard settings.lockEnabled else {
            isUnlocked = true
            return
        }
        guard !isUnlocked else { return }
        await authenticate()
    }

    func authenticate() async {
        let context = LAContext()
        context.localizedCancelTitle = "取消"

        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        guard canEvaluate else {
            // 设备未设置锁屏密码 / 未录入生物识别，无从验证，直接放行并提示用户
            isUnlocked = true
            lastErrorMessage = "设备未设置锁屏密码或生物识别，已跳过解锁"
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "验证身份后打开私人管家"
            )
            isUnlocked = success
            if success { lastErrorMessage = nil }
        } catch {
            isUnlocked = false
            lastErrorMessage = (error as NSError).localizedDescription
        }
    }
}
