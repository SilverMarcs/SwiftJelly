import SwiftUI
import AVKit
import UIKit
import JellyfinAPI

struct AVPlayerTvOS: UIViewControllerRepresentable {
    let player: AVPlayer?
    let item: BaseItemDto
    let isTransitioning: Bool
    let showSkipIntro: Bool
    let nextEpisode: BaseItemDto?
    let creditsStartSeconds: Double?
    let onSkipIntro: () -> Void
    let onNextEpisode: () -> Void
    let onDismiss: () -> Void

    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var lastShowSkipIntro = false
        var lastIsTransitioning = false
        var lastNextEpisodeID: String?
        var activityIndicator: UIActivityIndicatorView?
        var relatedContentController: UIViewController?
        var relatedContentToken: String?
        var onNextEpisode: (() -> Void)?
        var onDismiss: (() -> Void)?

        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            shouldPresent proposal: AVContentProposal
        ) -> Bool {
            let proposalVC = NextEpisodeProposalViewController()
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
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.delegate = context.coordinator
        controller.transportBarIncludesTitleView = true
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
        print("[ContentProposal] updateContentProposal called - nextEpisode: \(newNextEpisodeID ?? "nil"), lastID: \(coordinator.lastNextEpisodeID ?? "nil")")
        
        guard coordinator.lastNextEpisodeID != newNextEpisodeID else {
            print("[ContentProposal] Skipping - same episode ID")
            return
        }
        coordinator.lastNextEpisodeID = newNextEpisodeID

        guard let nextEpisode,
              let playerItem = player?.currentItem,
              let duration = player?.currentItem?.duration,
              duration.isValid,
              duration.seconds.isFinite,
              duration.seconds > 0 else {
            print("[ContentProposal] Clearing proposal - missing requirements")
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
        print("[ContentProposal] Creating proposal for \(nextEpisode.name ?? "unknown") at \(proposalTime.seconds)s (duration: \(duration.seconds)s, creditsDetected: \(creditsStartSeconds != nil))")

        let title = buildProposalTitle(for: nextEpisode)
        var previewImage: UIImage?

        // Attempt to load the preview image synchronously from cache or use a placeholder
        if let imageURL = ImageURLProvider.imageURL(for: nextEpisode, type: .primary) {
            // Try to get from URLCache
            let request = URLRequest(url: imageURL)
            if let cachedResponse = URLCache.shared.cachedResponse(for: request),
               let image = UIImage(data: cachedResponse.data) {
                previewImage = image
            }
        }

        let proposal = AVContentProposal(
            contentTimeForTransition: proposalTime,
            title: title,
            previewImage: previewImage
        )

        // Build metadata
        var metadata: [AVMetadataItem] = []

        if let overview = nextEpisode.overview {
            metadata.append(makeMetadataItem(.commonIdentifierDescription, value: overview))
        }

        if let rating = nextEpisode.officialRating {
            metadata.append(makeMetadataItem(.iTunesMetadataContentRating, value: rating))
        }

        proposal.metadata = metadata

        // Auto-accept 4 seconds after playback ends
        proposal.automaticAcceptanceInterval = 0

        playerItem.nextContentProposal = proposal
        print("[ContentProposal] Proposal set on player item successfully")

        // Prefetch the image in background if not cached
        if previewImage == nil, let imageURL = ImageURLProvider.imageURL(for: nextEpisode, type: .primary) {
            Task.detached {
                if let (data, response) = try? await URLSession.shared.data(from: imageURL),
                   let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: imageURL))
                }
            }
        }
    }

    private func buildProposalTitle(for episode: BaseItemDto) -> String {
        var components: [String] = []

        if let seasonNumber = episode.parentIndexNumber,
           let episodeNumber = episode.indexNumber {
            components.append("S\(seasonNumber)E\(episodeNumber)")
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
        let token = String(describing: item.id)
        guard coordinator.relatedContentToken != token else {
            if let related = coordinator.relatedContentController {
                controller.customInfoViewControllers = [related]
            }
            return
        }

        let related = RelatedContentViewController(item: item)
        coordinator.relatedContentController = related
        coordinator.relatedContentToken = token
        controller.customInfoViewControllers = [related]
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
