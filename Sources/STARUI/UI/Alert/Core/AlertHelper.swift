import SwiftUI

/// Alert 管理器
@MainActor
@Observable
public final class AlertHelper {
    /// Alert 展示协议实现者
    public weak var presenter: AlertPresenting?

    /// 是否正在显示
    public var isPresented: Bool {
        presenter?.isPresented ?? false
    }

    /// 初始化 Alert 管理器
    public init(presenter: AlertPresenting? = nil) {
        self.presenter = presenter
    }

    /// 展示 Alert（自定义按钮）
    public func show(
        _ title: String?,
        message: String? = nil,
        actions: [AlertAction],
        appearance: AlertAppearance? = nil
    ) {
        let config = AlertConfiguration(
            title: title,
            message: message,
            actions: actions,
            appearance: appearance ?? .default
        )
        presenter?.present(config: config)
    }

    /// 展示 Alert（含消息）
    public func show(_ title: String?, message: String, appearance: AlertAppearance? = nil) {
        let config = AlertConfiguration(
            title: title,
            message: message,
            appearance: appearance ?? .default
        )
        presenter?.present(config: config)
    }

    /// 展示 Alert（仅标题）
    public func show(_ title: String?, appearance: AlertAppearance? = nil) {
        let config = AlertConfiguration(title: title, appearance: appearance ?? .default)
        presenter?.present(config: config)
    }

    /// 展示 Alert（自定义标题 + 自定义按钮视图）
    public func show(
        _ title: String? = nil,
        message: String? = nil,
        appearance: AlertAppearance? = nil,
        customTitleView: AnyView? = nil,
        customMessageView: AnyView? = nil,
        customActionViews: AnyView? = nil
    ) {
        let config = AlertConfiguration(
            title: title,
            message: message,
            customTitleView: customTitleView,
            customMessageView: customMessageView,
            customActionViews: customActionViews,
            appearance: appearance ?? .default
        )
        presenter?.present(config: config)
    }

    /// 展示 Alert（ViewBuilder 版本的自定义标题 + 自定义按钮视图）
    public func show(
        _ title: String? = nil,
        message: String? = nil,
        appearance: AlertAppearance? = nil,
        @ViewBuilder titleView: () -> some View,
        @ViewBuilder messageView: () -> some View,
        @ViewBuilder actionViews: () -> some View
    ) {
        show(
            title,
            message: message,
            appearance: appearance,
            customTitleView: AnyView(titleView()),
            customMessageView: AnyView(messageView()),
            customActionViews: AnyView(actionViews())
        )
    }

    /// 展示 Alert（仅自定义标题 + 自定义按钮视图）
    public func show(
        _ title: String? = nil,
        message: String? = nil,
        appearance: AlertAppearance? = nil,
        @ViewBuilder titleView: () -> some View,
        @ViewBuilder actionViews: () -> some View
    ) {
        show(
            title,
            message: message,
            appearance: appearance,
            customTitleView: AnyView(titleView()),
            customActionViews: AnyView(actionViews())
        )
    }

    /// 展示 Alert（标题/消息 + ViewBuilder 自定义按钮）
    public func show(
        _ title: String? = nil,
        message: String? = nil,
        appearance: AlertAppearance? = nil,
        @ViewBuilder actionViews: () -> some View
    ) {
        show(
            title,
            message: message,
            appearance: appearance,
            customActionViews: AnyView(actionViews())
        )
    }

    /// 展示确认/取消弹窗
    public func showConfirm(
        _ title: String?,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        appearance: AlertAppearance? = nil,
        onConfirm: @escaping () -> Void
    ) {
        let actions = [
            AlertAction(title: confirmTitle, handler: onConfirm),
            AlertAction(title: cancelTitle, role: .cancel)
        ]
        show(title, message: message, actions: actions, appearance: appearance)
    }

    /// 展示破坏性操作弹窗
    public func showDestructive(
        _ title: String?,
        message: String? = nil,
        destructiveTitle: String = "Delete",
        cancelTitle: String = "Cancel",
        appearance: AlertAppearance? = nil,
        onDestruct: @escaping () -> Void
    ) {
        let actions = [
            AlertAction(title: destructiveTitle, role: .destructive, handler: onDestruct),
            AlertAction(title: cancelTitle, role: .cancel)
        ]
        show(title, message: message, actions: actions, appearance: appearance)
    }

    /// 展示错误弹窗
    public func showError(_ error: Error, appearance: AlertAppearance? = nil) {
        show("Error", message: error.localizedDescription, appearance: appearance)
    }

    /// 隐藏 Alert
    public func dismiss() {
        presenter?.dismiss()
    }
}
