import SwiftUI

/// Alert 自定义视图协议
@MainActor
public protocol AlertViewProtocol: View {
    /// 创建 Alert 视图
    init(modal: AlertModal)
}
