import Foundation
import STAREvents

extension STAREvents {
    /// 发送Revenue事件
    public static func sendRevenueEvents(
        event: STAREvents.IAPManager_Revenue,
        param: [STAREvents.IAPManager_Revenue.Parameter: Any]? = nil
    ) {
        var dict = param
        switch event {
        case .ob_paywall_viewed,
             .ob_paywall_trialed,
             .ob_paywall_continued,
             .ob_paywall_purchased:
            dict?.removeValue(forKey: .paywall_source)
            if let v = dict?[.paywall_type] as? String,
               v == IAPManager.PaywallType.onboarding.type {
                dict?.removeValue(forKey: .paywall_type)
            }
        default:
            break
        }
        STAREvents.sendEvents(event: event, param: dict)
    }

    public enum IAPManager_Revenue: String, CaseIterable, STAREventSendable {
        public static func eventNameMapping(platform: Platform) -> [STAREvents.IAPManager_Revenue: String]? {
            if platform == .mixPanel {
                return [
                    .paywall_viewed: "Paywall Viewed",
                    .trial_started: "Paywall Trialed",
                    .purchase_completed: "Paywall Purchased",
                    .purchase_continued: "Paywall Continued",
                    .subscription_converted: "Subscription Converted",
                    .subscription_renewed: "Subscription Renewed"
                ]
            }

            return nil
        }

        public var platforms: Set<Platform> {
            switch self {
            case .paywall_closed:
                return []
            case .ob_paywall_trialed,
                 .ob_paywall_viewed,
                 .ob_paywall_continued,
                 .ob_paywall_purchased:
                return IAPManager.shared.eventsPlatforms.intersection([.mixPanel])
            default:
                return IAPManager.shared.eventsPlatforms
            }
        }

        case banner_trial

        case trial_started
        case paywall_closed
        case paywall_viewed
        case subscription_converted
        case subscription_renewed
        case purchase_completed
        case purchase_continued

        case ob_paywall_viewed = "OB Paywall Viewed"

        case ob_paywall_trialed = "OB Paywall Trialed"

        case ob_paywall_continued = "OB Paywall Continued"

        case ob_paywall_purchased = "OB Paywall Purchased"

        public var category: String {
            "Revenue"
        }

        public enum Parameter: String, FIRParameterDataType, CaseIterable {
            case paywall_source
            case paywall_type
            case product_id
            case design_id

            case activated_time
            case expired_time
            case transaction_id
            case sub_id

            public static var properties: [Self] { allCases }

            public static var propertiesTypes: [Self: Any.Type] {
                [
                    .paywall_source: String.self,
                    .design_id: String.self,
                    .paywall_type: String.self,
                    .product_id: [String].self,
                    .activated_time: String.self,
                    .expired_time: String.self,
                    .transaction_id: String.self,
                    .sub_id: String.self
                ]
            }
        }
    }
}
