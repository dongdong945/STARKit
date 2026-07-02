import SwiftUI

/// 进度条样式
public enum ProgressBarStyle: Sendable {
    /// 线性进度条
    case linear
    /// 圆形进度条
    case circular
}

/// 通用进度条组件
public struct ProgressBar: View {
    /// 当前进度值（0.0 - 1.0）
    public let progress: CGFloat
    /// 初始进度值（用于首次出现时的动画起始点）
    public let initialProgress: CGFloat
    /// 进度条渐变颜色数组
    public let colors: [Color]
    /// 背景颜色
    public let backgroundColor: Color
    /// 进度条样式（线性或圆形）
    public let style: ProgressBarStyle
    /// 进度条宽度/粗细
    public let lineWidth: CGFloat
    /// 是否启用动画
    public let animated: Bool
    /// 是否使用圆角端点
    public let roundedLineCap: Bool
    /// 首次出现时的动画时长（秒）
    public let appearAnimationDuration: TimeInterval
    /// 进度变化时的动画时长（秒）
    public let changeAnimationDuration: TimeInterval

    @State
    private var animatedProgress: CGFloat = 0

    /// 创建进度条
    public init(
        progress: CGFloat,
        initialProgress: CGFloat = 0,
        colors: [Color] = [Color("#1E55EC")],
        backgroundColor: Color = Color.white.opacity(0.03),
        style: ProgressBarStyle = .linear,
        lineWidth: CGFloat = 4,
        animated: Bool = true,
        roundedLineCap: Bool = true,
        appearAnimationDuration: TimeInterval = 1.0,
        changeAnimationDuration: TimeInterval = 0.5
    ) {
        // 边界值验证：确保进度值在 0.0 - 1.0 范围内
        self.progress = max(0, min(1, progress))
        self.initialProgress = max(0, min(1, initialProgress))
        // 确保颜色数组不为空
        self.colors = colors.isEmpty ? [Color("#1E55EC")] : colors
        self.backgroundColor = backgroundColor
        self.style = style
        self.lineWidth = lineWidth
        self.animated = animated
        self.roundedLineCap = roundedLineCap
        self.appearAnimationDuration = appearAnimationDuration
        self.changeAnimationDuration = changeAnimationDuration
    }

    public var body: some View {
        Group {
            switch style {
            case .linear:
                linearProgressBar
            case .circular:
                circularProgressBar
            }
        }
        .onAppear {
            // 设置初始进度
            animatedProgress = initialProgress
            if animated {
                // 使用参数化的动画时长
                withAnimation(.easeInOut(duration: appearAnimationDuration)) {
                    animatedProgress = progress
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            if animated {
                // 使用参数化的动画时长
                withAnimation(.easeInOut(duration: changeAnimationDuration)) {
                    animatedProgress = newValue
                }
            } else {
                animatedProgress = newValue
            }
        }
    }

    /// 线性进度条
    @ViewBuilder
    private var linearProgressBar: some View {
        GeometryReader { geometry in
            backgroundColor
                .overlay(alignment: .leading) {
                    LinearGradient(
                        gradient: Gradient(colors: colors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * animatedProgress)
                    .clipShape(RoundedRectangle(cornerRadius: roundedLineCap ? lineWidth / 2 : 0))
                }
                .clipShape(RoundedRectangle(cornerRadius: roundedLineCap ? lineWidth / 2 : 0))
        }
        .frame(height: lineWidth)
    }

    /// 圆形进度条
    @ViewBuilder
    private var circularProgressBar: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // 进度圆环
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + Double(360) * Double(animatedProgress))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: roundedLineCap ? .round : .butt)
                )
                .rotationEffect(.degrees(-90)) // 从顶部开始
        }
        .padding(lineWidth / 2)
    }
}

#Preview("Basic Usage") {
    VStack(spacing: 30) {
        // 最简单用法
        VStack(alignment: .leading, spacing: 8) {
            Text("Simple progress bar (default style)")
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressBar(progress: 0.3)
                .frame(height: 4)
        }

        // 自定义颜色和宽度
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom colors & width")
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressBar(
                progress: 0.7,
                colors: [.green, .blue],
                lineWidth: 6
            )
            .frame(height: 6)
        }

        // 圆形进度条
        VStack(alignment: .leading, spacing: 8) {
            Text("Circular progress bar")
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressBar(
                progress: 0.85,
                colors: [.purple, .pink],
                style: .circular,
                lineWidth: 10
            )
            .frame(width: 100, height: 100)
        }
    }
    .padding()
}

#Preview("Advanced Usage") {
    VStack(spacing: 30) {
        // 渐变主题
        VStack(alignment: .leading, spacing: 8) {
            Text("Gradient theme (red to orange)")
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressBar(
                progress: 0.9,
                colors: [.red, .orange],
                backgroundColor: .black.opacity(0.1),
                lineWidth: 8
            )
            .frame(height: 8)
        }

        // 自定义动画时长
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom animation duration (slow: 2s)")
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressBar(
                progress: 0.6,
                colors: [.cyan, .indigo],
                appearAnimationDuration: 2.0,
                changeAnimationDuration: 0.3
            )
            .frame(height: 4)
        }

        // 无动画
        VStack(alignment: .leading, spacing: 8) {
            Text("No animation")
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressBar(
                progress: 0.5,
                colors: [.gray],
                animated: false
            )
            .frame(height: 4)
        }

        // 直角端点
        VStack(alignment: .leading, spacing: 8) {
            Text("Square line caps")
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressBar(
                progress: 0.4,
                colors: [.blue],
                roundedLineCap: false
            )
            .frame(height: 4)
        }
    }
    .padding()
}

#Preview("Real World") {
    /// Onboarding 进度示例
    struct OnboardingProgressDemo: View {
        @State
        private var currentStep = 1
        let totalSteps = 5

        var progress: CGFloat {
            CGFloat(currentStep) / CGFloat(totalSteps)
        }

        var initialProgress: CGFloat {
            max(0, CGFloat(currentStep - 1) / CGFloat(totalSteps))
        }

        var body: some View {
            VStack(spacing: 20) {
                Text("Onboarding Step \(currentStep) of \(totalSteps)")
                    .font(.headline)

                ProgressBar(
                    progress: progress,
                    initialProgress: initialProgress,
                    colors: [.blue.opacity(0), .blue]
                )
                .frame(height: 4)

                HStack {
                    Button("Previous") {
                        if currentStep > 1 {
                            currentStep -= 1
                        }
                    }
                    .disabled(currentStep == 1)

                    Spacer()

                    Button("Next") {
                        if currentStep < totalSteps {
                            currentStep += 1
                        }
                    }
                    .disabled(currentStep == totalSteps)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    return OnboardingProgressDemo()
}
