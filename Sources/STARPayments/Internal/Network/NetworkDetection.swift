import Foundation
import Network

final class NetworkDetection: @unchecked Sendable {
    static let shared = NetworkDetection()

    typealias Callback = @Sendable (_ hasNetwork: Bool) -> Void
    typealias ListenerIdentifier = String

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.iapmanager.network-detection")
    private var isReachable = false

    private var dict: [ListenerIdentifier: Callback] = [:]

    var hasNetwork: Bool {
        isReachable
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isReachable = path.status == .satisfied
                self?.notifyListeners()
            }
        }
        monitor.start(queue: queue)
    }

    private func notifyListeners() {
        let b = hasNetwork
        dict.values.forEach { $0(b) }
    }

    func add(listener: @escaping Callback) -> ListenerIdentifier {
        let key = UUID().uuidString
        dict[key] = listener
        return key
    }

    func remove(listener: ListenerIdentifier) {
        dict[listener] = nil
    }
}
