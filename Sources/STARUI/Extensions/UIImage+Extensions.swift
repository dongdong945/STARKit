import UIKit

extension UIImage {
    /// 水平翻转图片
    public func horizontallyFlipped() -> UIImage? {
        guard let cgImage else { return nil }

        return UIImage(cgImage: cgImage, scale: scale, orientation: .leftMirrored)
    }
}
