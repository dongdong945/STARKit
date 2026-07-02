import SwiftUI

/// 自定义导航栏配置
public struct CustomNavigationBarConfig: Sendable {
    /// 标题字体
    public var titleFont: Font
    /// 标题颜色
    public var titleColor: Color
    /// 背景渐变颜色数组
    public var backgroundColors: [Color]
    /// 导航栏高度
    public var height: CGFloat
    /// 导航栏水平内边距
    public var horizontalPadding: CGFloat
    /// 背景透明度变化的滚动阈值（默认与 height 相同）
    public var transitionThreshold: CGFloat

    /// 初始背景透明度
    public var initialBackgroundOpacity: CGFloat

    /// 滚动后背景透明度
    public var scrolledBackgroundOpacity: CGFloat

    public init(
        titleFont: Font? = nil,
        titleColor: Color? = nil,
        backgroundColors: [Color] = [Color(.systemBackground)],
        height: CGFloat = 44,
        horizontalPadding: CGFloat = 6,
        transitionThreshold: CGFloat? = 120,
        initialBackgroundOpacity: CGFloat = 0,
        scrolledBackgroundOpacity: CGFloat = 1
    ) {
        self.titleFont = titleFont ?? .system(size: 20, weight: .medium)
        self.titleColor = titleColor ?? Color("#F2F2F2")
        self.backgroundColors = backgroundColors
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.transitionThreshold = transitionThreshold ?? height
        self.initialBackgroundOpacity = initialBackgroundOpacity
        self.scrolledBackgroundOpacity = scrolledBackgroundOpacity
    }

    /// 默认配置
    @MainActor
    public static var `default` = CustomNavigationBarConfig(
        backgroundColors: [
            Color("#1A1A1A"),
            Color("#1A1A1A"),
            Color("#1A1A1A").opacity(0)
        ]
    )
}

/// 自定义导航栏的 ViewModifier
struct CustomNavigationBarModifier<LeadingView: View, TitleView: View, TrailingView: View>: ViewModifier {
    let titleView: TitleView
    let leadingView: LeadingView
    let trailingView: TrailingView
    let config: CustomNavigationBarConfig

    /// 当前滚动偏移量
    @State
    private var scrollOffset: CGFloat = 0
    /// 初始偏移量（用于补偿 ScrollView 的初始位置）
    @State
    private var initialOffset: CGFloat? = nil

    /// 修正后的滚动偏移量（减去初始偏移）
    private var adjustedOffset: CGFloat {
        scrollOffset - (initialOffset ?? 0)
    }

    /// 滚动进度（0 = 未滚动，1 = 完全滚动）
    private var progress: CGFloat {
        let clampedOffset = min(max(adjustedOffset, 0), config.transitionThreshold)
        return clampedOffset / config.transitionThreshold
    }

    /// 背景透明度（从初始到滚动后插值）
    private var backgroundOpacity: CGFloat {
        config.initialBackgroundOpacity + (config.scrolledBackgroundOpacity - config.initialBackgroundOpacity) * progress
    }

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newValue in
                // 首次非零偏移时记录初始值，用于后续补偿
                if initialOffset == nil, newValue != 0 {
                    initialOffset = newValue
                }
                scrollOffset = newValue
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                navigationBarContainer
            }
    }

    /// 导航栏容器视图
    private var navigationBarContainer: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top

            // 背景高度：安全区 + 导航栏高度
            let backgroundHeight = safeAreaTop + config.height

            ZStack(alignment: .topLeading) {
                // 背景层
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: config.backgroundColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(backgroundOpacity)
                    .frame(height: backgroundHeight)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)

                // 导航栏内容
                ZStack {
                    // 标题居中
                    titleView

                    // leading 和 trailing 视图
                    HStack(alignment: .center) {
                        leadingView

                        Spacer()

                        trailingView
                    }
                }
                .frame(height: config.height)
                .padding(.horizontal, config.horizontalPadding)
            }
        }
        .frame(height: config.height)
    }
}

extension View {
    /// 为视图添加自定义导航栏（完整版：title + leading + trailing）
    public func customNavigationBar(
        @ViewBuilder title: () -> some View,
        @ViewBuilder leading: () -> some View,
        @ViewBuilder trailing: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: title(),
            leadingView: leading(),
            trailingView: trailing(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（title + leading）
    public func customNavigationBar(
        @ViewBuilder title: () -> some View,
        @ViewBuilder leading: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: title(),
            leadingView: leading(),
            trailingView: EmptyView(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（title + trailing）
    public func customNavigationBar(
        @ViewBuilder title: () -> some View,
        @ViewBuilder trailing: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: title(),
            leadingView: EmptyView(),
            trailingView: trailing(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（leading + trailing，无标题）
    public func customNavigationBar(
        @ViewBuilder leading: () -> some View,
        @ViewBuilder trailing: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: EmptyView(),
            leadingView: leading(),
            trailingView: trailing(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（仅 leading）
    public func customNavigationBar(
        @ViewBuilder leading: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: EmptyView(),
            leadingView: leading(),
            trailingView: EmptyView(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（仅 trailing）
    public func customNavigationBar(
        @ViewBuilder trailing: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: EmptyView(),
            leadingView: EmptyView(),
            trailingView: trailing(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（仅 title）
    public func customNavigationBar(
        @ViewBuilder title: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: title(),
            leadingView: EmptyView(),
            trailingView: EmptyView(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（String 标题 + leading + trailing）
    public func customNavigationBar(
        title: String?,
        @ViewBuilder leading: () -> some View,
        @ViewBuilder trailing: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: title.map {
                Text($0)
                    .font(config.titleFont)
                    .foregroundStyle(config.titleColor)
            },
            leadingView: leading(),
            trailingView: trailing(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（String 标题 + leading）
    public func customNavigationBar(
        title: String?,
        @ViewBuilder leading: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: title.map {
                Text($0)
                    .font(config.titleFont)
                    .foregroundStyle(config.titleColor)
            },
            leadingView: leading(),
            trailingView: EmptyView(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（String 标题 + trailing）
    public func customNavigationBar(
        title: String?,
        @ViewBuilder trailing: () -> some View,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: title.map {
                Text($0)
                    .font(config.titleFont)
                    .foregroundStyle(config.titleColor)
            },
            leadingView: EmptyView(),
            trailingView: trailing(),
            config: config
        ))
    }

    /// 为视图添加自定义导航栏（仅 String 标题）
    public func customNavigationBar(
        title: String?,
        config: CustomNavigationBarConfig = .default
    ) -> some View {
        modifier(CustomNavigationBarModifier(
            titleView: title.map {
                Text($0)
                    .font(config.titleFont)
                    .foregroundStyle(config.titleColor)
            },
            leadingView: EmptyView(),
            trailingView: EmptyView(),
            config: config
        ))
    }
}
