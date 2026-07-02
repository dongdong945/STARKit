import Foundation
import STAREvents
import StoreKit

public final class IAPManager: @unchecked Sendable {
    #if DEBUG
        // 开发时是否直接设置为会员，默认非会员
        public var debugCloseIap = false
    #endif

    private nonisolated(unsafe) static var SDKPlatform: IAPPurchaseSDK = .empty
    /// 是否已经初始化配置
    private nonisolated(unsafe) static var isInitialized = false

    /// 接收到TrialStarted通知
    var trialInfo: SubscriptionTrial?

    private nonisolated(unsafe) static var singleInstance = IAPManager()

    public static var shared: IAPManager {
        assert(isInitialized, "没有初始化")
        return singleInstance
    }

    /// 获取通知
    public static var notificationCenter: any IAPNotification.Type {
        SDKPlatform.sdk.iapNotificationType
    }

    // 是否自动续订
    public var isRenew: Bool {
        purchaseWrapper.isRenew
    }

    // 是否处于订阅试用期
    public var isTrial: Bool {
        purchaseWrapper.isTrial
    }

    // 是否处于订阅有效期
    public var isActive: Bool {
        #if DEBUG
            return debugCloseIap ? true : purchaseWrapper.isActive
        #else
            return purchaseWrapper.isActive
        #endif
    }

    /// 用户的订阅平台ID
    public var iapSubID: String? {
        purchaseWrapper.iapSubID
    }

    /// IAPManager SDK 初始化配置参数
    private(set) var iapSDKParams: any IAPConfigInit = IAPManagerConfig()
    /// 监听网络状态变化后再次缓存配置
    private var hasReloaded: NetworkDetection.ListenerIdentifier?

    /// 老版本用户第一次配置revenue cat瞬间的订阅状态
    private var lastActiveState = false

    /// 发送的事件平台
    private(set) var eventsPlatforms: Set<Platform> = []

    private lazy var purchaseWrapper = Self.SDKPlatform.platform

    private var offerMap = [String: IAPOfferOrPaywall]()

    private var productsMap = [String: [IAPProduct]]()

