import SwiftUI

/// Alert 系统样式视图
public struct SystemAlertView: View {
    @Bindable
    public var modal: AlertModal

    public init(modal: AlertModal) {
        self.modal = modal
    }

    public var body: some View {
        Color.clear
            .ignoresSafeArea()
            .alert(
                modal.currentConfig?.title ?? "",
                isPresented: Binding(
                    get: { modal.isPresented },
                    set: { if !$0 { modal.dismiss() } }
                )
            ) {
                // 渲染按钮列表
                if let actions = modal.currentConfig?.actions {
                    ForEach(actions) { action in
                        Button(action.title, role: action.role) {
                            action.handler()
                        }
                    }
                }
            } message: {
                // 渲染消息内容
                if let message = modal.currentConfig?.message {
                    Text(message)
                }
            }
    }
}
