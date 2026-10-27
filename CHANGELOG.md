# Changelog

## 0.0.4

- 修复使用 Xcode 27.1 构建时，STARUI 的 `@State` 宏引入 `LazyState` 符号而导致 iOS 18.6.2 真机启动崩溃的问题。
- 新增公开的 `@StoredState` 类型别名，显式使用原有 `SwiftUI.State` 属性包装器；STARUI 组件统一使用该别名。宿主 App 内同类 `@State` 需要一并处理。
- 修复代码已在 STAR301 的 iOS 18.6.2 真机启动验证中使用；此次仅将相同补丁移回远程 Package，未新增设备回归。
