import Foundation

/// 用户设置（持久化到 UserDefaults，变更可被 SwiftUI 观察）
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let lockEnabled = "settings.lockEnabled"
        static let autoClearEnabled = "settings.autoClearEnabled"
        static let autoClearSeconds = "settings.autoClearSeconds"
    }

    private let defaults = UserDefaults.standard

    @Published var lockEnabled: Bool {
        didSet { defaults.set(lockEnabled, forKey: Keys.lockEnabled) }
    }

    @Published var autoClearEnabled: Bool {
        didSet { defaults.set(autoClearEnabled, forKey: Keys.autoClearEnabled) }
    }

    @Published var autoClearSeconds: Int {
        didSet { defaults.set(autoClearSeconds, forKey: Keys.autoClearSeconds) }
    }

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Keys.lockEnabled: false,
            Keys.autoClearEnabled: true,
            Keys.autoClearSeconds: 60
        ])
        self.lockEnabled = defaults.bool(forKey: Keys.lockEnabled)
        self.autoClearEnabled = defaults.bool(forKey: Keys.autoClearEnabled)
        self.autoClearSeconds = defaults.object(forKey: Keys.autoClearSeconds) as? Int ?? 60
    }
}
