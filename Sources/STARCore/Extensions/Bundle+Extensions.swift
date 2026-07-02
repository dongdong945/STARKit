import Foundation

extension Bundle {
    /// 获取应用版本号
    public var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// 获取构建版本号
    public var buildVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// 获取应用显示名称
    public var appDisplayName: String {
        infoDictionary?["CFBundleDisplayName"] as? String ??
            infoDictionary?["CFBundleName"] as? String ?? "App"
    }

    /// 获取主应用Bundle，适用于主app和extension
    public static var appBundle: Bundle {
        var bundleURL = Bundle.main.bundleURL
        while bundleURL.pathExtension != "app", bundleURL.path != "/" {
            bundleURL = bundleURL.deletingLastPathComponent()
        }
        return Bundle(url: bundleURL) ?? Bundle.main
    }
}
