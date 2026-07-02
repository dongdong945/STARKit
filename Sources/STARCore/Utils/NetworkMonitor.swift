import Foundation
import Network

/// 网络连接类型
public enum NetworkType: Sendable {
    /// WiFi 连接
    case wifi
    /// 蜂窝网络连接
    case cellular
    /// 未知连接类型
    case unknown

    /// 网络类型的显示名称
    public var title: String {
        switch self {
        case .wifi:
            return "Wifi"
        case .cellular:
            return "Cellular"
        case .unknown:
            return "Unknown"
        }
    }
}

/// 网络监控工具
public final class NetworkMonitor: Sendable {
    /// 共享单例
    public static let shared = NetworkMonitor()

    /// 日志工具
    private let logger = AppLogger(category: "NetworkMonitor")
    /// 网络监控队列
    private let queue = DispatchQueue(label: "com.components.networkmonitor")
    /// 默认测试 URL
    private let defaultTestURL = URL(string: "https://www.google.com")!
    /// 请求超时时间（秒）
    private let requestTimeout: TimeInterval = 6

    /// 私有初始化方法（单例模式）
    private init() {}

    /// 获取网络状态信息（类型 + 延迟）
    public func getNetworkStatus() async -> String {
        // 并发执行网络类型检测和延迟测试
        async let networkType = getNetworkType()
        async let networkDuration = getNetworkLatency()

        return await "\(networkType.title): \(networkDuration)"
    }

    /// 获取当前网络类型
    public func getNetworkType() async -> NetworkType {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()

            monitor.pathUpdateHandler = { path in
                monitor.pathUpdateHandler = nil
                monitor.cancel()

                guard path.status == .satisfied else {
                    continuation.resume(returning: .unknown)
                    return
                }

                switch (path.usesInterfaceType(.wifi), path.usesInterfaceType(.cellular)) {
                case (true, _):
                    continuation.resume(returning: .wifi)
                case (_, true):
                    continuation.resume(returning: .cellular)
                default:
                    continuation.resume(returning: .unknown)
                }
            }

            monitor.start(queue: queue)
        }
    }

    /// 获取网络延迟
    public func getNetworkLatency(testURL: URL? = nil) async -> String {
        let url = testURL ?? defaultTestURL
        let startTime = Date()

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = requestTimeout

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                logger.warning("Network latency test failed: invalid response")
                return "null"
            }

            let duration = ceil(Date().timeIntervalSince(startTime) * 1000)
            return "\(Int(duration)) ms"
        } catch {
            logger.error("Network latency test failed: \(error)")
            return "null"
        }
    }
}
