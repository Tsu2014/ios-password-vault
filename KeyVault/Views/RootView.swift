import SwiftUI

@MainActor
struct RootView: View {
    @StateObject private var repository = VaultRepository.shared
    @StateObject private var vault = VaultViewModel()
    @StateObject private var lock = AppLock()
    @StateObject private var settings = AppSettings.shared
    @StateObject private var clipboard = ClipboardManager.shared

    @Environment(\.scenePhase) private var scenePhase

    private var needsLock: Bool { settings.lockEnabled && !lock.isUnlocked }

    var body: some View {
        ZStack {
            NavigationStack {
                VaultListView()
            }
            .blur(radius: needsLock ? 8 : 0)
            .allowsHitTesting(!needsLock)

            if needsLock {
                LockView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: needsLock)
        .overlay(alignment: .bottom) {
            ToastOverlay(message: clipboard.toast)
        }
        .environmentObject(repository)
        .environmentObject(vault)
        .environmentObject(lock)
        .environmentObject(settings)
        .environmentObject(clipboard)
        .task {
            await lock.unlockIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                lock.lock()
            } else if needsLock {
                Task { await lock.unlockIfNeeded() }
            }
        }
    }
}
