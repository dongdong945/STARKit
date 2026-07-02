import SwiftUI

/// 数值刻度尺组件，支持垂直/水平滚动、吸附、可配置刻度/标签样式
public struct ScaleRuler: View {
    // 数据属性
    @Binding
    private var selectedValue: Double
    private let minValue: Double
    private let maxValue: Double
    private let step: Double

    // 轴向和布局
    private var axis: Axis.Set = .vertical
    private var tickAlignment: Alignment = .trailing

    // 间距
    private var tickSpacing: CGFloat = 8.0
    private var labelTickSpacing: CGFloat = 4.0

    // 刻度线
    private var majorTickInterval: Int = 5
    private var majorTickLength: CGFloat = 24
    private var minorTickLength: CGFloat = 12
    private var tickWidth: CGFloat = 2
    private var majorTickColor: Color = .white
    private var minorTickColor: Color = .white.opacity(0.4)

    // 标签
    private var showLabels: Bool = true
    private var labelAlignment: Alignment = .trailing
    private var labelFont: Font = .system(size: 16, weight: .regular)
    private var labelColor: Color = .white
    private var customLabel: ((Double) -> AnyView)? // 自定义标签闭包

    // 指示器
    private var indicatorColor: Color = .init("#62E86C")
    private var indicatorSize: CGSize = .init(width: 2, height: 60)

    // 渐变遮罩
    private var maskGradientColors: [Color] = [.clear]
    private var maskGradientLength: CGFloat = 100

    // 子刻度渐变层
    private var minorTickGradientColors: [Color] = [.clear]

    // 行为
    private var enableSnapping: Bool = true
    private var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .soft

    @State
    private var scrollPosition: Int?
    @State
    private var containerSize: CGSize = .zero
    @State
    private var tickPositions: [Int: CGFloat] = [:]
    @State
    private var isInitializing: Bool = true

    public init(
        selectedValue: Binding<Double>,
        minValue: Double,
        maxValue: Double,
        step: Double = 1.0,
        customLabel: ((Double) -> AnyView)? = nil
    ) {
        _selectedValue = selectedValue
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.customLabel = customLabel
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
                        if newPhase == .idle, !isInitializing {
                            snapToNearestTick(proxy: proxy)
                        }
                    }