    private init() {
        let T = Self.notificationCenter
        NotificationCenter.add(observer: self, selector: #selector(TrialStarted), noti: T.trialStarted)
        NotificationCenter.add(observer: self, selector: #selector(sendSubscriptionRenewedEvent), noti: T.subscriptionRenewed)
        NotificationCenter.add(observer: self, selector: #selector(sendSubscriptionConvertedEvent), noti: T.subscriptionConverted)
    }

    /// 优先级最高的基础配置，初始化时必须优先调用
    public static func config(
        sdk: IAPPurchaseSDK,
        platforms: Set<Platform> = [.mixPanel],
        param: (_ iapConfig: inout IAPConfigInit) -> Void,
        completion: (@Sendable (Error?) -> Void)? = nil,
        lastSubscribeState: Bool = false
    ) {
        SDKPlatform = sdk
        isInitialized = !sdk.isEmpty
        assert(!sdk.isEmpty, "没有指定有效的内购平台")

        let iap = IAPManager.shared
        iap.eventsPlatforms = platforms
        iap.lastActiveState = lastSubscribeState

        param(&iap.iapSDKParams)

        assert(iap.iapSDKParams.iapPlacements.count > 0, "iapPlacements为空")
        assert(iap.iapSDKParams.iapPublicKey.count > 0, "apiPublicKey没有配置")
        assert(iap.iapSDKParams.iapIdentify.count > 0, "Entitlement没有配置")
        iap.purchaseWrapper.iapInitialize(configParams: iap.iapSDKParams) { err in
            completion?(err)
            iap.prepareCache()
        }
    }
}

extension IAPManager {
    /// 执行购买
    public func purchase(
        designId: String,
        paywallSource: PaywallSource,
        paywallType: PaywallType,
        productID: String,
        buyHandle: IAPPurchaseBlock? = nil
    ) {
        guard Self.isInitialized else {
            let result = IAPInternalError(.configurationError).result
            buyHandle?(result)
            return
        }

        sendPaywallTrigerEvent(
            designId: designId,
            productIDs: [productID],
            paywallSource: paywallSource,
            paywallType: paywallType,
            eventsType: .purchase_continued
        )
        purchase(productID: productID) { [weak self] result in
            buyHandle?(result)

            if result.isActive {
                guard let self else { return }

                sendPaywallTrigerEvent(
                    designId: designId,
                    productIDs: [productID],
                    paywallSource: paywallSource,
                    paywallType: paywallType,
                    eventsType: .purchase_completed
                )
                if let info = trialInfo {
                    sendTrialStartedEvent(info, designId: designId, paywallSource: paywallSource, paywallType: paywallType)
                }
            }
        }
    }

    /// 执行购买
    public func purchase(
        designId: String,
        paywallSource: PaywallSource,
        paywallType: PaywallType,
        product: IAPProduct,
        buyHandle: IAPPurchaseBlock? = nil
    ) {
        guard Self.isInitialized else {
            let result = IAPInternalError(.configurationError).result
            buyHandle?(result)
            return
        }

        let productID = product.productId

        sendPaywallTrigerEvent(
            designId: designId,
            productIDs: [productID],
            paywallSource: paywallSource,
            paywallType: paywallType,
            eventsType: .purchase_continued
        )

        purchaseWrapper.purchase(product: product) { [weak self] result in
            buyHandle?(result)

            if result.isBuySucess || result.isActive {
                guard let self else { return }

                sendPaywallTrigerEvent(
                    designId: designId,
                    productIDs: [productID],
                    paywallSource: paywallSource,
                    paywallType: paywallType,
                    eventsType: .purchase_completed
                )
                if let info = trialInfo {
                    sendTrialStartedEvent(info, designId: designId, paywallSource: paywallSource, paywallType: paywallType)
                }
            }
        }
    }

    /// 执行恢复购买
    public func restore(handle: IAPPurchaseBlock?) {
        guard Self.isInitialized else {
            let result = IAPInternalError(.configurationError).result
            handle?(result)
            return
        }

        purchaseWrapper.restore { [weak self] result in
            handle?(result)

            guard let self else { return }
            let sub_id = purchaseWrapper.iapSubID ?? ""
            if let error = result.error {
                var params = [STAREvents.IAPManager_Custom.Parameter: Any]()
                params[.subID] = sub_id
                params[.device] = getDevice()
                params[.space] = getSpace()
                params[.isSubscribe] = lastActiveState
                params[.error] = error.localizedDescription
                params[.code] = error.code
                STAREvents.sendCustomEvents(event: .restoreReceiptKVO, param: params)
            }
        }
    }

    public func getOfferingOrPaywall(placementID: String, completion: (@Sendable (IAPOfferOrPaywall?) -> Void)?) {
        purchaseWrapper.getOfferingOrPaywall(placementID: placementID, completion: completion)
    }

    public func login(uid: String, completion: (@Sendable (Bool) -> Void)?) {
        purchaseWrapper.login(uid: uid, completion: completion)
    }

    public func logout(completion: (@Sendable (Bool) -> Void)?) {
        purchaseWrapper.logout(completion: completion)
    }

    public func setAttribution(_ name: IAPAttribution, value: String?) {
        purchaseWrapper.setAttribution(name, value: value)
    }

    /// 以前订阅级别是通过``IAPConfiguration.iapIdentify``传入的，
    public func isActive(for accessLevel: String) -> Bool {
        #if DEBUG
            return debugCloseIap ? true : purchaseWrapper.isActive(for: accessLevel)
        #else
            purchaseWrapper.isActive(for: accessLevel)
        #endif
    }

    /// 获取对应的product是否还有优惠资格
    public func checkEligibility(
        for product: IAPProduct,
        completion: (@Sendable (Bool) -> Void)?
    ) {
        purchaseWrapper.checkEligibility(
            for: product,
            completion: completion
        )
    }
}

extension IAPManager {
    private func prepareCache() {
        let m = NetworkDetection.shared
        guard m.hasNetwork else {
            hasReloaded = m.add { [weak self] hasNetwork in
                if hasNetwork {
                    self?.reload()
                }
            }
            return
        }
        cacheAllPaywallAndProducts()
    }

    private func cacheAllPaywallAndProducts() {
        let placements = iapSDKParams.iapPlacements
        Task { @MainActor in
            var offerDict = [String: IAPOfferOrPaywall]()
            var productsDict = [String: [IAPProduct]]()
            for place in placements {
                guard let offer = await self.getOfferingOrPaywall(placementID: place) else {
                    continue
                }
                offerDict[place] = offer
                let arr = await offer.getProductList()
                productsDict[place] = arr
            }
            self.offerMap = offerDict
            self.productsMap = productsDict
        }
    }

    private func reload() {
        guard let l = hasReloaded else { return }
        cacheAllPaywallAndProducts()

        NetworkDetection.shared.remove(listener: l)
        hasReloaded = nil
    }
}

extension IAPManager: SubscriptionViewEventsProtocol {
    /// 根据 product id 购买
    fileprivate func purchase(productID: String, buyHandle: IAPPurchaseBlock?) {
        if let product = productsMap.values.flatMap(\.self).first(where: { $0.productId == productID }) {
            purchaseWrapper.purchase(product: product, buyHandle: buyHandle)
            return
        }

        let placements = iapSDKParams.iapPlacements

        Task {
            var product: IAPProduct?
            for place in placements {
                guard let paywall = await self.getOfferingOrPaywall(placementID: place) else {
                    continue
                }
                let products = await paywall.getProductList()
                if let p = products.first(where: { $0.productId == productID }) {
                    product = p
                    break
                }
            }
            if let p = product {
                purchaseWrapper.purchase(product: p, buyHandle: buyHandle)
            } else {
                DispatchQueue.main.async {
                    let result = IAPInternalError(.productNotAvailable).result
                    buyHandle?(result)
                }
            }
        }
    }

    /// 获取指定 placement的 offer或者paywall
    public func getOfferingOrPaywall(placementID: String) async -> IAPOfferOrPaywall? {
        await withCheckedContinuation { continuation in
            self.getOfferingOrPaywall(placementID: placementID) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// 购买指定产品id的异步方法
    public func purchase(
        designId: String,
        paywallSource: PaywallSource,
        paywallType: PaywallType,
        productID: String
    ) async -> IAPPurchaseResult {
        await withCheckedContinuation { continuation in
            self.purchase(designId: designId, paywallSource: paywallSource, paywallType: paywallType, productID: productID) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// 购买指定产品的异步方法
    public func purchase(
        designId: String,
        paywallSource: PaywallSource,
        paywallType: PaywallType,
        product: IAPProduct
    ) async -> IAPPurchaseResult {
        await withCheckedContinuation { continuation in
            self.purchase(designId: designId, paywallSource: paywallSource, paywallType: paywallType, product: product) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// 恢复购买的异步方法
    public func restore() async -> IAPPurchaseResult {
        await withCheckedContinuation { continuation in
            self.restore { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// 获取指定placement配置的产品列表
    public func getProducts(placementID: String) -> [IAPProduct] {
        productsMap[placementID] ?? []
    }

    /// 获取指定productID的商品
    public func getProduct(productID: String) -> IAPProduct? {
        productsMap.values.flatMap(\.self).first { $0.productId == productID }
    }

    public func setAttribution(customAttribution value: String?, key: String) {
        purchaseWrapper.setAttribution(.custom(key: key), value: value)
    }
}
