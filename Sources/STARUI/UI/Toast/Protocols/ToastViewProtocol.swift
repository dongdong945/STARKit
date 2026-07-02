import SwiftUI

/// Toast 自定义视图协议
@MainActor
public protocol ToastViewProtocol: View {
    /// 创建 Toast 视图
    init(modal: ToastModal)
}
