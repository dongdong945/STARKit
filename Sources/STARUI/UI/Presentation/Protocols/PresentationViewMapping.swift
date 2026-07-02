import SwiftUI

/// Presentation 视图映射协议
@MainActor
public protocol PresentationViewMapping {
    associatedtype Content: View

    /// 根据视图类型返回对应视图
    @ViewBuilder
    func view(for viewType: AnyHashable) -> Content
}
