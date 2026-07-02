import AppsFlyerLib
import Foundation

final class AppsFlyerAdapter: Adapter {
    nonisolated(unsafe) static var enableLog: Bool = false

    nonisolated(unsafe) static var logs = ThreadSafeArray<(name: String, param: [String: Any]?)>()

    static func clearLogs() {
        logs.removeAll()
    }

    static func sendEvent<T: STAREventSendable>(_ event: T, param: [T.Parameter: Any]?) {
        let mapping = T.eventNameMapping(platform: platform)
        let event = mapping?[event] ?? event.rawValue
        var newParam: [String: Any]?
        if let param {
            newParam = [:]
            param.forEach { key, value in
                newParam?[key.rawValue] = value
            }
        }

        AppsFlyerLib.shared().logEvent(event, withValues: newParam)

        if enableLog {
            logs.append((event, newParam))
        }
    }

    static func sendEvent(_ event: String, param: [String: Any]?) {
        AppsFlyerLib.shared().logEvent(event, withValues: param)

        if enableLog {
            logs.append((event, param))
        }
    }

    static func setUserProperty(_ name: some FIRUserPropertySendable, value: Any?) {
        print("\(platform.adapter) does not support \(#function)")
    }

    static func setUserProperty(_ name: String, value: Any?) {
        print("\(platform.adapter) does not support \(#function)")
    }

    static func setUserProperties(_ userProperties: [String: Any?]) {
        print("\(platform.adapter) does not support \(#function)")
    }

    static func setUserPropertyOnce(_ name: String, value: Any?) {
        print("\(platform.adapter) does not support \(#function)")
    }

    static func setUserPropertiesOnce(_ userProperties: [String: Any?]) {
        print("\(platform.adapter) does not support \(#function)")
    }

    static func clearUserProperty(_ name: some FIRUserPropertySendable) {
        print("\(platform.adapter) does not support \(#function)")
    }

    static func clearUserProperty(_ name: String) {
        print("\(platform.adapter) does not support \(#function)")
    }

    static func clearUserProperties(_ names: [String]?) {
        print("\(platform.adapter) does not support \(#function)")
    }

    static let platform: Platform = .appsFlyer
}
