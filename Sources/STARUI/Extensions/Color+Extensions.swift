import SwiftUI

extension Color {
    /// 从十六进制字符串创建颜色
    public init(_ hexString: String) {
        var hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let r, g, b, a: Double
        switch hexString.count {
        case 6: // RGB (不含透明度)
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            a = 1.0
        case 8: // RGBA
            r = Double((rgbValue & 0xFF00_0000) >> 24) / 255.0
            g = Double((rgbValue & 0x00FF_0000) >> 16) / 255.0
            b = Double((rgbValue & 0x0000_FF00) >> 8) / 255.0
            a = Double(rgbValue & 0x0000_00FF) / 255.0
        default:
            r = 0
            g = 0
            b = 0
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
