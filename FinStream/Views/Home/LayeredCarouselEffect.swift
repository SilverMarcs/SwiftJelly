import SwiftUI

/// Interpolates fractional page progress for arrow-driven navigation on tvOS.
struct LayeredCarouselEffect: AnimatableModifier {
    let index: Int
    var progress: CGFloat
    let maximumBlur: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let relativeProgress = LayeredCarouselMetrics.relativeProgress(at: index, progress: progress)
        content
            .blur(radius: LayeredCarouselMetrics.blurRadius(
                relativeProgress: relativeProgress, maximumRadius: maximumBlur
            ))
            .opacity(LayeredCarouselMetrics.opacity(at: index, progress: progress))
    }
}

