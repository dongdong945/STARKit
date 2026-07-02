import Foundation

public protocol Adapter {
    /// 是否记录发送的事件
    static var enableLog: Bool { get set }

    /// 获取记录的事件
    static var logs: ThreadSafeArray<(name: String, param: [String: Any]?)> { get }

    /// 清空记录的事件
    static func clearLogs()

    /// 发送事件
    static func sendEvent<T: STAREventSendable>(_ event: T, param: [T.Parameter: Any]?)

    /// 发送事件
    static func sendEvent(_ event: String, param: [String: Any]?)

    /// 设置用户属性
    static func setUserProperty(_ name: some FIRUserPropertySendable, value: Any?)

    /// 设置用户属性
    static func setUserProperty(_ name: String, value: Any?)

    /// 设置用户属性
    static func setUserProperties(_ userProperties: [String: Any?])

    /// 设置用户属性（用户生命周期内只设置一次）
    static func setUserPropertyOnce(_ name: String, value: Any?)

    /// 设置用户属性（用户生命周期内只设置一次）
    static func setUserPropertiesOnce(_ userProperties: [String: Any?])

    /// 清空用户属性
    static func clearUserProperty(_ name: some FIRUserPropertySendable)

    /// 清空用户属性
    static func clearUserProperty(_ name: String)

    /// 清空用户属性，如果names为nil，则清空用户所有属性
    static func clearUserProperties(_ names: [String]?)

    /// 平台
    static var platform: Platform { get }
}
