import SwiftUI

/// Toast 系统样式视图（简单黑底白字）
public struct SystemToastView: View {
    /// Toast 数据模型
    @Bindable
    public var modal: ToastModal

    public init(modal: ToastModal) {
        self.modal = modal
    }

    public var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()

            if modal.isPresented, let config = modal.currentConfig {
                toastContent(config: config)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    /// Toast 内容视图
    @ViewBuilder
    private func toastContent(config: ToastConfiguration) -> some View {
        Group {
            switch config.type {
            case .loading:
                loadingView(appearance: config.appearance)
            default:
                defaultView(
                    title: config.title,
                    attributedTitle: config.attributedTitle,
                    appearance: config.appearance
                )
            }
        }
        .padding()
        .background(config.appearance.backgroundColor)
        .cornerRadius(config.appearance.cornerRadius)
    }

    /// 加载状态视图
    @ViewBuilder
    private func loadingView(appearance: ToastAppearance) -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(appearance.titleColor)
    }

    /// 默认样式视图
    @ViewBuilder
    private func defaultView(
        title: String?,
        attributedTitle: AttributedString?,
        appearance: ToastAppearance
    ) -> some View {
        if let attributedTitle {
            Text(attributedTitle)
                .font(appearance.titleFont)
                .foregroundColor(appearance.titleColor)
                .multilineTextAlignment(.center)
        } else if let title {
            Text(title)
                .font(appearance.titleFont)
                .foregroundColor(appearance.titleColor)
                .multilineTextAlignment(.center)
        }
    }
}
