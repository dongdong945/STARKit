import AVFoundation
import SwiftUI
import UIKit

/// 视频背景修饰符：宽度填充、顶部对齐、底部超出裁剪
public struct CustomVideoBackgroundModifier: ViewModifier {
    /// 视频文件名（不含扩展名）
    public let videoName: String
    /// 背景填充色
    public let fillColor: Color

    public init(
        videoName: String,
        fillColor: Color = .black
    ) {
        self.videoName = videoName
        self.fillColor = fillColor
    }

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                GeometryReader { geometry in
                    fillColor
                        .ignoresSafeArea()
                        .overlay(alignment: .top) {
                            VideoPlayerView(videoName: videoName, containerWidth: geometry.size.width)
                                .ignoresSafeArea()
                        }
                }
                .ignoresSafeArea()
            }
    }
}

private struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    let containerWidth: CGFloat

    func makeUIView(context: Context) -> PlayerView {
        let playerView = PlayerView()
        playerView.containerWidth = containerWidth

        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            return playerView
        }

        let player = AVPlayer(url: url)
        playerView.playerLayer.player = player
        playerView.playerLayer.videoGravity = .resize
        playerView.alpha = 0

        context.coordinator.player = player
        context.coordinator.playerView = playerView
        context.coordinator.observePlayerReadiness()

        return playerView
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.containerWidth = containerWidth
        uiView.updatePlayerLayerFrame()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, @unchecked Sendable {
        var player: AVPlayer?
        var playerView: PlayerView?
        private var observer: NSKeyValueObservation?

        func observePlayerReadiness() {
            guard let player else { return }

            observer = player.observe(\.currentItem?.status, options: [.new]) { [weak self] player, _ in
                guard let self,
                      let item = player.currentItem,
                      item.status == .readyToPlay
                else { return }

                guard let playerView else { return }

                DispatchQueue.main.async {
                    playerView.updatePlayerLayerFrame()

                    UIView.animate(withDuration: 0.3) {
                        playerView.alpha = 1.0
                    }
                    player.play()
                }

                observer?.invalidate()
                observer = nil
            }
        }

        deinit {
            observer?.invalidate()
            player?.pause()
            player = nil
            playerView = nil
        }
    }
}

/// UIView 容器，包含 AVPlayerLayer sublayer
private final class PlayerView: UIView {
    let playerLayer = AVPlayerLayer()
    var containerWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePlayerLayerFrame()
    }

    /// 宽度填充模式：宽度 = 容器宽度，高度按比例计算，顶部对齐
    func updatePlayerLayerFrame() {
        guard let videoSize = playerLayer.player?.currentItem?.presentationSize,
              videoSize.width > 0, videoSize.height > 0 else {
            playerLayer.frame = bounds
            return
        }

        let videoAspectRatio = videoSize.width / videoSize.height
        let scaledHeight = containerWidth / videoAspectRatio

        // 宽度填充、顶部对齐
        playerLayer.frame = CGRect(x: 0, y: 0, width: containerWidth, height: scaledHeight)
    }

    override var intrinsicContentSize: CGSize {
        guard let videoSize = playerLayer.player?.currentItem?.presentationSize,
              videoSize.width > 0, videoSize.height > 0 else {
            return CGSize(width: containerWidth, height: UIView.noIntrinsicMetric)
        }

        let videoAspectRatio = videoSize.width / videoSize.height
        let scaledHeight = containerWidth / videoAspectRatio
        return CGSize(width: containerWidth, height: scaledHeight)
    }
}
