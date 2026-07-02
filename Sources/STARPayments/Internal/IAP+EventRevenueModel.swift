import Foundation

extension IAPManager {
    public class EventRevenueModel {
        var paywallSource: IAPManager.PaywallSource?
        var paywallType: IAPManager.PaywallType?
        var productIDs: [String] = []
        var designId = ""

        public init(paywallSource: IAPManager.PaywallSource?, paywallType: IAPManager.PaywallType?, productIDs: [String], designId: String) {
            self.paywallSource = paywallSource
            self.paywallType = paywallType
            self.productIDs = productIDs
            self.designId = designId
        }

        init() {}
    }
}
