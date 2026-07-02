import Foundation
import STAREvents

extension STAREvents {
    static func setIAPUserProperty(name: STAREvents.IAPManager_CommonProperty, value: Any?) {
        STAREvents.setUserProperty(name: name, value: value)
    }

    public enum IAPManager_CommonProperty: String, FIRUserPropertySendable {
        public static var propertiesTypes: [STAREvents.IAPManager_CommonProperty: Any.Type] {
            [
                .trial_from: String.self,
                .purchase_from: String.self,
                .purchaseKind: String.self
            ]
        }

        public var platforms: Set<Platform> {
            IAPManager.shared.eventsPlatforms
        }

        case trial_from
        case purchase_from
        case purchaseKind = "purchase_kind"
    }
}
