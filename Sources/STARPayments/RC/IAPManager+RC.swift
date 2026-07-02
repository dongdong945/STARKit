import Foundation
import RevenueCat

extension RC.NotiType: IAPNotification {}

extension Offering: IAPOfferOrPaywall {
    public func getProductList() async -> [IAPProduct] {
        availablePackages
    }
}

extension RC.PurchaseResult: @unchecked Sendable {}

extension RC.PurchaseResult: IAPPurchaseResult {}

extension Package: IAPProduct {
    public var priceFormat: NumberFormatter? {
        storeProduct.priceFormatter
    }

    public var productId: String {
        storeProduct.productIdentifier
    }

    public var price: Decimal {
        storeProduct.price
    }

    public var priceLocal: String? {
        storeProduct.localizedPriceString
    }

    public var unit: IAPUnit {
        guard let period = storeProduct.subscriptionPeriod else {
            return .unknown
        }
        switch period.unit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        }
    }

    public var numberOfUnits: Int {
        storeProduct.subscriptionPeriod?.value ?? 0
    }

    public var currencyCode: String? {
        storeProduct.currencyCode
    }

    public var currencySymbol: String? {
        guard let code = currencyCode,
              let symbol = NSLocale(localeIdentifier: code).displayName(forKey: .currencySymbol, value: code) else {
            return "$"
        }
        return symbol
    }

    public var freeUnit: IAPUnit {
        guard let introDiscount = storeProduct.introductoryDiscount,
              introDiscount.paymentMode == .freeTrial else {
            return .unknown
        }

        let period = introDiscount.subscriptionPeriod

        switch period.unit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        }
    }

    public var freePrice: Decimal {
        guard let introDiscount = storeProduct.introductoryDiscount,
              introDiscount.paymentMode == .freeTrial else {
            return 0
        }
        return introDiscount.price
    }

    public var numberOfFreeUnits: Int {
        guard let introDiscount = storeProduct.introductoryDiscount,
              introDiscount.paymentMode == .freeTrial else {
            return 0
        }

        return introDiscount.subscriptionPeriod.value
    }

    public var introDiscountUnit: IAPUnit? {
        guard let introDiscount = storeProduct.introductoryDiscount,
              introDiscount.type == .introductory else {
            return nil
        }

        let period = introDiscount.subscriptionPeriod

        switch period.unit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        }
    }

    public var numberOfIntroDiscountUnits: Int? {
        guard let introDiscount = storeProduct.introductoryDiscount,
              introDiscount.type == .introductory else {
            return nil
        }
        return introDiscount.subscriptionPeriod.value
    }

    public var introDiscountPrice: Decimal? {
        guard let introDiscount = storeProduct.introductoryDiscount,
              introDiscount.type == .introductory else {
            return nil
        }
        return introDiscount.price
    }

    public var introDiscountPriceString: String? {
        guard let introDiscount = storeProduct.introductoryDiscount,
              introDiscount.type == .introductory else {
            return nil
        }
        return introDiscount.localizedPriceString
    }
}

extension RCManager: IAPManagerInterface {
    public static var instance: IAPManagerInterface {
        shared
    }

    public static var iapNotificationType: any IAPNotification.Type {
        NotiType.self
    }

    public var iapSubID: String? {
        Purchases.shared.appUserID
    }

    public func iapInitialize(configParams: any IAPConfiguration, completion: (@Sendable (Error?) -> Void)?) {
        buildConfig { acInfo in
            acInfo.publicKey = configParams.iapPublicKey
            acInfo.identify = configParams.iapIdentify
            acInfo.stripe_identify = configParams.iapWebIdentify
            acInfo.userID = configParams.iapUserID
        } completion: { error in
            completion?(error)
        }
    }

    public func purchase(product: IAPProduct, buyHandle: IAPPurchaseBlock?) {
        makePurchase(package: product as! Package, completion: buyHandle)
    }

    public func restore(handle: IAPPurchaseBlock?) {
        doRestore(completion: handle)
    }

    public func getOfferingOrPaywall(placementID: String, completion: (@Sendable ((any IAPOfferOrPaywall)?) -> Void)?) {
        Purchases.shared.getOfferings { offers, error in
            let res = offers?.currentOffering(forPlacement: placementID)
            completion?(res)
        }
    }

    public func setAttribution(_ name: IAPAttribution, value: String?) {
        let att = Purchases.shared.attribution
        switch name {
        case .adjustID:
            att.setAdjustID(value)
        case .appsFlyerID:
            att.setAppsflyerID(value)
        case .fBAnonID:
            att.setFBAnonymousID(value)
        case .mpParticleID:
            att.setMparticleID(value)
        case .oneSignalID:
            att.setOnesignalID(value)
        case .oneSignalUserID:
            att.setOnesignalUserID(value)
        case .airshipChannelID:
            att.setAirshipChannelID(value)
        case .cleverTapID:
            att.setCleverTapID(value)
        case .mixpanelDistinctID:
            att.setMixpanelDistinctID(value)
        case .firebaseAppInstanceID:
            att.setFirebaseAppInstanceID(value)
        case .custom(let k):
            if let v = value {
                att.setAttributes([k: v])
            }
        }
    }

    func isActive(for accessLevel: String) -> Bool {
        Purchases.shared.cachedCustomerInfo?.entitlements[accessLevel]?.isActive ?? false
    }

    public func checkEligibility(
        for product: IAPProduct,
        completion: (@Sendable (Bool) -> Void)?
    ) {
        guard let p = product as? Package else {
            DispatchQueue.main.async {
                completion?(false)
            }
            return
        }
        Purchases.shared
            .checkTrialOrIntroDiscountEligibility(
                product: p.storeProduct
            ) { status in
                DispatchQueue.main.async {
                    completion?(status != .ineligible)
                }
            }
    }
}
