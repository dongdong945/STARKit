import SwiftUI

/// Toast 提示框管理器
@MainActor
@Observable
public final class ToastHelper {
    /// Toast 展示协议实现者
    public weak var presenter: ToastPresenting?

    /// 是否正在显示
    public var isPresented: Bool {
        presenter?.isPresented ?? false
    }

    public init(presenter: ToastPresenting? = nil) {
        self.presenter = presenter
    }

    /// 隐藏 Toast
    public func dismiss() {
        presenter?.dismiss()
    }

    /// 显示加载状态提示
    public func loading(
        _ title: LocalizedStringResource? = nil,
        appearance: ToastAppearance? = nil,
        position: ToastPosition = .center()
    ) {
        let localizedTitle = title.map { String(localized: $0) }
        let config = ToastConfiguration(
            type: .loading,
            title: localizedTitle,
            duration: 0, // loading 不自动隐藏
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示信息提示
    public func info(
        _ title: LocalizedStringResource,
        appearance: ToastAppearance? = nil,
        position: ToastPosition = .center()
    ) {
        let localizedTitle = String(localized: title)
        let config = ToastConfiguration(
            type: .info,
            title: localizedTitle,
            duration: 3.0,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示成功提示
    public func success(
        _ title: LocalizedStringResource,
        appearance: ToastAppearance? = nil,
        position: ToastPosition = .center()
    ) {
        let localizedTitle = String(localized: title)
        let config = ToastConfiguration(
            type: .success,
            title: localizedTitle,
            duration: 3.0,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示错误提示
    public func error(
        _ title: LocalizedStringResource,
        appearance: ToastAppearance? = nil,
        position: ToastPosition = .center()
    ) {
        let localizedTitle = String(localized: title)
        let config = ToastConfiguration(
            type: .error,
            title: localizedTitle,
            duration: 3.0,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示警告提示
    public func warning(
        _ title: LocalizedStringResource,
        appearance: ToastAppearance? = nil,
        position: ToastPosition = .center()
    ) {
        let localizedTitle = String(localized: title)
        let config = ToastConfiguration(
            type: .warning,
            title: localizedTitle,
            duration: 3.0,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示自定义类型提示
    public func custom(
        _ title: LocalizedStringResource,
        id: String,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let localizedTitle = String(localized: title)
        let config = ToastConfiguration(
            type: .custom(id),
            title: localizedTitle,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示错误提示
    public func error(
        _ error: Error,
        appearance: ToastAppearance? = nil,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .error,
            title: error.localizedDescription,
            duration: 3.0,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    public func loading(
        attributed title: AttributedString? = nil,
        appearance: ToastAppearance? = nil,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .loading,
            attributedTitle: title,
            duration: 0, // loading 不自动隐藏
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    public func info(
        attributed title: AttributedString,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .info,
            attributedTitle: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    public func success(
        attributed title: AttributedString,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .success,
            attributedTitle: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    public func error(
        attributed title: AttributedString,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .error,
            attributedTitle: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    public func warning(
        attributed title: AttributedString,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .warning,
            attributedTitle: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    public func custom(
        attributed title: AttributedString,
        id: String,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .custom(id),
            attributedTitle: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示信息提示
    public func info(
        verbatim title: String,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .info,
            title: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示成功提示
    public func success(
        verbatim title: String,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .success,
            title: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示错误提示
    public func error(
        verbatim title: String,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .error,
            title: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示警告提示
    public func warning(
        verbatim title: String,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .warning,
            title: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }

    /// 显示自定义类型提示
    public func custom(
        verbatim title: String,
        id: String,
        appearance: ToastAppearance? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center()
    ) {
        let config = ToastConfiguration(
            type: .custom(id),
            title: title,
            duration: duration,
            appearance: appearance ?? .default,
            position: position
        )
        presenter?.present(config: config)
    }
}
