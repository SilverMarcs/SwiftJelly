import SwiftUI
import AVKit
import UIKit
import JellyfinAPI

struct AVPlayerTvOS: UIViewControllerRepresentable {
    let player: AVPlayer?
    let item: BaseItemDto
    let isTransitioning: Bool
    let showSkipIntro: Bool
    let showNextEpisode: Bool
    let onSkipIntro: () -> Void
    let onNextEpisode: () -> Void

    final class Coordinator {
        var lastShowSkipIntro = false
        var lastShowNextEpisode = false
        var lastIsTransitioning = false
        var activityIndicator: UIActivityIndicatorView?
        var relatedContentController: UIViewController?
        var relatedContentToken: String?
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.transportBarIncludesTitleView = true
        updateInfoTabs(for: controller, coordinator: context.coordinator)
        updateContextualActions(for: controller, coordinator: context.coordinator)
        updateTransitionOverlay(for: controller, coordinator: context.coordinator)
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
        updateInfoTabs(for: uiViewController, coordinator: context.coordinator)
        updateContextualActions(for: uiViewController, coordinator: context.coordinator)
        updateTransitionOverlay(for: uiViewController, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func updateContextualActions(for controller: AVPlayerViewController, coordinator: Coordinator) {
        guard coordinator.lastShowSkipIntro != showSkipIntro ||
                coordinator.lastShowNextEpisode != showNextEpisode else {
            return
        }

        var actions: [UIAction] = []

        if showSkipIntro {
            actions.append(UIAction(title: "Skip Intro") { _ in
                onSkipIntro()
            })
        }

        if showNextEpisode {
            actions.append(UIAction(title: "Next Episode") { _ in
                onNextEpisode()
            })
        }

        controller.contextualActions = actions
        coordinator.lastShowSkipIntro = showSkipIntro
        coordinator.lastShowNextEpisode = showNextEpisode
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
