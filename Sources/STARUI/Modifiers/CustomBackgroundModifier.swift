import SwiftUI

public enum CustomBackgroundStyle: Sendable {
    case fixed
    case scroll
    case stickyTop
    case stretchyTop
}

struct CustomBackgroundLayout: Equatable {
    let yOffset: CGFloat
    let extraHeight: CGFloat

    static func make(style: CustomBackgroundStyle, scrollOffset: CGFloat) -> Self {
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

private struct CustomBackgroundHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct CustomBackgroundLayer<Background: View>: View {
    let height: CGFloat?
    let fillColor: Color?
    let style: CustomBackgroundStyle
    let scrollOffset: CGFloat
    let background: Background

    @StoredState
    private var measuredHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let layout = CustomBackgroundLayout.make(style: style, scrollOffset: scrollOffset)
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
                    background
                        .frame(width: width, height: height, alignment: .top)
                }
                .clipped()
        } else {
            background
                .frame(width: width, alignment: .top)
        }
    }

    private func measuredBackground(width: CGFloat) -> some View {
        background
            .frame(width: width, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: CustomBackgroundHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            }
            .onPreferenceChange(CustomBackgroundHeightPreferenceKey.self) { newValue in
                measuredHeight = newValue
            }
    }
}

struct CustomBackgroundContentModifier<Background: View>: ViewModifier {
    let height: CGFloat?
    let fillColor: Color?
    let style: CustomBackgroundStyle
    let background: Background

    @StoredState
    private var scrollOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                CustomBackgroundLayer(
                    height: height,
                    fillColor: fillColor,
                    style: style,
                    scrollOffset: scrollOffset,
                    background: background
                )
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, newValue in
                scrollOffset = newValue
            }
    }
}

/// 自定义背景修饰符：支持任意 View 背景与滚动行为样式
public struct CustomBackgroundModifier<Background: View>: ViewModifier {
    /// 背景初始高度
    public let height: CGFloat?
    /// 背景填充色
    public let fillColor: Color?
    /// 背景滚动样式
    public let style: CustomBackgroundStyle
    /// 背景内容
    public let background: Background

    public init(
        height: CGFloat? = nil,
        fillColor: Color? = nil,
        style: CustomBackgroundStyle = .fixed,
        @ViewBuilder background: () -> Background
    ) {
        self.height = height
        self.fillColor = fillColor
        self.style = style
        self.background = background()
    }

    public func body(content: Content) -> some View {
        content.modifier(
            CustomBackgroundContentModifier(
                height: height,
                fillColor: fillColor,
                style: style,
                background: background
            )
        )
    }
}
