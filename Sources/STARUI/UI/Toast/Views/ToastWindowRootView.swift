import SwiftUI
import UIKit

/// Toast 窗口根视图
public struct ToastWindowRootView<ContentView: View>: View {
    /// Toast 数据模型
    @Bindable
    public var modal: ToastModal

    /// Toast 窗口实例引用
    public let window: UIWindow

    /// 内容视图构建器
    public let contentView: (ToastModal) -> ContentView

    public init(modal: ToastModal, window: UIWindow, contentView: @escaping (ToastModal) -> ContentView) {
        self.modal = modal
        self.window = window
        self.contentView = contentView
    }

    public var body: some View {
        contentView(modal)
            .onChange(of: modal.isPresented) { _, _ in
                updateWindowInteraction()
            }
            .onChange(of: modal.currentConfig?.type) { _, _ in
                updateWindowInteraction()
            }
            .onAppear {
                updateWindowInteraction()
            }
    }

    /// 更新窗口交互状态
    private func updateWindowInteraction() {
        // 控制窗口显示/隐藏
        window.isHidden = !modal.isPresented

        // loading 类型拦截触摸，其他类型穿透
        let shouldBlockTouch = modal.isPresented && modal.currentConfig?.type == .loading
        window.isUserInteractionEnabled = shouldBlockTouch
    }
}
