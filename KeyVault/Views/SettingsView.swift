import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var repository: VaultRepository
    @EnvironmentObject private var clipboard: ClipboardManager

    @State private var showingDeleteAll = false

    var body: some View {
        Form {
            Section {
                Toggle("Face ID / Touch ID 解锁", isOn: $settings.lockEnabled)
            } header: {
                Text("安全")
            } footer: {
                Text("开启后，每次打开或切回 App 都需要验证设备密码或生物识别。")
            }

            Section {
                Toggle("复制后自动清空剪贴板", isOn: $settings.autoClearEnabled)
                Stepper(value: $settings.autoClearSeconds, in: 10...300, step: 10) {
                    LabeledContent("清空倒计时") {
                        Text("\(settings.autoClearSeconds) 秒")
                            .foregroundStyle(settings.autoClearEnabled ? .primary : .secondary)
                    }
                }
                .disabled(!settings.autoClearEnabled)

                Button("立即清空剪贴板") {
                    clipboard.clearClipboard()
                }
            } header: {
                Text("剪贴板")
            } footer: {
                Text("复制密码后自动清空剪贴板，避免密码长时间留在系统剪贴板中被其它 App 读取。")
            }

            Section {
                LabeledContent("记录数量", value: "\(repository.items.count)")
                Button("清空所有记录", role: .destructive) {
                    showingDeleteAll = true
                }
            } header: {
                Text("数据")
            } footer: {
                Text("所有记录以 JSON 形式加密存放在本机钥匙串（Keychain）中，仅保存在本设备，不会上传或同步到 iCloud。")
            }

            Section("关于") {
                LabeledContent("版本", value: appVersion)
                Link(destination: URL(string: "https://github.com/Tsu2014/ios-password-vault")!) {
                    Label("项目主页", systemImage: "arrow.up.right.square")
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("清空所有记录", isPresented: $showingDeleteAll) {
            Button("清空", role: .destructive) { repository.removeAll() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将删除全部 \(repository.items.count) 条记录，且无法恢复。")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
