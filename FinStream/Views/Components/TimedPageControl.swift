#if os(iOS)
import SwiftUI
import UIKit

/// The system page control with a built-in auto-advance timer, as seen in the Apple TV app.
///
/// SwiftUI has no native equivalent: `TabView`'s page index has no timer progress or scrubbing,
/// so this wraps `UIPageControl` with `UIPageControlTimerProgress`.
struct TimedPageControl: UIViewRepresentable {
    let numberOfPages: Int
    let currentPage: Int
    /// Seconds each page stays visible before the control advances.
    let duration: TimeInterval
    /// Pauses the timer, e.g. while the user is swiping the content.
    let isPaused: Bool
    let tint: Color
    /// Beyond this many pages the control narrows and shrinks the outer dots, like the Apple TV app.
    var maximumVisiblePages = 8
    /// Called when the timer, a tap, or a scrub selects a page. `isScrubbing` is `true` while the
    /// user drags across the dots, when content should follow immediately rather than animate.
    let onSelectPage: (_ page: Int, _ isScrubbing: Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectPage: onSelectPage)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.hidesForSinglePage = true
        pageControl.addTarget(context.coordinator, action: #selector(Coordinator.pageChanged(_:)), for: .valueChanged)

        let progress = UIPageControlTimerProgress(preferredDuration: duration)
        progress.resetsToInitialPageAfterEnd = true
        progress.delegate = context.coordinator
        pageControl.progress = progress

        return pageControl
    }

    func updateUIView(_ pageControl: UIPageControl, context: Context) {
        let coordinator = context.coordinator
        coordinator.onSelectPage = onSelectPage
        coordinator.isPaused = isPaused

        pageControl.numberOfPages = numberOfPages
        pageControl.currentPageIndicatorTintColor = UIColor(tint)
        pageControl.pageIndicatorTintColor = UIColor(tint.opacity(0.35))

        // The control owns the page while it's being scrubbed; pushing a page in would fight the finger.
        if !coordinator.isScrubbing, pageControl.currentPage != currentPage {
            pageControl.currentPage = currentPage
        }

        guard let progress = pageControl.progress as? UIPageControlTimerProgress else { return }
        progress.preferredDuration = duration
        coordinator.updateTimer(progress)
    }

    static func dismantleUIView(_ pageControl: UIPageControl, coordinator: Coordinator) {
        (pageControl.progress as? UIPageControlTimerProgress)?.pauseTimer()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIPageControl, context: Context) -> CGSize? {
        // A narrower frame than all dots need makes the control scroll its dots and shrink the edge ones.
        let visibleSize = uiView.size(forNumberOfPages: min(numberOfPages, maximumVisiblePages))
        return CGSize(width: min(visibleSize.width, proposal.width ?? .infinity), height: visibleSize.height)
    }

    @MainActor
    final class Coordinator: NSObject, UIPageControlTimerProgressDelegate {
        var onSelectPage: (Int, Bool) -> Void
        var isPaused = false
        /// The control hides its progress while the user drags across the dots.
        private(set) var isScrubbing = false

        init(onSelectPage: @escaping (Int, Bool) -> Void) {
            self.onSelectPage = onSelectPage
        }

        func updateTimer(_ progress: UIPageControlTimerProgress) {
            if isPaused || isScrubbing {
                progress.pauseTimer()
            } else if !progress.isRunning {
                progress.resumeTimer()
            }
        }

        /// Called when the user taps or scrubs across the dots.
        @objc func pageChanged(_ sender: UIPageControl) {
            onSelectPage(sender.currentPage, isScrubbing || sender.interactionState == .continuous)
        }

        /// Called when the timer finishes a page; the control moves to `page` itself.
        func pageControlTimerProgress(_ progress: UIPageControlTimerProgress, shouldAdvanceToPage page: Int) -> Bool {
            onSelectPage(page, false)
            return true
        }

        func pageControlProgressVisibilityDidChange(_ progress: UIPageControlProgress) {
            isScrubbing = !progress.isProgressVisible
            if let timerProgress = progress as? UIPageControlTimerProgress {
                updateTimer(timerProgress)
            }
        }
    }
}
#endif
