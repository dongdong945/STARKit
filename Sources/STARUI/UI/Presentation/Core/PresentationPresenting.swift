import SwiftUI

/// Presentation 展示协议
@MainActor
public protocol PresentationPresenting: AnyObject {
    /// 当前展示栈
    var stack: [PresentationItem] { get }

    /// 展示一个视图
    func present(_ item: PresentationItem)

    /// 关闭最顶层视图
    func dismiss()

    /// 关闭所有视图
    func dismissAll()

    /// 从指定索引关闭
    func dismissFrom(index: Int)
}

/// Presentation 数据项
public struct PresentationItem: Identifiable {
    /// 视图类型标识符（支持任意 Hashable 类型）
    public let viewType: AnyHashable

    /// 展示样式
    public let style: PresentationStyle

    /// 唯一标识符
    public let id: String

    public init(viewType: AnyHashable, style: PresentationStyle) {
        self.viewType = viewType
        self.style = style
        id = "\(viewType)_\(style == .sheet ? "sheet" : "cover")"
    }
}

/// Presentation 展示样式
public enum PresentationStyle {
    case sheet
    case fullScreenCover
}

/// Sheet 包装类型（满足 SwiftUI 的 .sheet(item:) 类型要求）
public struct SheetWrapper: Identifiable {
    public let item: PresentationItem
    public var id: String { item.id }

    public init(item: PresentationItem) {
        self.item = item
    }
}

/// FullScreenCover 包装类型（满足 SwiftUI 的 .fullScreenCover(item:) 类型要求）
public struct CoverWrapper: Identifiable {
    public let item: PresentationItem
    public var id: String { item.id }

    public init(item: PresentationItem) {
        self.item = item
    }
}

/// 包装类型协议，使泛型 Binding 成为可能
public protocol PresentationWrapping: Identifiable {
    var item: PresentationItem { get }
    init(item: PresentationItem)
}

extension SheetWrapper: PresentationWrapping {}
extension CoverWrapper: PresentationWrapping {}
