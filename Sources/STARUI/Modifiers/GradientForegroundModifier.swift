import SwiftUI

/// 渐变前景色修饰符
public struct GradientForegroundModifier: ViewModifier {
    /// 渐变色停点数组
    var stops: [Gradient.Stop]
    /// 渐变起始点
    var startPoint: UnitPoint
    /// 渐变结束点
    var endPoint: UnitPoint

    public func body(content: Content) -> some View {
        content.foregroundStyle(
            LinearGradient(
                stops: stops,
                startPoint: startPoint,
                endPoint: endPoint
            )
        )
    }
}
