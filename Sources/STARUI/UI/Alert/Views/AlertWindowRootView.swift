import SwiftUI
import UIKit

/// Alert 窗口根视图
public struct AlertWindowRootView<ContentView: View>: View {
    @Bindable
    public var modal: AlertModal

    public let window: UIWindow
    public let contentView: (AlertModal) -> ContentView

    // 用于取消延迟隐藏任务
    @StoredState
    private var hideWindowTask: DispatchWorkItem?

    public init(modal: AlertModal, window: UIWindow, contentView: @escaping (AlertModal) -> ContentView) {
        self.modal = modal
        self.window = window
        self.contentView = contentView
    }

    public var body: some View {
        contentView(modal)
            .onChange(of: modal.isPresented) { _, _ in
                updateWindowInteraction()
            }
            .onAppear {
                updateWindowInteraction()
            }
    }

    private func updateWindowInteraction() {
        // 取消之前的延迟隐藏任务
        hideWindowTask?.cancel()
        hideWindowTask = nil

        if modal.isPresented {
            // 显示：立即显示窗口
            window.isHidden = false
            window.isUserInteractionEnabled = true
        } else {
            // 隐藏：先禁用交互，延迟隐藏窗口（等待动画完成）
            window.isUserInteractionEnabled = false

            // 创建可取消的延迟任务
            let task = DispatchWorkItem { [weak window] in
                window?.isHidden = true
            }
            hideWindowTask = task

            // 延迟 0.25 秒（与消失动画时长一致）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: task)
        }
    }
}
