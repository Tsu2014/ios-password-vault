import SwiftUI

struct LockView: View {
    @EnvironmentObject private var lock: AppLock

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                Text("密码管家已锁定")
                    .font(.title2.bold())

                Text("验证身份后查看你的密码数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await lock.authenticate() }
                } label: {
                    Label("解锁", systemImage: "faceid")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Capsule())

                if let message = lock.lastErrorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .padding()
        }
    }
}
