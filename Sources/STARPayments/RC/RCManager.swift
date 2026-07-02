import AdSupport
import AppTrackingTransparency
import Foundation
import RevenueCat
import StoreKit

typealias RCErrorBlock = @Sendable (_ error: Error?) -> Void
typealias RCResultBlock = @Sendable (_ result: RC.PurchaseResult) -> Void

typealias RC = RCManager

final class RCManager: NSObject, @unchecked Sendable {
    static let shared = RCManager()

    /// 最近一次订阅过期的时间
    private var latestExpireDate: Date?

    // 从offerings中获取到的所有订阅类型的数组
    private var packages = [Package]()

    // 是否是沙盒测试
    public var isSandbox = false

    // 是否自动续订
    public var isRenew: Bool {
        UserDefaults.standard.bool(forKey: PurchasInfo.isRenew.rawValue)
    }

    // 是否处于订阅试用期
    public var isTrial: Bool {
        UserDefaults.standard.bool(forKey: PurchasInfo.isTrial.rawValue)
    }

    // 是否处于订阅有效期
    public var isActive: Bool {
        UserDefaults.standard.bool(forKey: PurchasInfo.isActive.rawValue)
    }

    private var apiKey = ""
    private var identify = ""
    private var stripe_identify: String?

    private var isInitialized = false

    private var offeringPackgesDict: [String: [Package]] = [:]

    private var offerings: Offerings?

    override init() {
        super.init()
    }

    public func login(uid: String, completion: ((Bool) -> Void)?) {
        let oldSid = Purchases.shared.appUserID

        Purchases.shared.logIn(uid) { [weak self] info, suc, error in
            Purchases.shared.syncPurchases { synInfo, synErr in
                self?.updatePurchaseInfo(synInfo, false)
            }

            completion?(oldSid != Purchases.shared.appUserID)
        }
    }

    public func logout(completion: ((Bool) -> Void)?) {
        let oldSid = Purchases.shared.appUserID

        Purchases.shared.logOut { [weak self] info, error in
            self?.updatePurchaseInfo(info, false)

            completion?(oldSid != Purchases.shared.appUserID)
        }
    }
}

extension RCManager {
    public struct AccessInfo {
        /// RevenueCat控制台配置的授权标志符
        public var identify: String = "" // "premium_access"
        /// RevenueCat控制台配置的stripe Entitlement标志符
        public var stripe_identify: String? // "stripe_subscription"
        /// RevenueCat控制台配置的 publickKey
        public var publicKey: String = "" // "<revenuecat_public_key>"
        /// RevenueCat初始化 userId
        public var userID: String?
    }
}

extension RCManager {
    public enum NotiType: String {
        /// 开始试用
        case trialStarted
        /// 手动二次订阅（不包含自动续订）
        case subscriptionRenewed
        /// 试用转化会员
        case subscriptionConverted
        /// 订阅状态改变
        case needUpdatePurchaseState
        /// 交易完成
        case purchaseCompleted
        /// 首次
        case initialPurchase
    }

    enum PurchasInfo: String {
        /// 是否已经同步过订阅状态
//        case syncPurchases = "syncPurchases"

        /// 是否自动续订
        case isRenew
        /// 是否处于订阅试用期
        case isTrial
        /// 是否处于订阅有效期
        case isActive
        /// 免费使用期结束标志符
        case freeEndDate_Key = "FreeEndDate_Key"

        /// 是否已经标记过开始试用
        case isMarkTrial
        /// 是否已经标记过转化会员
        case isMarkConvert
    }
}

extension RCManager {
    /// 优先级最高的基础配置，初始化时必须优先调用
    public func buildConfig(
        block: (_ acInfo: inout AccessInfo) -> Void,
        completion: RCErrorBlock? = nil
    ) {
        #if DEBUG
            Purchases.logLevel = .debug
        #endif
        var info = AccessInfo()
        block(&info)
        Purchases.configure(withAPIKey: info.publicKey, appUserID: info.userID)
        Purchases.shared.delegate = self
        apiKey = info.publicKey
        identify = info.identify
        stripe_identify = info.stripe_identify

        syncPurchases(completionBlock: completion)

        isInitialized = true

        enableRevenueCatIDFA()
    }

