import Foundation

public struct IAPPurchaseSDK: @unchecked Sendable {
    let sdk: IAPManagerInterface.Type

    public static let empty: IAPPurchaseSDK = .init(sdk: EmptyPurchase.self)

    public static func create(_ type: IAPManagerInterface.Type) -> Self {
        .init(sdk: type)
    }

    var platform: IAPManagerInterface { sdk.instance }

    var isEmpty: Bool {
        sdk is EmptyPurchase.Type
    }
}
