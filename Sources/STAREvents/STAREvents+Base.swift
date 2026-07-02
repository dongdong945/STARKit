import Foundation

public protocol STAREventBaseType: Hashable {
    var category: String { get }
}

public protocol FIRParameterEnumStringType {
    var typeValue: String { get }
}

public protocol FIRParameterEnumNumberType {
    var typeValue: NSNumber { get }
}

public protocol FIRParameterDataType: Hashable, RawRepresentable where RawValue == String {
    static var properties: [Self] { get }
    static var propertiesTypes: [Self: Any.Type] { get }
}

public protocol STAREventSendable: STAREventBaseType, RawRepresentable where RawValue == String {
    associatedtype Parameter: FIRParameterDataType

    static func eventNameMapping(platform: Platform) -> [Self: String]?

    var platforms: Set<Platform> { get }
}

extension STAREventSendable {
    public static func eventNameMapping(platform: Platform) -> [Self: String]? {
        nil
    }
}

public protocol FIRUserPropertySendable: Hashable, RawRepresentable where RawValue == String {
    static var propertiesTypes: [Self: Any.Type] { get }

    var platforms: Set<Platform> { get }
}