    /// 开启RC的 idfa
    private func enableRevenueCatIDFA() {
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { status in
                    // 不管最终授权状态如何，直接设置属性
                    Purchases.shared.attribution.setAttributes([
                        "$idfa": ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    ])
                    if #available(iOS 14.3, *) {
                        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
                    } else {
                        // Fallback on earlier versions
                    }
                    Purchases.shared.attribution.collectDeviceIdentifiers()
                }
            } else {
                // 不管最终授权状态如何，直接设置属性
                Purchases.shared.attribution.setAttributes([
                    "$idfa": ASIdentifierManager.shared().advertisingIdentifier.uuidString
                ])
                if #available(iOS 14.3, *) {
                    Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
                } else {
                    // Fallback on earlier versions
                }
                Purchases.shared.attribution.collectDeviceIdentifiers()
            }
        } else {
            Purchases.shared.attribution.setAttributes([
                "$idfa": ASIdentifierManager.shared().advertisingIdentifier.uuidString
            ])
            Purchases.shared.attribution.collectDeviceIdentifiers()
        }
    }

    /// 启动app时同步订阅状态
    private func syncPurchases(completionBlock completion: RCErrorBlock? = nil) {
        let synKey = "RC.Syn." + apiKey
        if UserDefaults.standard.bool(forKey: synKey) {
            getOfferings(completionBlock: completion)
        } else {
            Purchases.shared.syncPurchases { [weak self] purchaserInfo, error in
                if error == nil {
                    UserDefaults.standard.set(true, forKey: synKey)
                    UserDefaults.standard.synchronize()

                    self?.getOfferings(completionBlock: completion)
                } else {
                    completion?(error)
                }
            }
        }
    }

    /// 获取Offerings，得到订阅类型等信息
    private func getOfferings(completionBlock completion: RCErrorBlock? = nil) {
        guard Purchases.isConfigured else {
            let publicError = PublicError(domain: ErrorCode.errorDomain, code: (ErrorCode(rawValue: 23) as? NSError)?.code ?? 0, userInfo: nil)
            completion?(publicError)
            return
        }

        Purchases.shared.getOfferings { [weak self] offerings, error in
            guard let self else { return }

            self.offerings = offerings
            offerings?.all.values.forEach { offering in
                self.packages.append(contentsOf: offering.availablePackages)

                self.offeringPackgesDict[offering.identifier] = offering.availablePackages
            }

            if error == nil {
                updatePurchaseInfo()
            }

            completion?(error)
        }
    }

    /// 购买操作
    public func makePurchase(package: Package, completion: RCResultBlock?) {
        let expDate = latestExpireDate

        Purchases.shared.purchase(package: package) { [weak self] transaction, purchaserInfo, error, userCancelled in
            guard let self else {
                let result = PurchaseResult(isBuySucess: false, isActive: false, error: PublicError(domain: ErrorCode.errorDomain, code: (ErrorCode(rawValue: 0) as? NSError)?.code ?? 0, userInfo: nil), userCancel: true, firstDate: purchaserInfo?.firstSeen)
                completion?(result)
                return
            }

            if userCancelled {
                let result = PurchaseResult(isBuySucess: false, isActive: false, error: nil, userCancel: true, firstDate: purchaserInfo?.firstSeen)
                completion?(result)
                return
            }

            updatePurchaseInfo(purchaserInfo, true)

            if let limitDate = expDate, // 在本次订阅之前的过期时间（即有订阅）
               let entitlement = purchaserInfo?.entitlements[identify],
               entitlement.isActive, // 本次订阅成功
               let curPurchaseDate = purchaserInfo?.purchaseDate(forEntitlement: entitlement.identifier), // 本次订阅的最近的购买时间
               limitDate < curPurchaseDate {
                NotificationCenter.send(.subscriptionRenewed, nil, ["product_id": entitlement.productIdentifier.components(separatedBy: ".").last ?? ""])
            }

            let activeState = purchaserInfo?.entitlements[identify]?.isActive

            if activeState == true {
                var initPurchase = false
                if let s2 = transaction?.sk2Transaction {
                    let orid = String(s2.originalID)
                    let transId = transaction?.transactionIdentifier
                    if orid == transId {
                        initPurchase = true
                    }
                }
                if initPurchase {
                    NotificationCenter.send(
                        .initialPurchase,
                        nil,
                        ["product_id": transaction?.productIdentifier.components(separatedBy: ".").last ?? ""]
                    )
                }

                if let ent = purchaserInfo?.entitlements[identify],
                   ent.periodType == .trial,
                   UserDefaults.standard.bool(forKey: PurchasInfo.isMarkTrial.rawValue) == false {
                    UserDefaults.standard.set(true, forKey: PurchasInfo.isMarkTrial.rawValue)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.send(.trialStarted, nil, [
                        "product_id": ent.productIdentifier.components(separatedBy: ".").last ?? "",
                        "activated_time": "\(ent.latestPurchaseDate?.timeIntervalSince1970 ?? 0)",
                        "expired_time": "\(ent.expirationDate?.timeIntervalSince1970 ?? 0)",
                        "transaction_id": transaction?.transactionIdentifier ?? "",
                        "sub_id": purchaserInfo?.originalAppUserId ?? ""
                    ])
                }

                var result = PurchaseResult(isBuySucess: true, isActive: true, error: nil, userCancel: false, firstDate: purchaserInfo?.firstSeen)
                result.transactionIdentifier = transaction?.transactionIdentifier
                result.transaction = transaction
                NotificationCenter.send(.purchaseCompleted, transaction)
                completion?(result)
                return
            }

            let result = PurchaseResult(isBuySucess: false, isActive: false, error: error, userCancel: false, firstDate: purchaserInfo?.firstSeen)
            completion?(result)
        }
    }

    /// 恢复购买
    public func doRestore(completion: RCResultBlock?) {
        guard isInitialized else {
            let result = PurchaseResult(isBuySucess: false, isActive: false, error: PublicError(domain: ErrorCode.errorDomain, code: (ErrorCode(rawValue: 23) as? NSError)?.code ?? 0, userInfo: nil), userCancel: false, firstDate: nil)
            completion?(result)
            return
        }

        Purchases.shared.restorePurchases { [weak self] purchaserInfo, error in
            guard let self else {
                let result = PurchaseResult(isBuySucess: false, isActive: false, error: error, userCancel: false, firstDate: nil)
                completion?(result)
                return
            }

            if error == nil {
                if let entitlement = purchaserInfo?.entitlements {
                    parseEntitlement(entitlements: entitlement, subID: purchaserInfo?.originalAppUserId)
                }

                let result = PurchaseResult(isBuySucess: isActive, isActive: isActive, error: error, userCancel: false, firstDate: nil)
                completion?(result)
                return
            }

            let result = PurchaseResult(isBuySucess: false, isActive: false, error: error, userCancel: false, firstDate: nil)
            completion?(result)
        }
    }

    private func updatePurchaseInfo(_ customInfo: CustomerInfo? = nil, _ canSendEventsNoti: Bool = true) {
        if let info = customInfo {
            latestExpireDate = info.latestExpirationDate
            parseEntitlement(entitlements: info.entitlements, subID: info.originalAppUserId, canSendEventsNoti)
        } else {
            Purchases.shared.getCustomerInfo(fetchPolicy: .fromCacheOnly) { [weak self] customerInfo, error in
                guard let self else { return }
                latestExpireDate = customerInfo?.latestExpirationDate
                if let entitlement = customerInfo?.entitlements {
                    parseEntitlement(entitlements: entitlement, subID: customerInfo?.originalAppUserId, canSendEventsNoti)
                }
            }
        }
    }

    private func parseEntitlement(entitlements: EntitlementInfos, subID: String?, _ canSendEventsNoti: Bool = true) {
        // 是否从试用期转化为正式会员
        func isTrialConvert(_ ent: EntitlementInfo) -> Bool {
            if let freeEndDate = UserDefaults.standard.object(forKey: PurchasInfo.freeEndDate_Key.rawValue) as? Date,
               let lastPurchaseDate = ent.latestPurchaseDate {
                if isActive, lastPurchaseDate >= freeEndDate {
                    return true
                }
            }
            return false
        }

        if entitlements.all.isEmpty {
            UserDefaults.standard.set(false, forKey: PurchasInfo.isActive.rawValue)
            UserDefaults.standard.synchronize()
            NotificationCenter.send(.needUpdatePurchaseState)
            return
        }

        if let entitlement = entitlements[identify] {
            UserDefaults.standard.set(entitlement.periodType == .trial, forKey: PurchasInfo.isTrial.rawValue)
            if entitlement.periodType == .trial, let endDate = entitlement.expirationDate {
                UserDefaults.standard.set(endDate, forKey: PurchasInfo.freeEndDate_Key.rawValue)
            }
            UserDefaults.standard.set(entitlement.isActive, forKey: PurchasInfo.isActive.rawValue)
            UserDefaults.standard.set(entitlement.willRenew, forKey: PurchasInfo.isRenew.rawValue)
            UserDefaults.standard.synchronize()
            NotificationCenter.send(.needUpdatePurchaseState)

            if canSendEventsNoti {
                if isTrialConvert(entitlement) {
                    if UserDefaults.standard.bool(forKey: PurchasInfo.isMarkConvert.rawValue) == false {
                        UserDefaults.standard.set(true, forKey: PurchasInfo.isMarkConvert.rawValue)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.send(.subscriptionConverted, nil, [
                            "product_id": entitlement.productIdentifier,
                            "sub_id": subID ?? ""
                        ])
                    }
                }
            }
        } else {
            UserDefaults.standard.set(false, forKey: PurchasInfo.isActive.rawValue)
            NotificationCenter.send(.needUpdatePurchaseState)
        }

        if let key = stripe_identify,
           let entitlement = entitlements[key],
           isActive == false {
            UserDefaults.standard.set(entitlement.isActive, forKey: PurchasInfo.isActive.rawValue)
            NotificationCenter.send(.needUpdatePurchaseState)
        }
    }
}

