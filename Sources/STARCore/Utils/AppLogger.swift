import Foundation
import OSLog

/// 日志级别
public enum AppLogType: String, CaseIterable, Sendable, Identifiable {
    case info
    case warning
    case debug
    case error
    case critical

    public var id: String {
        rawValue
    }
}

/// 应用日志条目
public struct AppLogEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let subsystem: String
    public let category: String
    public let type: AppLogType
    public let message: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        subsystem: String,
        category: String,
        type: AppLogType,
        message: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.subsystem = subsystem
        self.category = category
        self.type = type
        self.message = message
    }

    /// 简短消息，用于列表展示
    public var shortMessage: String {
        let limit = 120
        guard message.count > limit else { return message }
        let index = message.index(message.startIndex, offsetBy: limit)
        return String(message[..<index]) + "..."
    }
}

extension Notification.Name {
    /// 日志变化通知
    public static let appLoggerLogsDidChange = Notification.Name("components.appLogger.logsDidChange")
}

/// 日志存储中心
private final class AppLoggerStore: @unchecked Sendable {
    static let shared = AppLoggerStore()
    private static let fileLoggingEnabledDefaultsKey = "components.appLogger.fileLoggingEnabled"

    private let lock = NSLock()
    private let fileWriteQueue = DispatchQueue(label: "components.applogger.filewriter")

    private var logs: [AppLogEntry] = []
    private var isEnabled: Bool = true
    private var isFileLoggingEnabled: Bool = false
    private var fileURL: URL?

    private init() {
        isFileLoggingEnabled = UserDefaults.standard.bool(forKey: Self.fileLoggingEnabledDefaultsKey)

        if isFileLoggingEnabled, ensureFileURL() == nil {
            isFileLoggingEnabled = false
            persistFileLoggingEnabled(false)
        }
    }

    var loggingEnabled: Bool {
        lock.withLock {
            isEnabled
        }
    }

    func setLoggingEnabled(_ enabled: Bool) {
        lock.withLock {
            isEnabled = enabled
        }
    }

    var fileLoggingEnabled: Bool {
        lock.withLock {
            isFileLoggingEnabled
        }
    }

    func setFileLoggingEnabled(_ enabled: Bool) {
        lock.withLock {
            isFileLoggingEnabled = enabled
        }

        guard enabled else {
            persistFileLoggingEnabled(false)
            return
        }

        if ensureFileURL() == nil {
            lock.withLock {
                isFileLoggingEnabled = false
            }
            persistFileLoggingEnabled(false)
            return
        }

        persistFileLoggingEnabled(true)
    }

    func allLogsDescending() -> [AppLogEntry] {
        lock.withLock {
            Array(logs.reversed())
        }
    }

    func removeLog(id: UUID) {
        let changed = lock.withLock {
            let oldCount = logs.count
            logs.removeAll { $0.id == id }
            return oldCount != logs.count
        }

        if changed {
            notifyLogsChanged()
        }
    }

    func removeAllLogs() {
        let hadLogs = lock.withLock {
            let hasLogs = !logs.isEmpty
            logs.removeAll(keepingCapacity: true)
            return hasLogs
        }

        if hadLogs {
            notifyLogsChanged()
        }
    }

    func currentFilePath() -> String? {
        ensureFileURL()?.path
    }

    func record(_ entry: AppLogEntry) {
        let outcome = lock.withLock { () -> (recorded: Bool, writeToFile: Bool) in
            guard isEnabled else { return (false, false) }
            logs.append(entry)
            return (true, isFileLoggingEnabled)
        }

        guard outcome.recorded else { return }

        notifyLogsChanged()

        if outcome.writeToFile {
            appendLogToFile(entry)
        }
    }

    private func notifyLogsChanged() {
        NotificationCenter.default.post(name: .appLoggerLogsDidChange, object: nil)
    }

