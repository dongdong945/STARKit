import Foundation

public protocol IAPOfferOrPaywall: Sendable {
    func getProductList() async -> [IAPProduct]
}
