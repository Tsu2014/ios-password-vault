import SwiftUI

struct VaultListView: View {
    @EnvironmentObject private var repository: VaultRepository
    @EnvironmentObject private var vault: VaultViewModel
    @EnvironmentObject private var clipboard: ClipboardManager
    @EnvironmentObject private var settings: AppSettings

    @State private var showingEditor = false
    @State private var editingItem: PasswordItem?

    private var sections: [VaultSection] { vault.sections(from: repository.items) }

    var body: some View {
        List {
            if sections.isEmpty {
                Section {
                    EmptyStateView(isSearching: !vault.searchText.isEmpty) {
                        showingEditor = true
                    }
                }
            }

            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.items) { item in
                        NavigationLink(value: item.id) {
                            ItemRow(item: item) {
                                clipboard.copy(item.password, label: "「\(item.displayName)」的密码")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                repository.delete(item)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            Button {
                                editingItem = item
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                repository.toggleFavorite(item)
                            } label: {
                                Label(item.isFavorite ? "取消收藏" : "收藏",
                                      systemImage: item.isFavorite ? "star.slash.fill" : "star.fill")
                            }
                            .tint(.yellow)
                        }
                        .contextMenu {
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
                        }
                    }
                }
            }

            if !repository.items.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        Text("共 \(repository.items.count) 条记录 · 数据保存在本机钥匙串")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("密码管家")
        .searchable(text: $vault.searchText, prompt: "搜索项目 / 用户名 / 备注")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: UUID.self) { id in
            if let item = repository.item(with: id) {
                ItemDetailView(item: item)
            } else {
                Text("记录不存在或已被删除")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingEditor) {
            ItemEditView(original: nil) { repository.add($0) }
        }
        .sheet(item: $editingItem) { item in
            ItemEditView(original: item) { repository.update($0) }
        }
    }
}

private struct ItemRow: View {
    let item: PasswordItem
    var onCopyPassword: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                Text(item.initial)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(item.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(item.subtitle.isEmpty ? "暂无用户名" : item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                onCopyPassword()
            } label: {
                Image(systemName: "key.fill")
                    .font(.footnote)
                    .padding(8)
                    .background(Color(.secondarySystemFill), in: Circle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel("复制密码")
        }
        .padding(.vertical, 2)
    }
}

private struct EmptyStateView: View {
    let isSearching: Bool
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: isSearching ? "magnifyingglass" : "lock.square.stack")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(isSearching ? "没有匹配的记录" : "还没有任何记录")
                .font(.headline)
            Text(isSearching ? "换个关键词试试" : "点击右上角 + 创建第一条密码记录")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !isSearching {
                Button("新建记录") { onCreate() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
