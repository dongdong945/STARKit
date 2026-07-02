import SwiftUI

/// Alert 模态展示器
@MainActor
@Observable
public final class AlertModal: AlertPresenting {
    /// 是否正在显示
    public var isPresented: Bool = false
    /// 当前 Alert 配置
    public private(set) var currentConfig: AlertConfiguration?

    public init() {}

    /// 展示 Alert
    public func present(config: AlertConfiguration) {
        currentConfig = config
        isPresented = true
    }

    /// 隐藏 Alert
    public func dismiss() {
        isPresented = false
    }
}