extension RCManager: PurchasesDelegate {
    public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updatePurchaseInfo(nil, !packages.isEmpty)
    }

    public func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
        startPurchase { [weak self] transaction, purchaserInfo, error, userCancelled in
            guard let self else { return }
            let activeState = purchaserInfo?.entitlements[identify]?.isActive

            if activeState == true {
                // showToast(text: "Buy finish")
                return
            }

            if userCancelled { return }

            // if let errorText = error?.localizedDescription {
            //    showToast(text: "Buy error:\(errorText)")
            // }
        }
    }
}

extension NotificationCenter {
    fileprivate static func send(_ type: RCManager.NotiType, _ object: Any? = nil, _ userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: NSNotification.Name(type.rawValue), object: object, userInfo: userInfo)
    }
}

extension RCManager {
    /// 交易结果
    public struct PurchaseResult {
        public var isBuySucess: Bool /// 购买操作是否执行成功；
        public var isActive: Bool /// 是否处于订阅有效期；
        public var error: PublicError? /// 购买过程中出现的错误；
        public var userCancel: Bool /// 是否是用户手动取消购买操作；
        public var firstDate: Date? /// 用户第一次使用RevenueCat的日期

        /// 购买成功的交易id
        public var transactionIdentifier: String?
        /// 购买成功的交易
        public var transaction: StoreTransaction?

        public init(isBuySucess: Bool, isActive: Bool, error: PublicError? = nil, userCancel: Bool, firstDate: Date? = nil) {
            self.isBuySucess = isBuySucess
            self.isActive = isActive
            self.error = error
            self.userCancel = userCancel
            self.firstDate = firstDate
        }
    }
}
