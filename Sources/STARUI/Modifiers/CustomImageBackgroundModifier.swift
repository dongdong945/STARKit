import Kingfisher
import SwiftUI

public enum CustomImageBackgroundStyle: Sendable {
    case fixed
    case scroll
    case stickyTop
    case stretchyTop
}

public enum CustomImageBackgroundScaling: Sendable {
    case fill
    case fit
}

struct CustomImageBackgroundLayout: Equatable {
    let yOffset: CGFloat
    let extraHeight: CGFloat

    static func make(style: CustomImageBackgroundStyle, scrollOffset: CGFloat) -> Self {
        switch style {
        case .fixed:
            .init(yOffset: 0, extraHeight: 0)
        case .scroll:
            .init(yOffset: -scrollOffset, extraHeight: 0)
        case .stickyTop:
            .init(yOffset: min(-scrollOffset, 0), extraHeight: 0)
        case .stretchyTop:
            .init(
                yOffset: min(-scrollOffset, 0),
                extraHeight: max(-scrollOffset, 0)
            )
        }
    }

    func resolvedHeight(baseHeight: CGFloat) -> CGFloat {
        max(baseHeight + extraHeight, 0)
    }
}

private struct CustomImageBackgroundHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

enum CustomImageBackgroundSource {
    case resource(SwiftUI.ImageResource)
    case url(URL?)
}

struct CustomImageBackgroundLayer: View {
    let source: CustomImageBackgroundSource
    let height: CGFloat?
    let fillColor: Color?
    let style: CustomImageBackgroundStyle
    let scaling: CustomImageBackgroundScaling
    let scrollOffset: CGFloat

    @State
    private var measuredHeight: CGFloat = 0

    @ViewBuilder
    var body: some View {
        if usesContainerSizedLayout {
            containerSizedBackground
        } else {
            geometryDrivenBackground
        }
    }

    /// 固定全屏背景直接继承容器尺寸，避免转场期间按最终位置重新布局
    private var usesContainerSizedLayout: Bool {
        guard height == nil else { return false }

        switch style {
        case .fixed:
            return true
        case .scroll, .stickyTop, .stretchyTop:
            return false
        }
    }

    /// 固定背景直接填充页面容器
    private var containerSizedBackground: some View {
        (fillColor ?? .clear)
            .overlay(alignment: .top) {
                backgroundView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipped(if: scaling == .fill)
            }
            .ignoresSafeArea()
    }

    /// 滚动或指定高度背景沿用几何驱动布局
    private var geometryDrivenBackground: some View {
        GeometryReader { geometry in
            let layout = CustomImageBackgroundLayout.make(style: style, scrollOffset: scrollOffset)
            let baseHeight = height ?? measuredHeight
            let resolvedHeight = baseHeight > 0 ? layout.resolvedHeight(baseHeight: baseHeight) : nil

            (fillColor ?? .clear)
                .overlay(alignment: .top) {
                    visibleBackground(width: geometry.size.width, height: resolvedHeight)
                        .offset(y: layout.yOffset)
                }
                .overlay(alignment: .top) {
                    if height == nil {
                        measuredBackground(width: geometry.size.width)
                            .hidden()
                            .allowsHitTesting(false)
                    }
                }
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func visibleBackground(width: CGFloat, height: CGFloat?) -> some View {
        if let height {
            Color.clear
                .frame(width: width, height: height, alignment: .top)
                .overlay(alignment: .top) {
                    backgroundView
                        .frame(width: width, height: height, alignment: .top)
                }
                .clipped(if: scaling == .fill)
        } else {
            backgroundView
                .frame(width: width, alignment: .top)
        }
    }

    private func measuredBackground(width: CGFloat) -> some View {
        backgroundView
            .frame(width: width, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: CustomImageBackgroundHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            }
            .onPreferenceChange(CustomImageBackgroundHeightPreferenceKey.self) { newValue in
                measuredHeight = newValue
            }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch source {
        case .resource(let image):
            scaledImageView(Image(image).resizable())
        case .url(let url):
            scaledImageView(
                KFImage(url)
                    .placeholder { Color.clear }
                    .resizable()
            )
        }
    }

    @ViewBuilder
    private func scaledImageView(_ content: some View) -> some View {
        switch scaling {
        case .fill:
            content.scaledToFill()
        case .fit:
            content.scaledToFit()
        }
    }
}

struct CustomImageBackgroundContentModifier: ViewModifier {
    let source: CustomImageBackgroundSource
    let height: CGFloat?
    let fillColor: Color?
    let style: CustomImageBackgroundStyle
    let scaling: CustomImageBackgroundScaling

    @State
    private var scrollOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                CustomImageBackgroundLayer(
                    source: source,
                    height: height,
                    fillColor: fillColor,
                    style: style,
                    scaling: scaling,
                    scrollOffset: scrollOffset
                )
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, newValue in
                scrollOffset = newValue
            }
    }
}

/// 图片背景修饰符：宽度填充、顶部对齐，并支持滚动行为样式
public struct CustomImageBackgroundModifier: ViewModifier {
    /// 背景图片来源
    private let source: CustomImageBackgroundSource
    /// 背景初始高度
    public let height: CGFloat?
    /// 背景填充色
    public let fillColor: Color?
    /// 背景滚动样式
    public let style: CustomImageBackgroundStyle
    /// 背景缩放方式
    public let scaling: CustomImageBackgroundScaling

    public init(
        image: SwiftUI.ImageResource,
        height: CGFloat? = nil,
        fillColor: Color? = nil,
        style: CustomImageBackgroundStyle = .fixed,
        scaling: CustomImageBackgroundScaling = .fill
    ) {
        source = .resource(image)
        self.height = height
        self.fillColor = fillColor
        self.style = style
        self.scaling = scaling
    }

    public init(
        url: URL?,
        height: CGFloat? = nil,
        fillColor: Color? = nil,
        style: CustomImageBackgroundStyle = .fixed,
        scaling: CustomImageBackgroundScaling = .fill
    ) {
        source = .url(url)
        self.height = height
        self.fillColor = fillColor
        self.style = style
        self.scaling = scaling
    }

    public func body(content: Content) -> some View {
        content.modifier(
            CustomImageBackgroundContentModifier(
                source: source,
                height: height,
                fillColor: fillColor,
                style: style,
                scaling: scaling
            )
        )
    }
}

extension View {
    @ViewBuilder
    fileprivate func clipped(if shouldClip: Bool) -> some View {
        if shouldClip {
            clipped()
        } else {
            self
        }
    }
}
