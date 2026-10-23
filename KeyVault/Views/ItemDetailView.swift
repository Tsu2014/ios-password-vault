import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject private var repository: VaultRepository
    @EnvironmentObject private var clipboard: ClipboardManager
    @Environment(\.dismiss) private var dismiss

    @State private var item: PasswordItem
    @State private var showingEditor = false
    @State private var showingDeleteConfirm = false

    init(item: PasswordItem) {
        _item = State(initialValue: item)
    }

    var body: some View {
        List {
            Section("基本信息") {
                CopyableRow(field: .project, value: item.project)
                CopyableRow(field: .username, value: item.username)
                CopyableRow(field: .password, value: item.password)
            }

            Section("自定义数据") {
                CopyableRow(field: .data1, value: item.data1)
                CopyableRow(field: .data2, value: item.data2)
            }

            Section("备注") {
                CopyableRow(field: .note, value: item.note)
            }

            Section("其它") {
                LabeledContent("创建时间", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("更新时间", value: item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                Toggle("收藏", isOn: Binding(
                    get: { item.isFavorite },
                    set: { newValue in
                        item.isFavorite = newValue
                        repository.toggleFavorite(item)
                    }
                ))
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Section {
                Button {
                    clipboard.copy(item.password, label: "密码")
                } label: {
                    Label("复制密码", systemImage: "key.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(item.password.isEmpty)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button {
                        clipboard.copy(item.username, label: "用户名")
                    } label: {
                        Label("复制用户名", systemImage: "person")
                    }
                    Button {
                        clipboard.copy(item.password, label: "密码")
                    } label: {
                        Label("复制密码", systemImage: "key")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            ItemEditView(original: item) { updated in
                repository.update(updated)
                item = updated
            }
        }
        .alert("删除记录", isPresented: $showingDeleteConfirm) {
            Button("删除", role: .destructive) {
                repository.delete(item)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("「\(item.displayName)」将被永久删除，且无法恢复。")
        }
    }
}
