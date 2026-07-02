import SwiftUI

/// App 状态枚举
public enum AppState: Sendable, CaseIterable, Identifiable {
    /// 启动页
    case splash
    /// 引导页
    case onboarding
    /// 主界面
    case main

    public var id: Self { self }
}

/// AppState 环境键
private struct AppStateKey: EnvironmentKey {
    static let defaultValue: Binding<AppState> = .constant(.splash)
}

extension EnvironmentValues {
    /// App 状态绑定
    public var appState: Binding<AppState> {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
