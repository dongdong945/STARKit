import Foundation

public struct SubscriptionTrial {
    let product_id: String
    let activated_time: String
    let expired_time: String
    let transaction_id: String
    let sub_id: String

    init?(noti: Notification) {
        guard let info = noti.userInfo,
              let p1 = info["product_id"] as? String,
              let p2 = info["activated_time"] as? String,
              let p3 = info["expired_time"] as? String,
              let p4 = info["transaction_id"] as? String,
              let p5 = info["sub_id"] as? String else {
            return nil
        }
        product_id = p1
        activated_time = p2
        expired_time = p3
        transaction_id = p4
        sub_id = p5
    }

    func appendTrail(param: IAPManager.EventRevenueModel) -> [String: Any] {
        var dict = IAPManager.getRevenueEvent(model: param)
        dict["activated_time"] = activated_time
        dict["expired_time"] = expired_time
        dict["transaction_id"] = transaction_id
        dict["sub_id"] = sub_id
        return dict
    }
}
