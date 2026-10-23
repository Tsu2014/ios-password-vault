import Foundation

struct VaultSection: Identifiable {
    let id: String
    let title: String
    let items: [PasswordItem]
}

/// 列表页的搜索与分组逻辑
@MainActor
final class VaultViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var showingFavoritesOnly: Bool = false

    func filtered(_ items: [PasswordItem]) -> [PasswordItem] {
        var result = items.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
            return lhs.updatedAt > rhs.updatedAt
        }

        if showingFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !keyword.isEmpty else { return result }

        return result.filter { item in
            [item.project, item.username, item.data1, item.data2, item.note]
                .contains { $0.lowercased().contains(keyword) }
        }
    }

    func sections(from items: [PasswordItem]) -> [VaultSection] {
        let base = filtered(items)
        guard !base.isEmpty else { return [] }

        let favorites = base.filter { $0.isFavorite }
        let others = base.filter { !$0.isFavorite }

        var result: [VaultSection] = []
        if !favorites.isEmpty {
            result.append(VaultSection(id: "favorites", title: "收藏", items: favorites))
        }
        if !others.isEmpty {
            result.append(VaultSection(id: "others", title: favorites.isEmpty ? "全部记录" : "其它记录", items: others))
        }
        return result
    }
}
