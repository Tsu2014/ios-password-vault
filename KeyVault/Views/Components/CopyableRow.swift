import SwiftUI
import UIKit

/// 可点击复制的一行：点击即把内容写入系统剪贴板
struct CopyableRow: View {
    let field: PasswordItem.Field
    let value: String

    @EnvironmentObject private var clipboard: ClipboardManager
    @State private var revealed = false

    private var isEmpty: Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var displayText: String {
        guard !isEmpty else { return "未填写" }
        if field.isSecret && !revealed {
            return String(repeating: "•", count: min(value.count, 20))
        }
        return value
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: field.systemImage)
                .font(.footnote)
                .foregroundStyle(isEmpty ? Color(UIColor.tertiaryLabel) : Color.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(field.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(displayText)
                    .font(.body)
                    .foregroundStyle(isEmpty ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 8)

            if field.isSecret && !isEmpty {
                Button {
                    revealed.toggle()
                } label: {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }

            Image(systemName: "doc.on.doc")
                .font(.caption)
                .foregroundStyle(isEmpty ? Color(UIColor.quaternaryLabel) : Color(UIColor.secondaryLabel))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            clipboard.copy(value, label: field.title)
        }
        .contextMenu {
            Button {
                clipboard.copy(value, label: field.title)
            } label: {
                Label("复制\(field.title)", systemImage: "doc.on.doc")
            }
            if field.isSecret {
                Button {
                    revealed.toggle()
                } label: {
                    Label(revealed ? "隐藏" : "显示", systemImage: revealed ? "eye.slash" : "eye")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("点击复制\(field.title)")
    }
}
