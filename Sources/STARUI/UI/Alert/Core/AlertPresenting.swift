import SwiftUI

/// Alert 按钮数据模型
public struct AlertAction: Identifiable {
    /// 唯一标识
    public let id = UUID()
    /// 按钮标题
    public let title: String
    /// 按钮角色（确定/取消/破坏）
    public let role: ButtonRole?
    /// 点击回调
    public let handler: () -> Void

    /// 创建一个 Alert 按钮
    public init(title: String, role: ButtonRole? = nil, handler: @escaping () -> Void = {}) {
        self.title = title
        self.role = role
        self.handler = handler
    }

    /// 默认的“OK”按钮
    public static func defaultOK() -> AlertAction {
        AlertAction(title: "OK", role: nil)
    }
}

/// Alert 外观配置
public struct AlertAppearance: Sendable {
    /// 标题字体
    public let titleFont: Font
    /// 标题颜色
    public let titleColor: Color
    /// 消息字体
    public let messageFont: Font
    /// 消息颜色
    public let messageColor: Color
    /// 容器背景颜色
    public let backgroundColor: Color
    /// 容器圆角半径
    public let cornerRadius: CGFloat
    /// Alert 整体垂直偏移量，正值向下，负值向上
    public let offset: CGFloat
    /// 蒙层颜色
    public let dimmingColor: Color
    /// 按钮字体
    public let buttonFont: Font
    /// 按钮高度
    public let buttonHeight: CGFloat
    /// 主按钮文字颜色（destructive role）
    public let primaryButtonTextColor: Color
    /// 主按钮背景颜色
    public let primaryButtonBackgroundColor: Color
    /// 次按钮文字颜色（default/cancel role）
    public let secondaryButtonTextColor: Color
    /// 次按钮背景颜色
    public let secondaryButtonBackgroundColor: Color

    public init(
        titleFont: Font,
        titleColor: Color,
        messageFont: Font,
        messageColor: Color,
        backgroundColor: Color,
        cornerRadius: CGFloat,
        offset: CGFloat = 0,
        dimmingColor: Color,
        buttonFont: Font,
        buttonHeight: CGFloat,
        primaryButtonTextColor: Color,
        primaryButtonBackgroundColor: Color,
        secondaryButtonTextColor: Color,
        secondaryButtonBackgroundColor: Color
    ) {
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.messageFont = messageFont
        self.messageColor = messageColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.offset = offset
        self.dimmingColor = dimmingColor
        self.buttonFont = buttonFont
        self.buttonHeight = buttonHeight
        self.primaryButtonTextColor = primaryButtonTextColor
        self.primaryButtonBackgroundColor = primaryButtonBackgroundColor
        self.secondaryButtonTextColor = secondaryButtonTextColor
        self.secondaryButtonBackgroundColor = secondaryButtonBackgroundColor
    }

    /// 默认样式（系统字体/颜色）
    @MainActor
    public static var `default` = AlertAppearance(
        titleFont: .headline,
        titleColor: .primary,
        messageFont: .subheadline,
        messageColor: .secondary,
        backgroundColor: Color(.systemBackground),
        cornerRadius: 16,
        offset: 0,
        dimmingColor: Color.black.opacity(0.7),
        buttonFont: .body.weight(.semibold),
        buttonHeight: 56,
        primaryButtonTextColor: .white,
        primaryButtonBackgroundColor: .blue,
        secondaryButtonTextColor: .primary,
        secondaryButtonBackgroundColor: Color(.secondarySystemBackground)
    )
}

/// Alert 配置数据模型
public struct AlertConfiguration {
    /// 标题
    public let title: String?
    /// 描述信息
    public let message: String?
    /// 自定义标题视图（优先于 title/message 文本区）
    public let customTitleView: AnyView?
    /// 自定义消息视图（优先于 message 文本）
    public let customMessageView: AnyView?
    /// 自定义按钮视图（优先于 actions）
    public let customActionViews: AnyView?
    /// 按钮列表
    public let actions: [AlertAction]
    /// 外观配置
    public let appearance: AlertAppearance

    /// 创建 Alert 配置
    @MainActor
    public init(
        title: String? = nil,
        message: String? = nil,
        customTitleView: AnyView? = nil,
        customMessageView: AnyView? = nil,
        customActionViews: AnyView? = nil,
        actions: [AlertAction] = [],
        appearance: AlertAppearance = .default
    ) {
        self.title = title
        self.message = message
        self.customTitleView = customTitleView
        self.customMessageView = customMessageView
        self.customActionViews = customActionViews
        self.actions = actions.isEmpty ? [.defaultOK()] : actions
        self.appearance = appearance
    }
}

/// Alert 展示协议
@MainActor
public protocol AlertPresenting: AnyObject {
    /// 是否正在显示
    var isPresented: Bool { get set }
    /// 展示 Alert
    func present(config: AlertConfiguration)
    /// 隐藏 Alert
    func dismiss()
}
