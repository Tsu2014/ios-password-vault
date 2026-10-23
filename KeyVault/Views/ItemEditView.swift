import SwiftUI

struct ItemEditView: View {
    let original: PasswordItem?
    let onSave: (PasswordItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: PasswordItem
    @State private var passwordVisible = false
    @FocusState private var focused: PasswordItem.Field?

    init(original: PasswordItem?, onSave: @escaping (PasswordItem) -> Void) {
        self.original = original
        self.onSave = onSave
        _draft = State(initialValue: original ?? PasswordItem())
    }

    private var isValid: Bool {
        !draft.project.trimmed.isEmpty && !draft.password.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    LabeledContent("项目") {
                        TextField("必填", text: $draft.project)
                            .multilineTextAlignment(.trailing)
                            .focused($focused, equals: .project)
                    }
                    LabeledContent("用户名") {
                        TextField("选填", text: $draft.username)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .focused($focused, equals: .username)
                    }
                }

                Section {
                    HStack {
                        Text("密码")
                        Spacer()
                        Group {
                            if passwordVisible {
                                TextField("必填", text: $draft.password)
                            } else {
                                SecureField("必填", text: $draft.password)
                            }
                        }
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .password)

                        Button {
                            passwordVisible.toggle()
                        } label: {
                            Image(systemName: passwordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)

                        Button("生成") {
                            draft.password = PasswordGenerator.generate()
                            passwordVisible = true
                        }
                        .buttonStyle(.borderless)
                        .font(.footnote)
                    }
                } header: {
                    Text("密码")
                } footer: {
                    Text("点击「生成」可创建 16 位高强度随机密码。")
                }

                Section("自定义数据") {
                    LabeledContent("数据1") {
                        TextField("选填", text: $draft.data1)
                            .multilineTextAlignment(.trailing)
                            .focused($focused, equals: .data1)
                    }
                    LabeledContent("数据2") {
                        TextField("选填", text: $draft.data2)
                            .multilineTextAlignment(.trailing)
                            .focused($focused, equals: .data2)
                    }
                }

                Section("备注") {
                    TextEditor(text: $draft.note)
                        .frame(minHeight: 90)
                        .focused($focused, equals: .note)
                }

                Section {
                    Toggle("加入收藏", isOn: $draft.isFavorite)
                }
            }
            .navigationTitle(original == nil ? "新建记录" : "编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if original == nil {
                    focused = .project
                }
            }
        }
    }

    private func save() {
        var item = draft.trimmedCopy()
        if let original {
            item.id = original.id
            item.createdAt = original.createdAt
        }
        item.touch()
        onSave(item)
        dismiss()
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
