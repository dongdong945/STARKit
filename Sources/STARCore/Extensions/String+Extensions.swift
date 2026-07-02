import CryptoKit
import Foundation

extension String {
    /// 计算字符串的 SHA1 哈希值
    public var sha1: String {
        let data = Data(utf8)
        let digest = Insecure.SHA1.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// 首字母大写的字符串
    public var capitalizingFirstLetter: String {
        guard !isEmpty else { return "" }

        let firstChar = prefix(1).uppercased()
        let remainingString = dropFirst()

        return firstChar + remainingString
    }
}
