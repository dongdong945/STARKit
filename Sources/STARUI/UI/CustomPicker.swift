import SwiftUI

/// 可滚动的通用选择器，支持垂直/水平，居中对齐并自动吸附最近项
public struct CustomPicker<Item: Hashable, Content: View>: View {
    // 数据属性
    @Binding
    private var selection: Item
    private let data: [Item]
    private let content: (Item) -> Content

    // 轴向和布局
    private var axis: Axis.Set = .vertical

    // 样式配置
    private var baseFont: Font = .system(size: 56, weight: .bold)
    private var foregroundColor: Color = .white
    private var edgeScale: CGFloat = 0.5
    private var minOpacity: Double = 0.3

    // 间距
    private var itemSpacing: CGFloat = 0

    // 单项尺寸
    private var itemSize: CGFloat = 70

    // 渐变遮罩
    private var maskBackgroundColor: Color = .init(red: 0.04, green: 0.04, blue: 0.04)
    private var gradientHeight: CGFloat = 100

    // 行为
    private var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .soft

    @StoredState
    private var scrollPosition: Item?
    @StoredState
    private var containerSize: CGSize = .init(width: 300, height: 300)
    @StoredState
    private var itemPositions: [Item: CGFloat] = [:]
    @StoredState
    private var isInitializing = true
    @StoredState
    private var isScrolling = false
    @StoredState
    private var scrollProxy: ScrollViewProxy?

    public init(
        selection: Binding<Item>,
        data: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        _selection = selection
        self.data = data
        self.content = content
    }

    public var body: some View {
        contentView
    }

    /// 主内容视图
    @ViewBuilder
    private var contentView: some View {
        GeometryReader { containerGeometry in
            ScrollViewReader { proxy in
                ZStack {
                    ScrollView(axis, showsIndicators: false) {
                        scrollViewContent
                    }
                    .scrollPosition(id: $scrollPosition, anchor: .center)
                    .onScrollPhaseChange { _, newPhase in
                        isScrolling = (newPhase != .idle)
                        if newPhase == .idle, !isInitializing {
                            snapToNearestItem(proxy: proxy)
                        }
                    }

                    startGradientMask
                    endGradientMask
                }
                .coordinateSpace(.named("picker"))
                .onAppear {
                    containerSize = containerGeometry.size
                    scrollProxy = proxy

                    scrollPosition = selection
                    proxy.scrollTo(selection, anchor: .center)
                    isInitializing = false
                }
                .onChange(of: containerGeometry.size) { _, newSize in
                    containerSize = newSize
                }
                .onChange(of: selection) { _, _ in
                    HapticHelper.shared.impact(style: hapticStyle)
                }
                .onPreferenceChange(ItemPositionPreferenceKey.self) { positions in
                    itemPositions = positions
                    updateSelectionDuringScroll(positions: positions)
                }
            }
        }
    }

    /// 滚动视图内容
    @ViewBuilder
    private var scrollViewContent: some View {
        Group {
            if axis == .vertical {
                LazyVStack(spacing: itemSpacing) {
                    ForEach(data, id: \.self) { item in
                        itemView(for: item)
                            .id(item)
                    }
                }
                .padding(.vertical, (mainAxisSize(of: containerSize) - itemSize) / 2)
            } else {
                LazyHStack(spacing: itemSpacing) {
                    ForEach(data, id: \.self) { item in
                        itemView(for: item)
                            .id(item)
                    }
                }
                .padding(.horizontal, (mainAxisSize(of: containerSize) - itemSize) / 2)
            }
        }
    }

    /// 单个项视图
    @ViewBuilder
    private func itemView(for item: Item) -> some View {
        GeometryReader { geometry in
            content(item)
                .fixedSize()
                .font(baseFont)
                .foregroundStyle(foregroundColor)
                .scaleEffect(calculateScale(for: geometry))
                .opacity(calculateOpacity(for: geometry))
                .frame(
                    maxWidth: axis == .vertical ? .infinity : nil,
                    maxHeight: axis == .horizontal ? .infinity : nil
                )
                .background(
                    GeometryReader { itemGeometry in
                        Color.clear
                            .preference(
                                key: ItemPositionPreferenceKey.self,
                                value: [item: mainAxisCenter(of: itemGeometry.frame(in: .named("picker")))]
                            )
                    }
                )
        }
        .frame(
            width: axis == .horizontal ? itemSize : nil,
            height: axis == .vertical ? itemSize : nil
        )
    }

