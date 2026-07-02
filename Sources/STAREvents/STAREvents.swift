import Foundation

public enum STAREvents {
    @available(*, deprecated, message: "Use logs(platform:) instead")
    /// 获取记录的事件
    public static var eventLogs: [(name: String, param: [String: Any]?)] {
        logs(platform: .mixPanel)
    }

    /// 设置是否记录发送事件
    public static func setEnableLog(_ enable: Bool = false) {
        enableLog = enable
    }

    /// 获取记录的事件
    public static func logs(platform: Platform = .mixPanel) -> [(name: String, param: [String: Any]?)] {
        adapters[platform]?.logs.array ?? []
    }

    /// 清空记录的事件
    public static func clearLogs(platform: Platform = .mixPanel) {
        adapters[platform]?.clearLogs()
    }

    /// 设置事件回调
    public static func hookEvents(event: ((_ name: String, _ param: [String: Any]?) -> Void)?) {
        hookHandle = event
    }

    /// 发送事件
    public static func sendEvents<T: STAREventSendable>(event: T, param: [T.Parameter: Any]?, hookEnable: Bool = true) {
        for platform in event.platforms {
            register(platform)
            let adapter = adapters[platform]
            adapter?.sendEvent(event, param: param)
        }

        var paramDict: [String: Any]?
        if let param {
            var dict = [String: Any]()
            for (key, value) in param {
                dict[key.rawValue] = value
            }
            paramDict = dict
        }

        if hookEnable {
            hookHandle?(event.rawValue, paramDict)
        }
    }

    /// 发送事件
    public static func sendEvent(event: String, param: [String: Any]?, platforms: Set<Platform>, hookEnable: Bool = true) {
        for platform in platforms {
            register(platform)
            let adapter = adapters[platform]
            adapter?.sendEvent(event, param: param)
        }

        var paramDict: [String: Any]?
        if let param {
            var dict = [String: Any]()
            for (key, value) in param {
                dict[key] = value
            }
            paramDict = dict
        }

        if hookEnable {
            hookHandle?(event, paramDict)
        }
    }

    /// 设置用户属性
    public static func setUserProperty(name: some FIRUserPropertySendable, value: Any? = nil) {
        for platform in name.platforms {
            register(platform)
            let adapter = adapters[platform]
            adapter?.setUserProperty(name, value: value)
        }
    }

    /// 设置用户属性
    public static func setUserProperty(name: String, value: Any?, platforms: Set<Platform>) {
        for platform in platforms {
            register(platform)
            let adapter = adapters[platform]
            adapter?.setUserProperty(name, value: value)
        }
    }

    /// 设置用户属性
    public static func setUserProperties(_ userProperties: [String: Any?], platforms: Set<Platform>) {
        for platform in platforms {
            register(platform)
            let adapter = adapters[platform]
            adapter?.setUserProperties(userProperties)
        }
    }

    /// 设置用户属性（用户生命周期内只生效一次）
    public static func setUserPropertyOnce(name: String, value: Any?, platforms: Set<Platform>) {
        for platform in platforms {
            register(platform)
            let adapter = adapters[platform]
            adapter?.setUserPropertyOnce(name, value: value)
        }
    }

    /// 设置用户属性（用户生命周期内只生效一次）
    public static func setUserPropertiesOnce(_ userProperties: [String: Any?], platforms: Set<Platform>) {
        for platform in platforms {
            register(platform)
            let adapter = adapters[platform]
            adapter?.setUserPropertiesOnce(userProperties)
        }
    }

    /// 清空用户属性
    public static func clearUserProperty(name: some FIRUserPropertySendable) {
        for platform in name.platforms {
            register(platform)
            let adapter = adapters[platform]
            adapter?.clearUserProperty(name)
        }
    }

    /// 清空用户属性
    public static func clearUserProperty(name: String, platforms: Set<Platform>) {
        for platform in platforms {
            let adapter = adapters[platform]
            adapter?.clearUserProperty(name)
        }
    }

    /// 清空用户属性，如果names为nil，则清空用户所有属性
    public static func clearUserProperties(_ names: [String]? = nil, platforms: Set<Platform>) {
        for platform in platforms {
            let adapter = adapters[platform]
            adapter?.clearUserProperties(names)
        }
    }

    /// 是否记录发送事件
    private nonisolated(unsafe) static var enableLog = false {
        didSet {
            for (_, adapter) in adapters {
                adapter.enableLog = enableLog
            }
        }
    }

    /// 缓存的Adapter
    private nonisolated(unsafe) static var adapters = ThreadSafeDictionary<Platform, Adapter.Type>()

    /// 事件回调（不会对数据进行任何处理）
    private nonisolated(unsafe) static var hookHandle: ((_ name: String, _ param: [String: Any]?) -> Void)?

    /// 注册Adapter
    private static func register(_ platform: Platform) {
        guard !adapters.keys.contains(platform) else { return }

        guard let adapter = platform.adapterClass else {
            assertionFailure("\(platform.adapter)未引入")
            return
        }
        adapter.enableLog = enableLog
        adapters[platform] = adapter
    }
}

extension STAREvents {
    public struct EnumType {}
    public struct UserProperty {}
}
