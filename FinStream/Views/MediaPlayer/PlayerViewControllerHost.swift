import AVKit
import UIKit

/// Owns the `AVPlayerViewController` for one playback.
///
/// Picture in Picture belongs to the `AVPlayerViewController`, but SwiftUI
/// tears a representable's controller down whenever the player is dismissed.
/// Keeping the controller here lets the player close while the video floats,
/// so the rest of the app stays usable, and lets it come back on restore.
final class PlayerViewControllerHost: NSObject {
    let playerViewController = AVPlayerViewController()

    /// True from the moment Picture in Picture starts until it fully stops.
    private(set) var isPictureInPictureActive = false

    /// Asks the app to show (`true`) or hide (`false`) the player.
    var onPresentationRequest: ((Bool) -> Void)?

    /// Picture in Picture was closed without returning to the player.
    var onPictureInPictureDismissed: (() -> Void)?

    #if os(tvOS)
    /// Receives the tvOS-only delegate callbacks (content proposals and
    /// dismissal). Retained so its per-controller state lives as long as the
    /// controller does.
    var forwardingDelegate: AVPlayerViewControllerDelegate?
    #endif

    private var pendingRestoreCompletion: ((Bool) -> Void)?
    private var restoreTimeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        let controller = playerViewController
        controller.delegate = self
        controller.allowsPictureInPicturePlayback = true
        #if os(tvOS)
        controller.transportBarIncludesTitleView = true
        controller.speeds = [
            AVPlaybackSpeed(rate: 0.5, localizedName: "0.5×"),
            AVPlaybackSpeed(rate: 1.0, localizedName: "1×"),
            AVPlaybackSpeed(rate: 1.25, localizedName: "1.25×"),
            AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×"),
            AVPlaybackSpeed(rate: 2.0, localizedName: "2×")
        ]
        #else
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = false
        controller.updatesNowPlayingInfoCenter = true
        #endif
    }

    func setPlayer(_ player: AVPlayer?) {
        guard playerViewController.player !== player else { return }
        playerViewController.player = player
    }

    // MARK: - Embedding

    func embed(in container: UIViewController) {
        let controller = playerViewController
        guard controller.parent !== container else { return }
        if controller.parent != nil {
            removeFromCurrentParent()
        }
        container.addChild(controller)
        controller.view.frame = container.view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.view.addSubview(controller.view)
        controller.didMove(toParent: container)
        #if os(iOS)
        // The container forwards overlay visibility to this controller, so
        // ask the system to re-query now that it is the child.
        container.setNeedsStatusBarAppearanceUpdate()
        container.setNeedsUpdateOfHomeIndicatorAutoHidden()
        container.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        #endif
    }

    /// Only the container currently holding the controller may remove it; an
    /// outgoing presentation must not steal it back from an incoming one.
    func detach(from container: UIViewController) {
        guard playerViewController.parent === container else { return }
        removeFromCurrentParent()
    }

    func containerDidAppear(_ container: UIViewController) {
        guard playerViewController.parent === container else { return }
        if pendingRestoreCompletion != nil {
            finishPendingRestore(restored: true)
        } else if isPictureInPictureActive {
            // The player was opened from inside the app while the video
            // floats. Bring it back instead of showing AVKit's placeholder.
            stopPictureInPicture()
        }
    }

    private func removeFromCurrentParent() {
        let controller = playerViewController
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }

    /// AVPlayerViewController has no public stop API; detaching the player
    /// ends Picture in Picture without pausing playback.
    private func stopPictureInPicture() {
        guard let player = playerViewController.player else { return }
        let wasPlaying = player.rate > 0
        playerViewController.player = nil
        Task { @MainActor [weak self] in
            guard let self, self.playerViewController.player == nil else { return }
            self.playerViewController.player = player
            if wasPlaying, player.rate == 0 {
                player.play()
            }
        }
    }

    private func finishPendingRestore(restored: Bool) {
        restoreTimeoutTask?.cancel()
        restoreTimeoutTask = nil
        guard let completion = pendingRestoreCompletion else { return }
        pendingRestoreCompletion = nil
        completion(restored)
    }
}

extension PlayerViewControllerHost: AVPlayerViewControllerDelegate {
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        isPictureInPictureActive = true
    }

    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Close the player so the rest of the app is usable while the video
        // floats. On iOS, PiP that started because the app went to the
        // background keeps the player open so returning restores in place.
        #if os(tvOS)
        onPresentationRequest?(false)
        #else
        if playerViewController.view.window?.windowScene?.activationState == .foregroundActive {
            onPresentationRequest?(false)
        }
        #endif
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        isPictureInPictureActive = false
    }

    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        isPictureInPictureActive = false
        let isShowingPlayer = playerViewController.view.window != nil
        finishPendingRestore(restored: isShowingPlayer)
        if !isShowingPlayer {
            onPictureInPictureDismissed?()
        }
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        if playerViewController.view.window != nil {
            completionHandler(true)
            return
        }
        finishPendingRestore(restored: false)
        pendingRestoreCompletion = completionHandler
        onPresentationRequest?(true)
        restoreTimeoutTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            guard let self else { return }
            self.finishPendingRestore(restored: self.playerViewController.view.window != nil)
        }
    }

    #if os(tvOS)
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        shouldPresent proposal: AVContentProposal
    ) -> Bool {
        forwardingDelegate?.playerViewController?(playerViewController, shouldPresent: proposal) ?? false
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        didAccept proposal: AVContentProposal
    ) {
        forwardingDelegate?.playerViewController?(playerViewController, didAccept: proposal)
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        didReject proposal: AVContentProposal
    ) {
        forwardingDelegate?.playerViewController?(playerViewController, didReject: proposal)
    }

    func playerViewControllerWillBeginDismissalTransition(_ playerViewController: AVPlayerViewController) {
        forwardingDelegate?.playerViewControllerWillBeginDismissalTransition?(playerViewController)
    }
    #endif
}
