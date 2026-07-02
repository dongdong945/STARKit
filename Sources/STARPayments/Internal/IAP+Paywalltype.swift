import Foundation

extension IAPManager {
    /// 弹出Paywall的页面类型
    public enum PaywallType: Equatable, Sendable {
        case onboarding
        case dedicate
        case standard

        case other(name: String)

        var type: String {
            switch self {
            case .onboarding: return "onboarding"
            case .dedicate: return "dedicated"
            case .standard: return "standard"
            case .other(let name): return name
            }
        }
    }
}
