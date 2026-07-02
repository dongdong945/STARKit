import Foundation
import STAREvents

public protocol SubscriptionViewEventsProtocol {}

extension SubscriptionViewEventsProtocol {
    /// 发送 paywall 相关事件
    public func sendPaywallTrigerEvent(
        designId: String,
        productIDs: [String],
        paywallSource: IAPManager.PaywallSource?,
        paywallType: IAPManager.PaywallType?,
        eventsType: STAREvents.IAPManager_Revenue
    ) {
        let products = productIDs.compactMap { $0.components(separatedBy: ".").last }

        let eventModel = IAPManager.EventRevenueModel(
            paywallSource: paywallSource,
            paywallType: paywallType,
            productIDs: products,
            designId: designId
        )
        let params = IAPManager.getRevenueEvent(model: eventModel).revenueEventParams
        // TODO: 额外事件处理
        STAREvents.sendRevenueEvents(event: eventsType, param: params)
        switch eventsType {
        case .purchase_completed:
            STAREvents.setIAPUserProperty(name: .purchase_from, value: params[.paywall_source])
            STAREvents.setIAPUserProperty(name: .purchaseKind, value: params[.paywall_type])
        default:
            break
        }
        if paywallSource == .onboarding {
            switch eventsType {
            case .trial_started:
                STAREvents.sendRevenueEvents(event: .ob_paywall_trialed, param: params)
            case .paywall_viewed:
                STAREvents.sendRevenueEvents(event: .ob_paywall_viewed, param: params)
            case .purchase_completed:
                STAREvents.sendRevenueEvents(event: .ob_paywall_purchased, param: params)
            case .purchase_continued:
                STAREvents.sendRevenueEvents(event: .ob_paywall_continued, param: params)
            default:
                break
            }
        }
    }

    /// 发送 购买
    public func sendSubscriptionEvent(productID: String, eventsType: STAREvents.IAPManager_Revenue) {
        var params = [STAREvents.IAPManager_Revenue.Parameter: Any]()
        if let productIdsSuffix = productID.components(separatedBy: ".").last {
            params[.product_id] = [productIdsSuffix]
            STAREvents.sendRevenueEvents(event: eventsType, param: params)
        }
    }
}
