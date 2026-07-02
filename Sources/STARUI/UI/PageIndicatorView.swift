import SwiftUI

/// 简单页码指示器：当前页高亮，其余为圆点
public struct PageIndicatorView: View {
    public let totalPages: Int
    public let currentPage: Int
    public let selectedColor: Color
    public let normalColor: Color
    public let selectedSize: CGSize
    public let normalSize: CGSize
    public let spacing: CGFloat

    public init(
        totalPages: Int,
        currentPage: Int,
        selectedColor: Color = .accentColor,
        normalColor: Color = Color.white.opacity(0.08),
        selectedSize: CGSize = CGSize(width: 12, height: 8),
        normalSize: CGSize = CGSize(width: 8, height: 8),
        spacing: CGFloat = 4
    ) {
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.selectedColor = selectedColor
        self.normalColor = normalColor
        self.selectedSize = selectedSize
        self.normalSize = normalSize
        self.spacing = spacing
    }

    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0 ..< totalPages, id: \.self) { index in
                if currentPage == index {
                    selectedColor
                        .frame(width: selectedSize.width, height: selectedSize.height)
                        .clipShape(Capsule())
                } else {
                    normalColor
                        .frame(width: normalSize.width, height: normalSize.height)
                        .clipShape(Circle())
                }
            }
        }
    }
}
