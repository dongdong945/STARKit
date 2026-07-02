import SwiftUI

/// Presentation 管理器
@MainActor
@Observable
public final class PresentationHelper: PresentationPresenting {
    /// Presentation 栈（从 root 到最上层）
    public private(set) var stack: [PresentationItem] = []

    public init() {}

    /// 展示一个视图
    public func present(_ viewType: some Hashable, as style: PresentationStyle) {
        let item = PresentationItem(viewType: AnyHashable(viewType), style: style)
        present(item)
    }

    /// 关闭最顶层视图
    public func dismiss() {
        if !stack.isEmpty {
            stack.removeLast()
        }
    }

    /// 关闭所有视图
    public func dismissAll() {
        stack.removeAll()
    }

    public func present(_ item: PresentationItem) {
        stack.append(item)
    }

    public func dismissFrom(index: Int) {
        guard index >= 0, index < stack.count else { return }
        stack.removeSubrange((index + 1)...)
    }

    /// 获取指定索引的 item
    public func item(at index: Int) -> PresentationItem? {
        guard index < stack.count else { return nil }
        return stack[index]
    }

    /// 当前栈深度
    public var depth: Int {
        stack.count
    }

    /// 当前最顶层样式
    public var currentStyle: PresentationStyle? {
        stack.last?.style
    }
}
