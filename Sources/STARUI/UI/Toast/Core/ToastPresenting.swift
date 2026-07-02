import SwiftUI

/// Toast 展示协议
@MainActor
public protocol ToastPresenting: AnyObject {
    /// 是否正在显示
    var isPresented: Bool { get set }
    /// 展示 Toast
    func present(config: ToastConfiguration)
    /// 隐藏 Toast
    func dismiss()
}

/// Toast 显示位置
public enum ToastPosition: Sendable, Equatable {
    /// 顶部（offset 为距离顶部安全区的额外偏移，正值向下）
    case top(offset: CGFloat = 0)

    /// 居中（offset 为垂直方向偏移，正值向下）
    case center(offset: CGFloat = 0)

    /// 底部（offset 为距离底部安全区的额外偏移，正值向上）
    case bottom(offset: CGFloat = 0)
}

/// Toast 配置数据模型
public struct ToastConfiguration: Sendable {
    /// Toast 类型
    public let type: ToastType
    /// 纯文本标题
    public let title: String?
    /// 富文本标题
    public let attributedTitle: AttributedString?
    /// 自动隐藏时长
    public let duration: TimeInterval
    /// Toast 外观配置
    public let appearance: ToastAppearance
    /// Toast 显示位置
    public let position: ToastPosition

    public init(
        type: ToastType = .info,
        title: String? = nil,
        attributedTitle: AttributedString? = nil,
        duration: TimeInterval = 3.0,
        appearance: ToastAppearance = .default,
        position: ToastPosition = .center()
    ) {
        self.type = type
        self.title = title
        self.attributedTitle = attributedTitle
        self.duration = duration
        self.appearance = appearance
        self.position = position
    }
}

/// Toast 类型
public enum ToastType: Sendable, Equatable {
    case info // 信息提示
    case success // 成功提示
    case error // 错误提示
    case warning // 警告提示
    case custom(String) // 自定义类型（参数通常为 SF Symbol 名称）
    case loading // 加载中
}

extension ToastType {
    /// SF Symbol 图标名称
    public var iconName: String? {
        switch self {
        case .info: return "exclamationmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .custom(let iconName): return iconName
        case .loading: return nil
        }
    }

    /// 图标颜色
    public var iconColor: Color? {
        switch self {
        case .info: return Color("#FF9500") // iOS 标准橙色
        case .success: return Color("#34C759") // iOS 标准绿色
        case .error: return Color("#FF3B30") // iOS 标准红色
        case .warning: return Color("#FFCC00") // iOS 标准黄色
        case .custom: return nil
        case .loading: return nil
        }
    }

    /// 渐变颜色
    public var gradientColor: Color? { iconColor }
}

/// Toast 外观配置
public struct ToastAppearance: Sendable {
    /// 标题字体
    public let titleFont: Font
    /// 标题颜色
    public let titleColor: Color
    /// 背景颜色
    public let backgroundColor: Color
    /// 圆角半径
    public let cornerRadius: CGFloat
    /// Toast 图标
    public let icon: ImageResource?
    /// 渐变颜色
    public let gradientColor: Color?

    public init(
        titleFont: Font,
        titleColor: Color,
        backgroundColor: Color,
        cornerRadius: CGFloat,
        icon: ImageResource? = nil,
        gradientColor: Color? = nil
    ) {
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.icon = icon
        self.gradientColor = gradientColor
    }

    /// 默认样式（黑底白字，无图标）
    public static let `default` = ToastAppearance(
        titleFont: .body,
        titleColor: Color(uiColor: .white),
        backgroundColor: Color(uiColor: .black).opacity(0.7),
        cornerRadius: 12,
        icon: nil,
        gradientColor: nil
    )
}
