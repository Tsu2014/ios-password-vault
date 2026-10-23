import Foundation

/// 密码仓库：负责记录的增删改查与持久化（底层写入 Keychain）。
@MainActor
final class VaultRepository: ObservableObject {
    /// 全局共享实例（UI 与局域网共享服务共用同一份数据）
    static let shared = VaultRepository()

    @Published private(set) var items: [PasswordItem] = []
    @Published var lastErrorMessage: String?

    private let store: KeychainStore
    private let account = "vault.items.v1"

    init(store: KeychainStore = KeychainStore.shared) {
        self.store = store
        reload()
    }

    // MARK: - 读取 / 写入

    func reload() {
        do {
            guard let data = try store.load(account: account) else {
                items = []
                return
            }
            items = try JSONDecoder().decode([PasswordItem].self, from: data)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            try store.save(data, for: account)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - 增删改

    func add(_ item: PasswordItem) {
        var newItem = item.trimmedCopy()
        newItem.id = UUID()
        newItem.createdAt = Date()
        newItem.touch()
        items.insert(newItem, at: 0)
        persist()
    }

    func update(_ item: PasswordItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item.trimmedCopy()
        updated.createdAt = items[index].createdAt
        updated.touch()
        items[index] = updated
        persist()
    }

    func delete(_ item: PasswordItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func delete(at offsets: IndexSet, in list: [PasswordItem]) {
        let ids = offsets.compactMap { list[$0].id }
        items.removeAll { ids.contains($0.id) }
        persist()
    }

    func toggleFavorite(_ item: PasswordItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isFavorite.toggle()
        items[index].touch()
        persist()
    }

    func removeAll() {
        items = []
        persist()
    }

    func item(with id: UUID) -> PasswordItem? {
        items.first { $0.id == id }
    }
}
