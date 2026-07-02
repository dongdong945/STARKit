import SwiftUI
import UIKit

/// 触觉反馈管理器
@MainActor
@Observable
public final class HapticHelper {
    /// 共享单例实例
    public static let shared = HapticHelper()

    /// 是否启用触觉反馈
    public var isEnabled: Bool = true

    /// 私有初始化方法，强制使用单例
    private init() {}

    /// 触发指定样式的触觉反馈
    public func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// 触发轻触觉反馈（.light）
    public func light() {
        impact(style: .light)
    }

    /// 触发中等触觉反馈（.medium）
    public func medium() {
        impact(style: .medium)
    }

    /// 触发柔和触觉反馈（.soft）
    public func soft() {
        impact(style: .soft)
    }

    /// 触发重触觉反馈（.heavy）
    public func heavy() {
        impact(style: .heavy)
    }

    /// 触发刚性触觉反馈（.rigid）
    public func rigid() {
        impact(style: .rigid)
    }
}
