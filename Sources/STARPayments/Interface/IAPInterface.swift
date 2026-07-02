import Foundation

public typealias IAPPurchaseBlock = @Sendable (_ result: IAPPurchaseResult) -> Void

/// 内购SDK必须实现的协议
public protocol IAPManagerInterface {
    /// 返回内购SDK的实例
    static var instance: IAPManagerInterface { get }

    /// 内购SDK必须要有的几个通知
    static var iapNotificationType: any IAPNotification.Type { get }

    /// 是否自动续订
    var isRenew: Bool { get }

    /// 是否处于订阅试用期
    var isTrial: Bool { get }

    /// 是否处于订阅有效期
    var isActive: Bool { get }

    /// 用户的订阅平台ID
    var iapSubID: String? { get }

    /// 登录
    func login(uid: String, completion: (@Sendable (Bool) -> Void)?)

    /// 登出
    func logout(completion: (@Sendable (Bool) -> Void)?)

    /// 初始化
    func iapInitialize(configParams: IAPConfiguration, completion: (@Sendable (Error?) -> Void)?)
    /// 购买方法
    func purchase(product: IAPProduct, buyHandle: IAPPurchaseBlock?)

    /// 恢复方法
    func restore(handle: IAPPurchaseBlock?)
    /// 获取指定placement的[offer/paywall]
    func getOfferingOrPaywall(
        placementID: String,
        completion: (@Sendable (IAPOfferOrPaywall?) -> Void)?
    )

    /// 属性归因设置
    func setAttribution(_ name: IAPAttribution, value: String?)

    /// 返回对应订阅级别是否激活
    func isActive(for accessLevel: String) -> Bool

    /// 获取对应的product是否还有优惠资格
    func checkEligibility(
        for product: IAPProduct,
        completion: (@Sendable (Bool) -> Void)?
    )
}
