import SwiftUI

/// Toast 模态展示器
@MainActor
@Observable
public final class ToastModal: ToastPresenting {
    /// 是否正在显示
    public var isPresented: Bool = false

    /// 当前 Toast 配置
    public private(set) var currentConfig: ToastConfiguration?

    /// 当前自动隐藏任务
    private var autoDismissTask: Task<Void, Never>?

    public init() {}

    /// 展示 Toast
    public func present(config: ToastConfiguration) {
        // 取消旧的自动隐藏任务
        autoDismissTask?.cancel()
        autoDismissTask = nil

        // 如果当前正在显示 Toast，先立即隐藏
        let wasPresented = isPresented
        if wasPresented {
            isPresented = false
        }

        // 设置新配置
        currentConfig = config

        // 创建显示和自动隐藏任务
        autoDismissTask = Task { @MainActor in
            // 如果之前有显示，等待消失动画完成
            if wasPresented {
                try? await Task.sleep(for: .seconds(0.1))
            }

            // 检查任务是否被取消
            guard !Task.isCancelled else { return }

            // 显示新的 Toast
            withAnimation {
                isPresented = true
            }

            // 如果 duration > 0，自动隐藏
            if config.duration > 0 {
                try? await Task.sleep(for: .seconds(config.duration))
                // 检查任务是否被取消
                guard !Task.isCancelled else { return }

                withAnimation {
                    isPresented = false
                }
            }
        }
    }

    /// 隐藏 Toast
    public func dismiss() {
        // 取消自动隐藏任务
        autoDismissTask?.cancel()
        autoDismissTask = nil

        withAnimation {
            isPresented = false
        }
    }
}
