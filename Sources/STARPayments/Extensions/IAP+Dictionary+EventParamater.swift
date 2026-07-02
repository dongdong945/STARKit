import Foundation
import STAREvents

extension IAPManager {
    /// 获取events的参数
    public static func getRevenueEvent(
        params: [STAREvents.IAPManager_Revenue.Parameter] = [
            .paywall_source,
            .paywall_type,
            .product_id,
            .design_id
        ],
        model: EventRevenueModel
    ) -> [String: Any] {
        var dict: [String: Any] = [:]
        for param in params {
            switch param {
            case .paywall_source: dict[param.rawValue] = model.paywallSource?.sourceName ?? ""
            case .paywall_type: dict[param.rawValue] = model.paywallType?.type ?? ""
            case .product_id: dict[param.rawValue] = model.productIDs
            case .design_id: dict[param.rawValue] = model.designId
            default: break
            }
        }

        return dict
    }
}

extension Dictionary where Key == String {
    var revenueEventParams: [STAREvents.IAPManager_Revenue.Parameter: Any] {
        var res = [STAREvents.IAPManager_Revenue.Parameter: Any]()
        forEach { k, v in
            if let key = STAREvents.IAPManager_Revenue.Parameter(rawValue: k) {
                res[key] = v
            }
        }
        /// 给空的paywall_source指定默认值
        if let s = res[.paywall_source] as? String, s.isEmpty {
            res[.paywall_source] = "app_launch"
        }
        /// 给空的paywall_type指定默认值
        if let s = res[.paywall_type] as? String, s.isEmpty {
            res[.paywall_type] = "standard"
        }

        return res
    }
}
