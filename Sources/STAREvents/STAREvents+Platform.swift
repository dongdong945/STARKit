import Foundation

public enum Platform: String, Sendable {
    case mixPanel
    case appsFlyer

    public var adapter: String {
        switch self {
        case .mixPanel:
            return "MixPanelAdapter"
        case .appsFlyer:
            return "AppsFlyerAdapter"
        }
    }

    var adapterClass: Adapter.Type? {
        switch self {
        case .mixPanel:
            return MixPanelAdapter.self
        case .appsFlyer:
            return AppsFlyerAdapter.self
        }
    }
}
