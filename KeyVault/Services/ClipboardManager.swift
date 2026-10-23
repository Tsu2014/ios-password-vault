import SwiftUI
import UIKit

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    var isWarning: Bool = false
}

/// 剪贴板管理：复制内容、提示反馈、可选的自动清空。
@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var toast: ToastMessage?

    private let settings: AppSettings

    private var toastTask: Task<Void, Never>?
    private var clearTask: Task<Void, Never>?

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    /// 复制指定内容到系统剪贴板
    func copy(_ value: String, label: String) {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showToast("「\(label)」为空，无需复制", warning: true)
            return
        }
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("已复制「\(label)」")
        scheduleAutoClear()
    }

    func clearClipboard() {
        clearTask?.cancel()
        clearTask = nil
        guard UIPasteboard.general.hasStrings else { return }
        UIPasteboard.general.string = ""
        showToast("剪贴板已自动清空")
    }

    private func showToast(_ text: String, warning: Bool = false) {
        toastTask?.cancel()
        toast = ToastMessage(text: text, isWarning: warning)
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }

    private func scheduleAutoClear() {
        clearTask?.cancel()
        guard settings.autoClearEnabled else { return }
        let seconds = max(10, settings.autoClearSeconds)
        clearTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.clearClipboard()
        }
    }
}
