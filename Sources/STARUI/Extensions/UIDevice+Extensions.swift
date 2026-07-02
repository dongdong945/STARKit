import UIKit

extension UIDevice {
    /// 模拟器机器标识符列表
    private static let simulatorMachines = ["i386", "x86_64", "arm64"]

    /// 获取设备机型标识符
    public var machine: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        var identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        if Self.simulatorMachines.contains(where: { $0 == identifier }) {
            identifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iPhone3,1"
        }

        return identifier
    }

    /// 获取设备所在国家
    public var country: String {
        // 首先尝试从当前 region 获取国家名称
        if let regionCode = Locale.current.region?.identifier,
           let countryName = Locale(identifier: "en_US").localizedString(forRegionCode: regionCode) {
            return countryName
        }

        // 降级方案：使用系统 locale 和首选语言
        let languageCode = NSLocale.preferredLanguages.first ?? "en_US"
        let countryName = (NSLocale.system as NSLocale).displayName(forKey: .identifier, value: languageCode)

        return countryName ?? "US"
    }

    /// 设备摇动通知
    public static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}
