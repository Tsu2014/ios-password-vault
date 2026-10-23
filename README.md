# 密码管家（KeyVault）

一个用 SwiftUI 写的 iOS 密码管理 App。每条记录包含 **项目、用户名、密码、数据1、数据2、备注** 六个字段，**点击任意字段即可复制到系统剪贴板**，方便到其它 App 中粘贴使用。

## 功能

- **新建 / 编辑 / 删除** 密码记录
- **查看** 记录详情，密码默认以圆点遮罩显示，可一键显示/隐藏
- **点击即复制**：点击「项目」「用户名」「密码」「数据1」「数据2」「备注」任意一行，内容立即写入系统剪贴板并弹出提示 + 触感反馈
- 列表页每行右侧的钥匙按钮可**直接复制密码**；长按行可复制用户名/密码
- **搜索**：按项目 / 用户名 / 数据 / 备注过滤
- **收藏**：常用记录置顶分组
- **随机密码生成**：编辑页点击「生成」创建 16 位高强度随机密码（基于 `SecRandomCopyBytes`）
- **剪贴板自动清空**：复制后 60 秒（可在设置中调整 10~300 秒）自动清空系统剪贴板，避免密码长期驻留
- **Face ID / Touch ID 解锁**：可选，App 进入后台或冷启动时需验证身份
- **安全存储**：所有数据以 JSON 形式写入系统 **钥匙串（Keychain）**，`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`，仅保存在本设备、不上传、不同步 iCloud

## 运行环境

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9 / SwiftUI

## 使用方式

```bash
git clone https://github.com/Tsu2014/ios-password-vault.git
cd ios-password-vault
open KeyVault.xcodeproj
```

在 Xcode 中选择一个 iOS 模拟器或真机设备，`Cmd + R` 运行即可。

> 真机运行需要把 `Signing & Capabilities` 中的 Team 改成你自己的 Apple 账号（Bundle Identifier: `com.tsu2014.KeyVault`）。

## 目录结构

```
ios-password-vault/
├── KeyVault/
│   ├── KeyVaultApp.swift               # App 入口
│   ├── Models/
│   │   └── PasswordItem.swift          # 记录模型（项目/用户名/密码/数据1/数据2/备注）
│   ├── Services/
│   │   ├── AppLock.swift               # Face ID / Touch ID 解锁
│   │   ├── AppSettings.swift           # 用户设置（UserDefaults）
│   │   ├── ClipboardManager.swift      # 剪贴板复制与自动清空
│   │   ├── KeychainStore.swift         # Keychain 读写封装
│   │   ├── PasswordGenerator.swift     # 随机密码生成
│   │   └── VaultRepository.swift       # 记录增删改查 + 持久化
│   ├── ViewModels/
│   │   └── VaultViewModel.swift        # 搜索与分组
│   ├── Views/
│   │   ├── RootView.swift              # 根视图（解锁 / 提示浮层）
│   │   ├── VaultListView.swift         # 记录列表
│   │   ├── ItemDetailView.swift        # 记录详情（点击复制）
│   │   ├── ItemEditView.swift          # 新建 / 编辑
│   │   ├── LockView.swift              # 锁定页
│   │   ├── SettingsView.swift          # 设置
│   │   └── Components/
│   │       ├── CopyableRow.swift       # 可点击复制的行
│   │       └── ToastOverlay.swift      # 复制结果提示
│   └── Resources/Assets.xcassets       # App 图标与主题色
└── KeyVault.xcodeproj
```

## 关于数据安全

- 数据存放在系统钥匙串中，由 iOS 提供加密保护，App 沙盒外的其它应用无法读取。
- 未开启 iCloud 同步，所有数据只留在当前设备；卸载 App 会一并删除。
- 密码复制后默认 60 秒自动清空剪贴板，降低被其它 App 读取的风险。

## License

MIT
