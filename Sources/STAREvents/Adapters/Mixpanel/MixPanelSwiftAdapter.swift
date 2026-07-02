import Foundation
import Mixpanel

final class MixPanelAdapter: Adapter {
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

        Mixpanel.mainInstance().track(event: event, properties: newParam as? Properties)

        if enableLog {
            logs.append((event, newParam))
        }
    }

    static func sendEvent(_ event: String, param: [String: Any]?) {
        Mixpanel.mainInstance().track(event: event, properties: param as? Properties)

        if enableLog {
            logs.append((event, param))
        }
    }

    static func setUserProperty(_ name: some FIRUserPropertySendable, value: Any?) {
        setUserProperties([name.rawValue: value])
    }

    static func setUserProperty(_ name: String, value: Any?) {
        setUserProperties([name: value])
    }

    static func setUserProperties(_ userProperties: [String: Any?]) {
        let userProperties = userProperties.compactMapValues { $0 } as? Properties ?? [:]
        Mixpanel.mainInstance().registerSuperProperties(userProperties)
        Mixpanel.mainInstance().people.set(properties: userProperties)
    }

    static func setUserPropertyOnce(_ name: String, value: Any?) {
        setUserPropertiesOnce([name: value])
    }

    static func setUserPropertiesOnce(_ userProperties: [String: Any?]) {
        let userProperties = userProperties.compactMapValues { $0 } as? Properties ?? [:]
        Mixpanel.mainInstance().registerSuperPropertiesOnce(userProperties)
        Mixpanel.mainInstance().people.setOnce(properties: userProperties)
    }

    static func clearUserProperty(_ name: some FIRUserPropertySendable) {
        clearUserProperty(name.rawValue)
    }

    static func clearUserProperty(_ name: String) {
        Mixpanel.mainInstance().unregisterSuperProperty(name)
        Mixpanel.mainInstance().people.unset(properties: [name])
    }

    static func clearUserProperties(_ names: [String]?) {
        if let names {
            for name in names {
                clearUserProperty(name)
            }
        } else {
            Mixpanel.mainInstance().clearSuperProperties()
        }
    }

    static let platform: Platform = .mixPanel
}
