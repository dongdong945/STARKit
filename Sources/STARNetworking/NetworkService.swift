@preconcurrency import Foundation

/// Server-Sent Events (SSE) 事件
public struct SSEEvent: Sendable {
    /// 事件 ID
    public let id: String?
    /// 事件类型
    public let event: String?
    /// 事件数据
    public let data: String?
    /// 重试间隔（毫秒）
    public let retry: String?
}

/// SSE 错误类型
public enum SSEError: LocalizedError {
    /// 响应不是 SSE 格式（可能是普通 JSON）
    case notSSEResponse(String)

    public var errorDescription: String? {
        switch self {
        case .notSSEResponse(let content):
            return content
        }
    }

    /// 原始响应内容
    public var rawContent: String? {
        switch self {
        case .notSSEResponse(let content):
            return content
        }
    }
}

/// 网络服务
public final class NetworkService: @unchecked Sendable {
    /// 插件列表
    private let plugins: [PluginType]
    /// URL 会话
    private let session: URLSession

    /// 初始化网络服务
    public init(session: URLSession = .shared, plugins: [PluginType] = []) {
        self.session = session
        self.plugins = plugins
    }

    /// 发送网络请求
    @available(iOS 15.0, *)
    public func request(_ target: TargetType) async throws -> Data {
        var urlRequest = try urlRequest(for: target)

        // 应用插件准备请求
        for plugin in plugins {
            urlRequest = await plugin.prepare(urlRequest, target: target)
        }

        // 通知插件即将发送请求
        plugins.forEach { $0.willSend(urlRequest, target: target) }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            // 通知插件请求成功
            plugins.forEach { $0.didReceive(.success((response, data)), target: target) }
            return data
        } catch {
            // 通知插件请求失败
            plugins.forEach { $0.didReceive(.failure(error), target: target) }
            throw error
        }
    }

    /// 创建 Server-Sent Events (SSE) 流
    @available(iOS 15.0, *)
    public func sse(_ target: some TargetType & Sendable) -> AsyncThrowingStream<SSEEvent, Error> {
        // 捕获不可变值以避免捕获 self
        let session = session
        let plugins = plugins

        // 在流外部创建 URLRequest 以避免捕获 self
        let urlRequestResult: Result<URLRequest, Error>
        do {
            urlRequestResult = try .success(urlRequest(for: target))
        } catch {
            urlRequestResult = .failure(error)
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                var urlRequest: URLRequest
                switch urlRequestResult {
                case .success(let request):
                    urlRequest = request
                case .failure(let error):
                    continuation.finish(throwing: error)
                    return
                }

                // 应用插件准备请求
                for plugin in plugins {
                    urlRequest = await plugin.prepare(urlRequest, target: target)
                }

                do {
                    // 使用 bytes(for:) 实现真正的流式接收
                    let (bytes, _) = try await session.bytes(for: urlRequest)

                    var lineBuffer = Data() // 使用 Data 累积字节，支持 UTF-8 多字节字符
                    var rawContent = Data() // 保存原始内容，用于错误处理
                    var currentEvent = SSEEventBuilder()
                    var eventCount = 0

                    for try await byte in bytes {
                        // 检查任务是否被取消
                        try Task.checkCancellation()

                        lineBuffer.append(byte)
                        rawContent.append(byte)

                        // 检测到换行符时处理行
                        if byte == UInt8(ascii: "\n") {
                            // 移除末尾的换行符后解码为字符串
                            let lineData = lineBuffer.dropLast()
                            let line = String(decoding: lineData, as: UTF8.self)
                            lineBuffer = Data()

                            if line.isEmpty {
                                // 空行表示事件结束
                                if let event = currentEvent.build() {
                                    eventCount += 1
                                    continuation.yield(event)
                                }
                                currentEvent = SSEEventBuilder()
                            } else if line.hasPrefix(":") {
                                // 注释行，忽略
                                continue
                            } else {
                                // 解析字段
                                if let colonIndex = line.firstIndex(of: ":") {
                                    let field = String(line[..<colonIndex])
                                    var value = String(line[line.index(after: colonIndex)...])
                                    // 移除值开头的空格
                                    if value.hasPrefix(" ") {
                                        value = String(value.dropFirst())
                                    }
                                    currentEvent.set(field: field, value: value)
                                }
                            }
                        }
                    }

                    // 流结束后，如果没有产生任何 SSE 事件，说明响应不是 SSE 格式
                    // 可能是普通 JSON 错误响应，将原始内容作为错误抛出
                    if eventCount == 0, !rawContent.isEmpty {
                        let rawString = String(decoding: rawContent, as: UTF8.self)
                        throw SSEError.notSSEResponse(rawString)
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    /// 根据目标创建 URLRequest
    private func urlRequest(for target: TargetType) throws -> URLRequest {
        let url = target.baseURL.appendingPathComponent(target.path)
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue
        request.allHTTPHeaderFields = target.headers

        switch target.task {
        case .requestPlain:
            break
        case .requestData(let data):
            request.httpBody = data
        case .requestJSONEncodable(let encodable):
            request.httpBody = try JSONEncoder().encode(encodable)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .requestParameters(let parameters, let encoding):
            try encoding.encode(&request, with: parameters)
        }

        return request
    }
}

/// SSE 事件构建器
private struct SSEEventBuilder {
    var id: String?
    var event: String?
    var data: String?
    var retry: String?

    mutating func set(field: String, value: String) {
        switch field {
        case "id":
            id = value
        case "event":
            event = value
        case "data":
            // 多行 data 拼接
            if let existing = data {
                data = existing + "\n" + value
            } else {
                data = value
            }
        case "retry":
            retry = value
        default:
            break
        }
    }

    func build() -> SSEEvent? {
        guard id != nil || event != nil || data != nil || retry != nil else {
            return nil
        }
        return SSEEvent(id: id, event: event, data: data, retry: retry)
    }
}
