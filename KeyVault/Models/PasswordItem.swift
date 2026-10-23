import Foundation

/// 一条密码记录。
/// 每条记录包含：项目 / 用户名 / 密码 / 数据1 / 数据2 / 备注。
struct PasswordItem: Identifiable, Codable, Equatable {
    var id: UUID
    var project: String
    var username: String
    var password: String
    var data1: String
    var data2: String
    var note: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        project: String = "",
        username: String = "",
        password: String = "",
        data1: String = "",
        data2: String = "",
        note: String = "",
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.project = project
        self.username = username
        self.password = password
        self.data1 = data1
        self.data2 = data2
        self.note = note
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayName: String {
        let trimmed = project.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名项目" : trimmed
    }

    var initial: String {
        String(displayName.prefix(1)).uppercased()
    }

    /// 列表副标题：优先显示用户名
    var subtitle: String {
        [username, data1].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
    }

    mutating func touch() {
        updatedAt = Date()
    }

    func trimmedCopy() -> PasswordItem {
        var copy = self
        copy.project = project.trimmed
        copy.username = username.trimmed
        copy.password = password
        copy.data1 = data1.trimmed
        copy.data2 = data2.trimmed
        copy.note = note.trimmed
        return copy
    }
}

extension PasswordItem {
    /// 记录中的可复制字段
    enum Field: String, CaseIterable, Identifiable {
        case project
        case username
        case password
        case data1
        case data2
        case note

        var id: String { rawValue }

        var title: String {
            switch self {
            case .project: return "项目"
            case .username: return "用户名"
            case .password: return "密码"
            case .data1: return "数据1"
            case .data2: return "数据2"
            case .note: return "备注"
            }
        }

        var systemImage: String {
            switch self {
            case .project: return "folder"
            case .username: return "person"
            case .password: return "key"
            case .data1: return "1.square"
            case .data2: return "2.square"
            case .note: return "note.text"
            }
        }

        /// 是否属于敏感字段（默认打码显示）
        var isSecret: Bool { self == .password }

        var placeholder: String {
            switch self {
            case .project: return "例如：GitHub"
            case .username: return "例如：zhangsan@example.com"
            case .password: return "点击“生成”创建随机密码"
            case .data1: return "自定义数据，例如手机号"
            case .data2: return "自定义数据，例如密保问题"
            case .note: return "补充说明"
            }
        }

        func value(in item: PasswordItem) -> String {
            switch self {
            case .project: return item.project
            case .username: return item.username
            case .password: return item.password
            case .data1: return item.data1
            case .data2: return item.data2
            case .note: return item.note
            }
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