                    startGradientMask
                    endGradientMask
                    minorTickGradientOverlay
                    centerIndicator
                }
                .coordinateSpace(.named("ruler"))
                .onAppear {
                    containerSize = containerGeometry.size
                }
                .onChange(of: containerGeometry.size) { _, newSize in
                    containerSize = newSize
                }
                .onChange(of: selectedValue) { _, _ in
                    HapticHelper.shared.impact(style: hapticStyle)
                }
                .onPreferenceChange(TickPositionPreferenceKey.self) { positions in
                    tickPositions = positions
                    updateSelectionDuringScroll(positions: positions)
                }
                .task {
                    scrollPosition = valueToIndex(selectedValue)
                    proxy.scrollTo(scrollPosition, anchor: .center)
                    try? await Task.sleep(for: .milliseconds(400))
                    isInitializing = false
                }
            }
        }
    }

    /// 滚动视图内容
    @ViewBuilder
    private var scrollViewContent: some View {
        Group {
            if axis == .vertical {
                LazyVStack(spacing: tickSpacing) {
                    ForEach(generateTickIndices(), id: \.self) { tickIndex in
                        tickView(for: tickIndex)
                            .id(tickIndex)
                    }
                }
                .padding(.vertical, (mainAxisSize(of: containerSize) - tickWidth) / 2)
            } else {
                LazyHStack(spacing: tickSpacing) {
                    ForEach(generateTickIndices(), id: \.self) { tickIndex in
                        tickView(for: tickIndex)
                            .id(tickIndex)
                    }
                }
                .padding(.horizontal, (mainAxisSize(of: containerSize) - tickWidth) / 2)
            }
        }
    }

    /// 单个刻度视图
    @ViewBuilder
    private func tickView(for tickIndex: Int) -> some View {
        let value = indexToValue(tickIndex)
        let isMajor = tickIndex % majorTickInterval == 0

        if axis == .vertical {
            HStack(spacing: 0) {
                // 根据刻度对齐添加前置 Spacer
                if tickAlignment.horizontal == .trailing || tickAlignment.horizontal == .center {
                    Spacer(minLength: 0)
                }

                // 刻度内容（标签+刻度线）
                HStack(spacing: labelTickSpacing) {
                    if labelAlignment.horizontal == .leading, showLabels, isMajor {
                        tickLabel(for: value)
                            .fixedSize()
                    }

                    tickMark(isMajor: isMajor)

                    if labelAlignment.horizontal == .trailing, showLabels, isMajor {
                        tickLabel(for: value)
                            .fixedSize()
                    }
                }

                // 根据刻度对齐添加后置 Spacer
                if tickAlignment.horizontal == .leading || tickAlignment.horizontal == .center {
                    Spacer(minLength: 0)
                }
            }
            .frame(height: tickWidth)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: TickPositionPreferenceKey.self,
                            value: [tickIndex: mainAxisCenter(of: geometry.frame(in: .named("ruler")))]
                        )
                }
            )
        } else {
            VStack(spacing: 0) {
                // 根据刻度对齐添加前置 Spacer
                if tickAlignment.vertical == .bottom || tickAlignment.vertical == .center {
                    Spacer(minLength: 0)
                }

                // 刻度内容（标签+刻度线）
                VStack(spacing: labelTickSpacing) {
                    if labelAlignment.vertical == .top, showLabels, isMajor {
                        tickLabel(for: value)
                            .fixedSize()
                    }

                    tickMark(isMajor: isMajor)

                    if labelAlignment.vertical == .bottom, showLabels, isMajor {
                        tickLabel(for: value)
                            .fixedSize()
                    }
                }

                // 根据刻度对齐添加后置 Spacer
                if tickAlignment.vertical == .top || tickAlignment.vertical == .center {
                    Spacer(minLength: 0)
                }
            }
            .frame(width: tickWidth)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: TickPositionPreferenceKey.self,
                            value: [tickIndex: mainAxisCenter(of: geometry.frame(in: .named("ruler")))]
                        )
                }
            )
        }
    }

    /// 刻度线
    @ViewBuilder
    private func tickMark(isMajor: Bool) -> some View {
        Rectangle()
            .fill(isMajor ? majorTickColor : minorTickColor)
            .frame(
                width: axis == .vertical ? (isMajor ? majorTickLength : minorTickLength) : tickWidth,
                height: axis == .horizontal ? (isMajor ? majorTickLength : minorTickLength) : tickWidth
            )
    }

    /// 刻度标签
    @ViewBuilder
    private func tickLabel(for value: Double) -> some View {
        if let customLabel {
            customLabel(value)
        } else {
            Text(formatValue(value))
                .font(labelFont)
                .foregroundStyle(labelColor)
        }
    }

    /// 子刻度渐变层
    @ViewBuilder
    private var minorTickGradientOverlay: some View {
        if minorTickGradientColors != [.clear] {
            if axis == .vertical {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            if tickAlignment.horizontal == .trailing || tickAlignment.horizontal == .center {
                                Spacer(minLength: 0)
                            }

                            LinearGradient(
                                colors: minorTickGradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: minorTickLength, height: geometry.size.height / 2)

                            if tickAlignment.horizontal == .leading || tickAlignment.horizontal == .center {
                                Spacer(minLength: 0)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                }
                .allowsHitTesting(false)
            } else {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            if tickAlignment.vertical == .bottom || tickAlignment.vertical == .center {
                                Spacer(minLength: 0)
                            }

                            LinearGradient(
                                colors: minorTickGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geometry.size.width / 2, height: minorTickLength)

                            if tickAlignment.vertical == .top || tickAlignment.vertical == .center {
                                Spacer(minLength: 0)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }

    /// 中心指示器
    @ViewBuilder
    private var centerIndicator: some View {
        if axis == .vertical {
            HStack(spacing: 0) {
                if tickAlignment.horizontal == .trailing || tickAlignment.horizontal == .center {
                    Spacer(minLength: 0)
                }

                Rectangle()
                    .fill(indicatorColor)
                    .frame(width: indicatorSize.height, height: indicatorSize.width)

                if tickAlignment.horizontal == .leading || tickAlignment.horizontal == .center {
                    Spacer(minLength: 0)
                }
            }
        } else {
            VStack(spacing: 0) {
                if tickAlignment.vertical == .bottom || tickAlignment.vertical == .center {
                    Spacer(minLength: 0)
                }

                Rectangle()
                    .fill(indicatorColor)
                    .frame(width: indicatorSize.width, height: indicatorSize.height)

                if tickAlignment.vertical == .top || tickAlignment.vertical == .center {
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// 起始端渐变遮罩
    @ViewBuilder
    private var startGradientMask: some View {
        if maskGradientColors != [.clear] {
            if axis == .vertical {
                VStack {
                    LinearGradient(
                        colors: maskGradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: maskGradientLength)
                    Spacer()
                }
                .allowsHitTesting(false)
            } else {
                HStack {
                    LinearGradient(
                        colors: maskGradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: maskGradientLength)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
    }

    /// 结束端渐变遮罩
    @ViewBuilder
    private var endGradientMask: some View {
        if maskGradientColors != [.clear] {
            if axis == .vertical {
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: maskGradientColors.reversed(),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: maskGradientLength)
                }
                .allowsHitTesting(false)
            } else {
                HStack {
                    Spacer()
                    LinearGradient(
                        colors: maskGradientColors.reversed(),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: maskGradientLength)
                }
                .allowsHitTesting(false)
            }
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
    private var rulerCenter: CGFloat {
        mainAxisSize(of: containerSize) / 2
    }

    /// 将值转换为索引
    private func valueToIndex(_ value: Double) -> Int {
        Int(round((value - minValue) / step))
    }

    /// 将索引转换为值
    private func indexToValue(_ index: Int) -> Double {
        minValue + Double(index) * step
    }

    /// 生成刻度索引数组
    private func generateTickIndices() -> [Int] {
        let tickCount = Int(round((maxValue - minValue) / step)) + 1
        return Array(0 ..< tickCount)
    }

    /// 格式化数值显示
    private func formatValue(_ value: Double) -> String {
        if step >= 1 {
            return String(format: "%.0f", value)
        } else if step >= 0.1 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }

    /// 在滚动时实时更新选中值
    private func updateSelectionDuringScroll(positions: [Int: CGFloat]) {
        guard !isInitializing, !positions.isEmpty else { return }
        guard let nearestIndex = findNearestTickIndex(from: positions) else { return }

        let newValue = indexToValue(nearestIndex)
        if selectedValue != newValue {
            selectedValue = newValue
        }
    }

    /// 在滚动结束时自动对齐到最近刻度
    private func snapToNearestTick(proxy: ScrollViewProxy) {
        guard enableSnapping, !tickPositions.isEmpty else { return }
        guard let targetIndex = findNearestTickIndex(from: tickPositions) else { return }

        selectedValue = indexToValue(targetIndex)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
            proxy.scrollTo(targetIndex, anchor: .center)
        }
    }

    /// 查找距离中心最近的刻度索引
    private func findNearestTickIndex(from positions: [Int: CGFloat]) -> Int? {
        positions.min(by: { abs($0.value - rulerCenter) < abs($1.value - rulerCenter) })?.key
    }
}

extension ScaleRuler {
    /// 滚动方向
    public func rulerAxis(_ axis: Axis.Set) -> ScaleRuler {
        var ruler = self
        ruler.axis = axis
        return ruler
    }

    /// 刻度对齐
    public func rulerTickAlignment(_ alignment: Alignment) -> ScaleRuler {
        var ruler = self
        ruler.tickAlignment = alignment
        return ruler
    }

    /// 刻度间距
    public func rulerTickSpacing(_ spacing: CGFloat) -> ScaleRuler {
        var ruler = self
        ruler.tickSpacing = max(0, spacing)
        return ruler
    }

    /// 标签与刻度线间距
    public func rulerLabelTickSpacing(_ spacing: CGFloat) -> ScaleRuler {
        var ruler = self
        ruler.labelTickSpacing = max(0, spacing)
        return ruler
    }

    /// 主刻度间隔
    public func rulerMajorTickInterval(_ interval: Int) -> ScaleRuler {
        var ruler = self
        ruler.majorTickInterval = max(1, interval)
        return ruler
    }

    /// 主刻度线长度
    public func rulerMajorTickLength(_ length: CGFloat) -> ScaleRuler {
        var ruler = self
        ruler.majorTickLength = max(0, length)
        return ruler
    }

    /// 次刻度线长度
    public func rulerMinorTickLength(_ length: CGFloat) -> ScaleRuler {
        var ruler = self
        ruler.minorTickLength = max(0, length)
        return ruler
    }

    /// 刻度线粗细
    public func rulerTickWidth(_ width: CGFloat) -> ScaleRuler {
        var ruler = self
        ruler.tickWidth = max(0, width)
        return ruler
    }

    /// 主刻度颜色
    public func rulerMajorTickColor(_ color: Color) -> ScaleRuler {
        var ruler = self
        ruler.majorTickColor = color
        return ruler
    }

    /// 次刻度颜色
    public func rulerMinorTickColor(_ color: Color) -> ScaleRuler {
        var ruler = self
        ruler.minorTickColor = color
        return ruler
    }

    /// 显示标签
    public func rulerShowLabels(_ show: Bool) -> ScaleRuler {
        var ruler = self
        ruler.showLabels = show
        return ruler
    }

    /// 标签对齐
    public func rulerLabelAlignment(_ alignment: Alignment) -> ScaleRuler {
        var ruler = self
        ruler.labelAlignment = alignment
        return ruler
    }

    /// 标签字体
    public func rulerLabelFont(_ font: Font) -> ScaleRuler {
        var ruler = self
        ruler.labelFont = font
        return ruler
    }

    /// 标签颜色
    public func rulerLabelColor(_ color: Color) -> ScaleRuler {
        var ruler = self
        ruler.labelColor = color
        return ruler
    }

    /// 指示器颜色
    public func rulerIndicatorColor(_ color: Color) -> ScaleRuler {
        var ruler = self
        ruler.indicatorColor = color
        return ruler
    }

    /// 指示器尺寸
    public func rulerIndicatorSize(_ size: CGSize) -> ScaleRuler {
        var ruler = self
        ruler.indicatorSize = size
        return ruler
    }

    /// 渐变遮罩颜色
    public func rulerMaskGradientColors(_ colors: [Color]) -> ScaleRuler {
        var ruler = self
        ruler.maskGradientColors = colors
        return ruler
    }

    /// 渐变遮罩长度
    public func rulerMaskGradientLength(_ length: CGFloat) -> ScaleRuler {
        var ruler = self
        ruler.maskGradientLength = max(0, length)
        return ruler
    }

    /// 子刻度渐变层颜色
    public func rulerMinorTickGradientColors(_ colors: [Color]) -> ScaleRuler {
        var ruler = self
        ruler.minorTickGradientColors = colors
        return ruler
    }

    /// 自动对齐到刻度
    public func rulerEnableSnapping(_ enable: Bool) -> ScaleRuler {
        var ruler = self
        ruler.enableSnapping = enable
        return ruler
    }

    /// 触觉反馈样式
    public func rulerHapticStyle(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> ScaleRuler {
        var ruler = self
        ruler.hapticStyle = style
        return ruler
    }
}

/// 刻度位置偏好键
private struct TickPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] { [:] }

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}
