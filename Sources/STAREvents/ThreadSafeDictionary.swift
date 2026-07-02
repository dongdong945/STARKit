import Foundation

/// 线程安全字典
class ThreadSafeDictionary<Key: Hashable, Value> {
    private(set) var dictionary: [Key: Value] = [:]

    private let lock = NSLock()

    subscript(key: Key) -> Value? {
        get {
            lock.withLock { dictionary[key] }
        }

        set(newValue) {
            lock.withLock { dictionary[key] = newValue }
        }
    }

    var keys: Dictionary<Key, Value>.Keys {
        lock.withLock { dictionary.keys }
    }
}

extension ThreadSafeDictionary: Sequence {
    func makeIterator() -> Dictionary<Key, Value>.Iterator {
        lock.withLock { dictionary.makeIterator() }
    }
}

extension ThreadSafeDictionary: @unchecked Sendable {}
