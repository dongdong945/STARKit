@preconcurrency import Foundation

/// 网络请求插件协议
public protocol PluginType: Sendable {
    /// 准备请求（在发送前修改请求）
    func prepare(_ request: URLRequest, target: TargetType) async -> URLRequest

    /// 即将发送请求（用于日志等）
    func willSend(_ request: URLRequest, target: TargetType)

    /// 接收到响应或错误
    func didReceive(_ result: Result<(response: URLResponse, data: Data), Error>, target: TargetType)
}

extension PluginType {
    /// 默认实现：不修改请求
    public func prepare(_ request: URLRequest, target: TargetType) async -> URLRequest { request }

    /// 默认实现：不处理
    public func willSend(_ request: URLRequest, target: TargetType) {}

    /// 默认实现：不处理
    public func didReceive(_ result: Result<(response: URLResponse, data: Data), Error>, target: TargetType) {}
}
