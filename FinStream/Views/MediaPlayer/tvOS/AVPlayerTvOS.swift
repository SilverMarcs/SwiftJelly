import SwiftUI
import AVKit
import UIKit
import JellyfinAPI

struct AVPlayerTvOS: UIViewControllerRepresentable {
    @Environment(\.scenePhase) private var scenePhase
    let player: AVPlayer?
    let item: BaseItemDto
    let isTransitioning: Bool
    let showSkipIntro: Bool
    let nextEpisode: BaseItemDto?
    let creditsStartSeconds: Double?
    let onSkipIntro: () -> Void
    let onSelectEpisode: (BaseItemDto) -> Void
    let onNextEpisode: () -> Void
    let onDismiss: () -> Void

    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var lastShowSkipIntro = false
        var lastIsTransitioning = false
        var lastNextEpisodeID: String?
        var activityIndicator: UIActivityIndicatorView?
        var infoTabController: UIViewController?
        var infoTabToken: String?
        var lastScenePhase: ScenePhase?
        var onNextEpisode: (() -> Void)?
        var onDismiss: (() -> Void)?

        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            shouldPresent proposal: AVContentProposal
        ) -> Bool {
            let proposalVC = NextEpisodeProposalViewController()
            proposalVC.dateOfAutomaticAcceptance = Date().addingTimeInterval(30)
            playerViewController.contentProposalViewController = proposalVC
            return true
        }

        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            didAccept proposal: AVContentProposal
        ) {
            onNextEpisode?()
        }

        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            didReject proposal: AVContentProposal
        ) {
            // Just dismiss the proposal, continue playing current video
        }

        func playerViewControllerWillBeginDismissalTransition(_ playerViewController: AVPlayerViewController) {
            onDismiss?()
        }
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.delegate = context.coordinator
        controller.transportBarIncludesTitleView = true
        controller.allowsPictureInPicturePlayback = true
        controller.speeds = [
            AVPlaybackSpeed(rate: 0.5, localizedName: "0.5×"),
            AVPlaybackSpeed(rate: 1.0, localizedName: "1×"),
            AVPlaybackSpeed(rate: 1.25, localizedName: "1.25×"),
            AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×"),
            AVPlaybackSpeed(rate: 2.0, localizedName: "2×")
        ]
        context.coordinator.onNextEpisode = onNextEpisode
        context.coordinator.onDismiss = onDismiss
        updateInfoTabs(for: controller, coordinator: context.coordinator)
        updateContextualActions(for: controller, coordinator: context.coordinator)
        updateTransitionOverlay(for: controller, coordinator: context.coordinator)
        updateContentProposal(for: controller, coordinator: context.coordinator)
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
        context.coordinator.onNextEpisode = onNextEpisode
        context.coordinator.onDismiss = onDismiss
        updateInfoTabs(for: uiViewController, coordinator: context.coordinator)
        updateContextualActions(for: uiViewController, coordinator: context.coordinator)
        updateTransitionOverlay(for: uiViewController, coordinator: context.coordinator)
        updateContentProposal(for: uiViewController, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func updateContextualActions(for controller: AVPlayerViewController, coordinator: Coordinator) {
        guard coordinator.lastShowSkipIntro != showSkipIntro else {
            return
        }

        var actions: [UIAction] = []

        if showSkipIntro {
            actions.append(UIAction(title: "Skip Intro") { _ in
                onSkipIntro()
            })
        }

        controller.contextualActions = actions
        coordinator.lastShowSkipIntro = showSkipIntro
    }

    private func updateContentProposal(for controller: AVPlayerViewController, coordinator: Coordinator) {
        let newNextEpisodeID = nextEpisode?.id
        
        guard coordinator.lastNextEpisodeID != newNextEpisodeID else { return }
        coordinator.lastNextEpisodeID = newNextEpisodeID

        guard let nextEpisode,
              let playerItem = player?.currentItem,
              let duration = player?.currentItem?.duration,
              duration.isValid,
              duration.seconds.isFinite,
              duration.seconds > 0 else {
            player?.currentItem?.nextContentProposal = nil
            return
        }

        // Determine proposal timing: credits start or 60 seconds before end
        let proposalTimeSeconds: Double
        if let creditsStart = creditsStartSeconds {
            proposalTimeSeconds = creditsStart
        } else {
            proposalTimeSeconds = max(0, duration.seconds - 60)
        }
        let proposalTime = CMTime(seconds: proposalTimeSeconds, preferredTimescale: 1)

        let title = buildProposalTitle(for: nextEpisode)

        // Load image and create proposal asynchronously
        Task {
            let previewImage = await loadPreviewImage(for: nextEpisode)
            
            await MainActor.run {
                let proposal = AVContentProposal(
                    contentTimeForTransition: proposalTime,
                    title: title,
                    previewImage: previewImage
                )

                var metadata: [AVMetadataItem] = []

                if let overview = nextEpisode.overview {
                    metadata.append(makeMetadataItem(.commonIdentifierDescription, value: overview))
                }

                if let rating = nextEpisode.officialRating {
                    metadata.append(makeMetadataItem(.iTunesMetadataContentRating, value: rating))
                }

                proposal.metadata = metadata
                proposal.automaticAcceptanceInterval = 0
                playerItem.nextContentProposal = proposal
            }
        }
    }
    
    private func loadPreviewImage(for episode: BaseItemDto) async -> UIImage? {
        guard let imageURL = ImageURLProvider.imageURL(for: episode, type: .primary) else {
            return nil
        }
        
        // Check cache first
        let request = URLRequest(url: imageURL)
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            return image
        }
        
        // Fetch from network
        do {
            let (data, response) = try await URLSession.shared.data(from: imageURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                return nil
            }
            
            // Cache for future use
            let cachedResponse = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cachedResponse, for: request)
            
            return image
        } catch {
            return nil
        }
    }

    private func buildProposalTitle(for episode: BaseItemDto) -> String {
        var components: [String] = []

        if let seasonEpisodeString = episode.seasonEpisodeString {
            components.append(seasonEpisodeString)
        }

        if let name = episode.name {
            components.append(name)
        }

        return components.joined(separator: " - ")
    }

    private func makeMetadataItem(_ identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }

    private func updateInfoTabs(for controller: AVPlayerViewController, coordinator: Coordinator) {
        let resumed = scenePhase == .active && coordinator.lastScenePhase != .active
        coordinator.lastScenePhase = scenePhase
        let token = "\(item.id ?? ""):\(item.seriesID ?? ""):\(item.seasonID ?? "")"
        guard coordinator.infoTabToken != token else {
            if resumed, let episodes = coordinator.infoTabController as? SeasonEpisodesViewController {
                episodes.reloadIfEmpty()
            }
            return
        }

        // For an episode, show the other episodes in its season; for movies (and
        // anything without season context) fall back to related content.
        let infoTab: UIViewController
        if item.type == .episode, item.seriesID != nil, item.seasonID != nil {
            infoTab = SeasonEpisodesViewController(item: item, onSelectEpisode: onSelectEpisode)
        } else {
            infoTab = RelatedContentViewController(item: item)
        }

        coordinator.infoTabController = infoTab
        coordinator.infoTabToken = token
        controller.customInfoViewControllers = [infoTab]
    }

    private func updateTransitionOverlay(for controller: AVPlayerViewController, coordinator: Coordinator) {
        guard coordinator.lastIsTransitioning != isTransitioning else { return }
        coordinator.lastIsTransitioning = isTransitioning

        if isTransitioning {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            controller.contentOverlayView?.addSubview(indicator)
            if let overlayView = controller.contentOverlayView {
                NSLayoutConstraint.activate([
                    indicator.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
                    indicator.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
                ])
            }
            indicator.startAnimating()
            coordinator.activityIndicator = indicator
        } else {
            coordinator.activityIndicator?.removeFromSuperview()
            coordinator.activityIndicator = nil
        }
    }
}
