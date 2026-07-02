import SwiftUI

/// 可缩放的卡片轮播视图：中心卡片 100%，两侧卡片按比例缩放并向内偏移
public struct ScalableCarouselView<Content: View>: View {
    /// 卡片内容构建器
    private let content: (Int) -> Content
    /// 卡片数量
    private let itemCount: Int
    /// 当前页面索引
    @Binding
    private var currentPage: Int
    /// 卡片宽度
    private let cardWidth: CGFloat
    /// 卡片之间的间距
    private let spacing: CGFloat
    /// 边缘卡片的缩放比例（0.0 - 1.0）
    private let minScale: CGFloat

    public init(
        itemCount: Int,
        currentPage: Binding<Int>,
        cardWidth: CGFloat = 350,
        spacing: CGFloat = 8,
        minScale: CGFloat = 0.9,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.itemCount = itemCount
        _currentPage = currentPage
        self.spacing = spacing
        self.cardWidth = cardWidth
        self.minScale = minScale
        self.content = content
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                cards(for: geometry.size.width)
            }
            .scrollTargetBehavior(.viewAligned)
            .coordinateSpace(name: coordinateSpaceName)
            .onPreferenceChange(CardPositionPreferenceKey.self) { positions in
                updateCurrentPage(with: positions)
            }
        }
    }

    @ViewBuilder
    private func cards(for screenWidth: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(0 ..< itemCount, id: \.self) { index in
                card(for: index, screenWidth: screenWidth)
            }
        }
        .padding(.horizontal, horizontalPadding(for: screenWidth))
        .scrollTargetLayout()
    }

    private func card(for index: Int, screenWidth: CGFloat) -> some View {
        GeometryReader { cardGeometry in
            let cardCenter = cardGeometry.frame(in: .named(coordinateSpaceName)).midX
            let screenCenter = screenWidth / 2
            let transform = cardTransform(cardCenter: cardCenter, screenCenter: screenCenter)

            content(index)
                .frame(width: cardWidth)
                .scaleEffect(transform.scale)
                .offset(x: transform.offset)
                .preference(
                    key: CardPositionPreferenceKey.self,
                    value: [
                        CardPosition(
                            index: index,
                            center: transform.adjustedCenter,
                            screenCenter: screenCenter
                        )
                    ]
                )
        }
        .frame(width: cardWidth)
    }

    private func cardTransform(cardCenter: CGFloat, screenCenter: CGFloat) -> (scale: CGFloat, offset: CGFloat, adjustedCenter: CGFloat) {
        let distance = abs(cardCenter - screenCenter)
        let scale = scale(for: distance)
        let offset = inwardOffset(for: scale, isLeftOfCenter: cardCenter < screenCenter)
        return (scale, offset, cardCenter + offset)
    }

    private func scale(for distance: CGFloat) -> CGFloat {
        let maxDistance = (cardWidth + spacing) / 2
        let normalizedDistance = min(distance / maxDistance, 1.0)
        return 1.0 - normalizedDistance * (1.0 - minScale)
    }

    // 缩放后卡片宽度减少，向中心平移抵消被放大的间距
    private func inwardOffset(for scale: CGFloat, isLeftOfCenter: Bool) -> CGFloat {
        let offset = (1 - scale) * cardWidth / 2
        return isLeftOfCenter ? offset : -offset
    }

    private func horizontalPadding(for screenWidth: CGFloat) -> CGFloat {
        (screenWidth - cardWidth) / 2
    }

    private func updateCurrentPage(with positions: [CardPosition]) {
        guard let closestCard = positions.min(by: { abs($0.center - $0.screenCenter) < abs($1.center - $1.screenCenter) }) else {
            return
        }

        withAnimation {
            currentPage = closestCard.index
        }
    }

    private let coordinateSpaceName = "scalable_carousel_scroll"
}

private struct CardPosition: Equatable {
    let index: Int
    let center: CGFloat
    let screenCenter: CGFloat
}

private struct CardPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [CardPosition] { [] }

    static func reduce(value: inout [CardPosition], nextValue: () -> [CardPosition]) {
        value.append(contentsOf: nextValue())
    }
}
