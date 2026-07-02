import Foundation
import STAREvents

extension STAREvents {
    static func sendCustomEvents(
        event: STAREvents.IAPManager_Custom,
        param: [STAREvents.IAPManager_Custom.Parameter: Any]? = nil
    ) {
        STAREvents.sendEvents(event: event, param: param)
    }

    enum IAPManager_Custom: String, STAREventSendable {
        public var platforms: Set<Platform> {
            IAPManager.shared.eventsPlatforms
        }

        case restoreReceiptKVO = "MissingReceiptFile"

        public var category: String {
            "Revenue"
        }

        public enum Parameter: String, FIRParameterDataType, CaseIterable {
            case subID
            case device
            case space
            case isSubscribe
            case error
            case code
            public static let properties: [Self] = Self.allCases

            public static let propertiesTypes: [Self: Any.Type] = [
                .subID: String.self,
                .device: String.self,
                .space: String.self,
                .isSubscribe: Bool.self,
                .error: String.self,
                .code: Int.self
            ]
        }
    }
}
