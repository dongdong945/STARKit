import Foundation

/// 线程安全数组
public class ThreadSafeArray<Element> {
    private var internalArray: [Element] = []

    private let lock = NSLock()

    public var count: Int {
        lock.withLock { internalArray.count }
    }

    public subscript(index: Int) -> Element {
        get {
            lock.withLock { internalArray[index] }
        }

        set(newValue) {
            lock.withLock { internalArray[index] = newValue }
        }
    }

    public init() {}

    public func append(_ element: Element) {
        lock.withLock { internalArray.append(element) }
    }

    public func remove(at index: Int) {
        lock.withLock {
            _ = internalArray.remove(at: index)
        }
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        lock.withLock { internalArray.removeAll(keepingCapacity: keepCapacity) }
    }

    public var array: [Element] {
        lock.withLock { internalArray }
    }
}

extension ThreadSafeArray: @unchecked Sendable {}
