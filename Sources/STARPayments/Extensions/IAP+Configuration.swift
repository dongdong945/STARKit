import Foundation
import UIKit

extension IAPManager {
    struct IAPManagerConfig: IAPConfigInit {
        var iapPlacements: [String] = []

        var iapPublicKey: String = ""

        var iapIdentify: String = ""

        var iapWebIdentify: String?

        var iapUserID: String?
    }
}
