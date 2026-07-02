import Foundation
import STAREvents

extension IAPManager {
    @objc
    func sendSubscriptionRenewedEvent(_ notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            if let productID = dict["product_id"] as? String {
                sendSubscriptionEvent(productID: productID, eventsType: .subscription_renewed)
            }
        }
    }

    @objc
    func TrialStarted(_ notification: Notification) {
        trialInfo = .init(noti: notification)
    }

    @objc
    func sendSubscriptionConvertedEvent(_ notification: Notification) {
        if let dict = notification.userInfo,
           let productID = dict["product_id"] as? String,
           let sub_id = dict["sub_id"] as? String {
            sendTrialConvertEvent(product_id: productID, sub_id: sub_id)
        }
    }

    /// 发送trialStarted事件
    func sendTrialStartedEvent(
        _ param: SubscriptionTrial,
        designId: String,
        paywallSource: IAPManager.PaywallSource?,
        paywallType: IAPManager.PaywallType?
    ) {
        let eventModel = IAPManager.EventRevenueModel(
            paywallSource: paywallSource,
            paywallType: paywallType,
            productIDs: [param.product_id],
            designId: designId
        )
        let dict = param.appendTrail(param: eventModel).revenueEventParams
        STAREvents.sendRevenueEvents(event: .trial_started, param: dict)
        STAREvents.setIAPUserProperty(name: .trial_from, value: dict[.paywall_source])
        if paywallSource == .onboarding {
            STAREvents.sendRevenueEvents(event: .ob_paywall_trialed, param: dict)
        } else if paywallSource == .banner {
            STAREvents.sendRevenueEvents(event: .banner_trial, param: [.product_id: [param.product_id], .design_id: designId])
        }
        trialInfo = nil
    }

    /// 发送trialConvert事件
    func sendTrialConvertEvent(product_id: String, sub_id: String) {
        guard let pid = product_id.components(separatedBy: ".").last else {
            return
        }
        STAREvents.sendRevenueEvents(event: .subscription_converted, param: [
            .product_id: [pid],
            .sub_id: sub_id
        ])
    }
}

extension NotificationCenter {
    static func add(
        observer: Any,
        selector: Selector,
        noti: any IAPNotification
    ) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .init(noti.rawValue), object: nil)
    }
}
