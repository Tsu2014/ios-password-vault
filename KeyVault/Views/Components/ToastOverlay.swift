import SwiftUI

/// 底部的复制结果提示
struct ToastOverlay: View {
    let message: ToastMessage?

    var body: some View {
        Group {
            if let message {
                HStack(spacing: 8) {
                    Image(systemName: message.isWarning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    Text(message.text)
                        .lineLimit(1)
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(message.isWarning ? Color.orange.opacity(0.6) : Color.green.opacity(0.5), lineWidth: 1)
                )
                .padding(.bottom, 30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: message?.id)
    }
}
