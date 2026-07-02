import Foundation

public enum IAPUnit: String, Sendable {
    case day
    case week
    case month
    case quarter
    case year
    case unknown = ""

    public var title: String {
        switch self {
        case .day:
            return "daily"
        case .week:
            return "weekly"
        case .month:
            return "monthly"
        case .quarter:
            return "quarterly"
        case .year:
            return "yearly"
        case .unknown:
            return ""
        }
    }
}

public protocol IAPProduct: Sendable {
    var productId: String { get }
    var price: Decimal { get }
    var priceLocal: String? { get }
    var unit: IAPUnit { get }
    var numberOfUnits: Int { get }
    var currencyCode: String? { get }
    var currencySymbol: String? { get }
    var freeUnit: IAPUnit { get }
    var freePrice: Decimal { get }
    var numberOfFreeUnits: Int { get }

    var introDiscountUnit: IAPUnit? { get }
    var numberOfIntroDiscountUnits: Int? { get }
    var introDiscountPrice: Decimal? { get }
    var introDiscountPriceString: String? { get }

    var priceFormat: NumberFormatter? { get }
}

extension IAPProduct {
    /// 获取平均价格带货币符
    public func getAveragePrice(divide denominator: Float) -> String {
        let totalPriceStr = priceLocal
        let currencySymble = currencySymbol ?? "$"
        let value = (price as NSDecimalNumber).floatValue
        let perPrice = floor(value / denominator * 100.0) / 100.0

        if let fmt = priceFormat,
           let res = fmt.string(from: .init(floatLiteral: Double(perPrice))) {
            return res
        }

        if totalPriceStr?.hasSuffix(currencySymble) == true {
            return String(format: "%.2f%@", perPrice, currencySymble)
        } else {
            return String(format: "%@%.2f", currencySymble, perPrice)
        }
    }

    /// 返回价格的浮点数值
    public var doublePriceValue: Double {
        (price as NSDecimalNumber).doubleValue
    }

    /// 返回产品的免费试用天数
    public var freeTrailDays: Int {
        let count: Int
        switch freeUnit {
        case .unknown: count = 0
        case .day: count = 1
        case .week: count = 7
        case .month: count = 30
        case .quarter: count = 90
        case .year: count = 365
        }
        return numberOfFreeUnits * count
    }
}

public typealias IapUnit = IAPUnit
public typealias IapProduct = IAPProduct