    private func persistFileLoggingEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.fileLoggingEnabledDefaultsKey)
    }

    private func ensureFileURL() -> URL? {
        if let cachedURL = lock.withLock({ fileURL }) {
            return cachedURL
        }

        let fileManager = FileManager.default
        guard let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }

        let folderURL = cachesURL.appendingPathComponent("AppLogger", isDirectory: true)
        let logFileURL = folderURL.appendingPathComponent("app.log", isDirectory: false)

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            if !fileManager.fileExists(atPath: logFileURL.path) {
                let created = fileManager.createFile(atPath: logFileURL.path, contents: nil)
                guard created else { return nil }
            }
        } catch {
            return nil
        }

        lock.withLock {
            fileURL = logFileURL
        }

        return logFileURL
    }

    private func appendLogToFile(_ entry: AppLogEntry) {
        guard let targetURL = ensureFileURL() else { return }

        fileWriteQueue.async {
            let line = "\(entry.timestamp.ISO8601Format()) [\(entry.subsystem)] [\(entry.category)] [\(entry.type.rawValue.uppercased())] \(entry.message)\n"
            guard let data = line.data(using: .utf8) else { return }
            guard let fileHandle = FileHandle(forWritingAtPath: targetURL.path) else { return }

            defer {
                fileHandle.closeFile()
            }

            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        }
    }
}

extension NSLock {
    /// 加锁执行
    fileprivate func withLock<T>(_ action: () -> T) -> T {
        lock()
        defer { unlock() }
        return action()
    }
}

/// 应用日志工具
public final class AppLogger: Sendable {
    /// OSLog 日志实例
    private let logger: Logger

    /// 日志子系统
    private let subsystem: String

    /// 日志分类
    private let category: String

    /// 是否启用日志输出
    public static var isEnabled: Bool {
        get { AppLoggerStore.shared.loggingEnabled }
        set { AppLoggerStore.shared.setLoggingEnabled(newValue) }
    }

    /// 是否启用文件日志
    public static var isFileLoggingEnabled: Bool {
        get { AppLoggerStore.shared.fileLoggingEnabled }
        set { AppLoggerStore.shared.setFileLoggingEnabled(newValue) }
    }

    /// 初始化日志工具
    public init(subsystem: String = Bundle.main.appDisplayName, category: String) {
        self.subsystem = subsystem
        self.category = category
        logger = Logger(subsystem: subsystem, category: category)
    }

    /// 记录普通信息日志
    public func info(_ message: String) {
        write(type: .info, message: message, decoratedMessage: "ℹ️ \(message)")
    }

    /// 记录警告日志
    public func warning(_ message: String) {
        write(type: .warning, message: message, decoratedMessage: "⚠️ \(message)")
    }

    /// 记录调试日志
    public func debug(_ message: String) {
        write(type: .debug, message: message, decoratedMessage: "🐛 \(message)")
    }

    /// 记录错误日志
    public func error(_ message: String) {
        write(type: .error, message: message, decoratedMessage: "❌ \(message)")
    }

    /// 记录严重错误日志
    public func critical(_ message: String) {
        write(type: .critical, message: message, decoratedMessage: "🔥 \(message)")
    }

    /// 获取当前内存日志（时间倒序）
    public static func currentLogs() -> [AppLogEntry] {
        AppLoggerStore.shared.allLogsDescending()
    }

    /// 删除单条日志
    public static func deleteLog(id: UUID) {
        AppLoggerStore.shared.removeLog(id: id)
    }

    /// 清空日志
    public static func clearLogs() {
        AppLoggerStore.shared.removeAllLogs()
    }

    /// 获取文件日志路径
    public static func fileLogPath() -> String? {
        AppLoggerStore.shared.currentFilePath()
    }

    private func write(type: AppLogType, message: String, decoratedMessage: String) {
        guard Self.isEnabled else { return }

        switch type {
        case .info:
            logger.info("\(decoratedMessage, privacy: .public)")
        case .warning:
            logger.warning("\(decoratedMessage, privacy: .public)")
        case .debug:
            logger.debug("\(decoratedMessage, privacy: .public)")
        case .error:
            logger.error("\(decoratedMessage, privacy: .public)")
        case .critical:
            logger.critical("\(decoratedMessage, privacy: .public)")
        }

        let entry = AppLogEntry(
            subsystem: subsystem,
            category: category,
            type: type,
            message: message
        )
        AppLoggerStore.shared.record(entry)
    }
}
