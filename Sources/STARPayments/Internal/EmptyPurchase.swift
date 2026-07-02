import Foundation

final class EmptyPurchase: IAPManagerInterface {
    var iapSubID: String? { nil }

    func getProducts(placementID: String, completion: (([any IAPProduct]) -> Void)?) {}

    func getOfferingOrPaywall(placementID: String, completion: (@Sendable ((any IAPOfferOrPaywall)?) -> Void)?) {}

    func setAttribution(_ name: IAPAttribution, value: String?) {}

    enum EmptyPurchaseNotiType: String, IAPNotification {
        case trialStarted
        case subscriptionRenewed
        case subscriptionConverted
        case needUpdatePurchaseState
        case purchaseCompleted
        case initialPurchase
    }

    static var instance: IAPManagerInterface {
        EmptyPurchase()
    }

    var isRenew: Bool = false

    var isTrial: Bool = false

    var isActive: Bool = false

    func login(uid: String, completion: (@Sendable (Bool) -> Void)?) {}

    func logout(completion: (@Sendable (Bool) -> Void)?) {}

    static var iapNotificationType: any IAPNotification.Type {
        EmptyPurchaseNotiType.self
    }

    func iapInitialize(configParams: any IAPConfiguration, completion: (@Sendable ((any Error)?) -> Void)?) {}

    func purchase(productID: String, buyHandle: IAPPurchaseBlock?) {}

    func purchase(product: any IAPProduct, buyHandle: IAPPurchaseBlock?) {}

    func restore(handle: IAPPurchaseBlock?) {}

    func isActive(for accessLevel: String) -> Bool {
        false
    }

    func checkEligibility(
        for product: any IAPProduct,
        completion: (@Sendable (Bool) -> Void)?
    ) {}
}
