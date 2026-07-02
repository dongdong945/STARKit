import Foundation
import UIKit

public typealias IAPConfigInit = IAPConfiguration

/// IAPManager 初始化需要的配置
public protocol IAPConfiguration {
    /// 项目所有的placement
    var iapPlacements: [String] { set get }

    /// 各个平台配置的apiKey
    var iapPublicKey: String { set get }

    /// RC 后台配置的 Entitlement
    var iapIdentify: String { set get }

    /// RC 集成 Stripe 后针对 Web 端配置的 Entitlement
    var iapWebIdentify: String? { set get }

    /// 指定IAP的用户id
    var iapUserID: String? { set get }
}
