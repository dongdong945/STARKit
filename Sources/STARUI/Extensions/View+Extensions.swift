import AVFoundation
import SwiftUI

extension View {
    /// 监听设备摇动事件
    public func onShake(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
            action()
        }
    }

    /// 将视图渲染为 UIImage
    @MainActor
    public func asImage(opaque: Bool = false) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = opaque
        return renderer.uiImage
    }

    /// 为视图添加渐变前景色
    public func gradientForeground(
        stops: [Gradient.Stop] = [
            Gradient.Stop(color: Color.white.opacity(0.5), location: 0.00),
            Gradient.Stop(color: Color.white, location: 1.00)
        ],
        startPoint: UnitPoint = UnitPoint(x: 0, y: 0.5),
        endPoint: UnitPoint = UnitPoint(x: 1, y: 0.5)
    ) -> some View {
        modifier(GradientForegroundModifier(stops: stops, startPoint: startPoint, endPoint: endPoint))
    }

    /// 添加自定义图片背景（宽度填充、顶部对齐）
    public func customImageBackground(
        image: SwiftUI.ImageResource,
        height: CGFloat? = nil,
        fillColor: Color? = nil,
        style: CustomImageBackgroundStyle = .fixed,
        scaling: CustomImageBackgroundScaling = .fill
    ) -> some View {
        modifier(CustomImageBackgroundModifier(
            image: image,
            height: height,
            fillColor: fillColor,
            style: style,
            scaling: scaling
        ))
    }

    /// 添加自定义图片背景（宽度填充、顶部对齐）
    public func customImageBackground(
        url: URL?,
        height: CGFloat? = nil,
        fillColor: Color? = nil,
        style: CustomImageBackgroundStyle = .fixed,
        scaling: CustomImageBackgroundScaling = .fill
    ) -> some View {
        modifier(CustomImageBackgroundModifier(
            url: url,
            height: height,
            fillColor: fillColor,
            style: style,
            scaling: scaling
        ))
    }

    /// 添加自定义背景（宽度填充、顶部对齐）
    public func customBackground(
        height: CGFloat? = nil,
        fillColor: Color? = nil,
        style: CustomBackgroundStyle = .fixed,
        @ViewBuilder background: () -> some View
    ) -> some View {
        modifier(CustomBackgroundModifier(
            height: height,
            fillColor: fillColor,
            style: style,
            background: background
        ))
    }

    /// 添加自定义视频背景（宽度填充、顶部对齐）
    public func customVideoBackground(
        video: String,
        fillColor: Color = .black
    ) -> some View {
        modifier(CustomVideoBackgroundModifier(
            videoName: video,
            fillColor: fillColor
        ))
    }
}
