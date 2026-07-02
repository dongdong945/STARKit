import Foundation

public protocol IAPNotification: RawRepresentable where RawValue == String {
    /// 开始试用
    static var trialStarted: Self { get }
    /// 手动二次订阅（不包含自动续订）
    static var subscriptionRenewed: Self { get }
    /// 试用转化会员
    static var subscriptionConverted: Self { get }
    /// 交易完成
    static var needUpdatePurchaseState: Self { get }
    /// 交易完成
    static var purchaseCompleted: Self { get }
    /// 首次购买
    static var initialPurchase: Self { get }
}

/// 给IAP通知添加注册
extension IAPNotification {
    /// 添加注册通知
    private func addObserver(_ observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: .init(rawValue),
            object: nil
        )
    }

    /// 移除注册的通知
    public static func removeObserver(_ observer: Any) {
        let list = [
            trialStarted,
            subscriptionRenewed,
            subscriptionConverted,
            needUpdatePurchaseState,
            purchaseCompleted,
            initialPurchase
        ]
        list.forEach { noti in
            NotificationCenter.default.removeObserver(observer, name: .init(noti.rawValue), object: nil)
        }
    }

    /// 注册trialStarted通知
    public static func addObserver(trialStarted observer: Any, selector: Selector) {
        trialStarted.addObserver(observer, selector: selector)
    }

    /// 注册subscriptionRenewed通知
    public static func addObserver(subscriptionRenewed observer: Any, selector: Selector) {
        subscriptionRenewed.addObserver(observer, selector: selector)
    }

    /// 注册subscriptionConverted通知
    public static func addObserver(subscriptionConverted observer: Any, selector: Selector) {
        subscriptionConverted.addObserver(observer, selector: selector)
    }

    /// 注册needUpdatePurchaseState通知
    public static func addObserver(needUpdatePurchaseState observer: Any, selector: Selector) {
        needUpdatePurchaseState.addObserver(observer, selector: selector)
    }

    /// 注册purchaseCompleted通知
    public static func addObserver(purchaseCompleted observer: Any, selector: Selector) {
        purchaseCompleted.addObserver(observer, selector: selector)
    }

    /// 注册initialPurchase通知
    public static func addObserver(initialPurchase observer: Any, selector: Selector) {
        initialPurchase.addObserver(observer, selector: selector)
    }
}