    /// 起始端渐变遮罩
    @ViewBuilder
    private var startGradientMask: some View {
        if axis == .vertical {
            VStack {
                LinearGradient(
                    colors: [maskBackgroundColor, maskBackgroundColor.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: gradientHeight)
                Spacer()
            }
            .allowsHitTesting(false)
        } else {
            HStack {
                LinearGradient(
                    colors: [maskBackgroundColor, maskBackgroundColor.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: gradientHeight)
                Spacer()
            }
            .allowsHitTesting(false)
        }
    }

    /// 结束端渐变遮罩
    @ViewBuilder
    private var endGradientMask: some View {
        if axis == .vertical {
            VStack {
                Spacer()
                LinearGradient(
                    colors: [maskBackgroundColor.opacity(0), maskBackgroundColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: gradientHeight)
            }
            .allowsHitTesting(false)
        } else {
            HStack {
                Spacer()
                LinearGradient(
                    colors: [maskBackgroundColor.opacity(0), maskBackgroundColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: gradientHeight)
            }
            .allowsHitTesting(false)
        }
    }

    /// 提取主轴尺寸
    private func mainAxisSize(of size: CGSize) -> CGFloat {
        axis == .vertical ? size.height : size.width
    }

    /// 提取主轴中心位置
    private func mainAxisCenter(of frame: CGRect) -> CGFloat {
        axis == .vertical ? frame.midY : frame.midX
    }

    /// 容器中心位置
    private var pickerCenter: CGFloat {
        mainAxisSize(of: containerSize) / 2
    }

    /// 计算缩放比例
    private func calculateScale(for geometry: GeometryProxy) -> CGFloat {
        let frame = geometry.frame(in: .named("picker"))
        let itemCenter = mainAxisCenter(of: frame)
        let distance = abs(itemCenter - pickerCenter)
        let maxDistance = mainAxisSize(of: containerSize) * 0.4
        let normalizedDistance = min(distance / maxDistance, 1.0)
        return 1.0 - (1.0 - edgeScale) * normalizedDistance
    }

    /// 计算透明度
    private func calculateOpacity(for geometry: GeometryProxy) -> Double {
        let frame = geometry.frame(in: .named("picker"))
        let itemCenter = mainAxisCenter(of: frame)
        let distance = abs(itemCenter - pickerCenter)
        let maxDistance = mainAxisSize(of: containerSize) * 0.4
        let normalizedDistance = min(distance / maxDistance, 1.0)
        return 1.0 - (1.0 - minOpacity) * normalizedDistance
    }

    /// 在滚动时实时更新选中项
    private func updateSelectionDuringScroll(positions: [Item: CGFloat]) {
        guard !isInitializing else { return }
        guard !positions.isEmpty else { return }
        guard let nearestItem = findNearestItem(from: positions) else { return }

        if selection != nearestItem {
            selection = nearestItem
        }
    }

    /// 在滚动结束时自动对齐到最近项
    private func snapToNearestItem(proxy: ScrollViewProxy) {
        guard !itemPositions.isEmpty else { return }
        guard let targetItem = findNearestItem(from: itemPositions) else { return }

        if selection != targetItem {
            selection = targetItem
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
            proxy.scrollTo(targetItem, anchor: .center)
        }
    }

    /// 查找距离中心最近的项
    private func findNearestItem(from positions: [Item: CGFloat]) -> Item? {
        var nearestItem: Item?
        var minDistance: CGFloat = .infinity

        for (item, position) in positions {
            let distance = abs(position - pickerCenter)
            if distance < minDistance {
                minDistance = distance
                nearestItem = item
            }
        }

        return nearestItem
    }
}

extension CustomPicker {
    /// 滚动方向
    public func pickerAxis(_ axis: Axis.Set) -> CustomPicker {
        var picker = self
        picker.axis = axis
        return picker
    }

    /// 基准字体
    public func pickerFont(_ font: Font) -> CustomPicker {
        var picker = self
        picker.baseFont = font
        return picker
    }

    /// 前景色
    public func pickerForegroundColor(_ color: Color) -> CustomPicker {
        var picker = self
        picker.foregroundColor = color
        return picker
    }

    /// 边缘项缩放比例
    public func pickerEdgeScale(_ scale: CGFloat) -> CustomPicker {
        var picker = self
        picker.edgeScale = max(0.0, min(1.0, scale))
        return picker
    }

    /// 最小透明度
    public func pickerMinOpacity(_ opacity: Double) -> CustomPicker {
        var picker = self
        picker.minOpacity = max(0.0, min(1.0, opacity))
        return picker
    }

    /// 项间距
    public func pickerItemSpacing(_ spacing: CGFloat) -> CustomPicker {
        var picker = self
        picker.itemSpacing = max(0, spacing)
        return picker
    }

    /// 单项尺寸
    public func pickerItemSize(_ size: CGFloat) -> CustomPicker {
        var picker = self
        picker.itemSize = max(0, size)
        return picker
    }

    /// 遮罩背景色
    public func pickerMaskBackground(_ color: Color) -> CustomPicker {
        var picker = self
        picker.maskBackgroundColor = color
        return picker
    }

    /// 遮罩高度
    public func pickerGradientHeight(_ height: CGFloat) -> CustomPicker {
        var picker = self
        picker.gradientHeight = max(0, height)
        return picker
    }

    /// 触觉反馈样式
    public func pickerHapticStyle(_ hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle) -> CustomPicker {
        var picker = self
        picker.hapticStyle = hapticStyle
        return picker
    }
}

/// 项位置偏好键
private struct ItemPositionPreferenceKey<Item: Hashable>: PreferenceKey {
    static var defaultValue: [Item: CGFloat] { [:] }

    static func reduce(value: inout [Item: CGFloat], nextValue: () -> [Item: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}
