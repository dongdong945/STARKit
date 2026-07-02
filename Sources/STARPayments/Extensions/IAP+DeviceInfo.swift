import Foundation

extension IAPManager {
    func getDevice() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    func getSpace() -> String {
        func unitFormatter(_ bytes: Int64, _ showUnit: ByteCountFormatter.Units, _ showStyle: ByteCountFormatter.CountStyle, _ isShowUnit: Bool = false) -> String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = showUnit // 返回字符串的显示单位
            formatter.countStyle = showStyle // 返回字符串的计算单位,1000进制（file或decimal）或者1024进制（binary）
            formatter.includesUnit = isShowUnit
            return formatter.string(fromByteCount: bytes) as String
        }

        var totalSpaceInBytes: Int64 = 0
        if let space = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[FileAttributeKey.systemSize] as? Int64 {
            totalSpaceInBytes = space
        }

        var freeSpaceInBytes: Int64 = 0
        if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
            freeSpaceInBytes = space
        }

        let totalSpaceStr = unitFormatter(totalSpaceInBytes, .useMB, .decimal, true)
        let freeSpaceStr = unitFormatter(freeSpaceInBytes, .useMB, .decimal, true)

        return "free \(freeSpaceStr)" + " / " + "total \(totalSpaceStr)"
    }
}
