import Foundation

enum LayeredCarouselMetrics {
    static func blurRadius(relativeProgress: CGFloat, maximumRadius: CGFloat) -> CGFloat {
        let distance = min(abs(relativeProgress), 1)
        // Both settled pages and fully offscreen pages have no blur surface to maintain.
        return maximumRadius * 4 * distance * (1 - distance)
    }

    static func renderedIndices(visibleIndex: Int, selectedIndex: Int, count: Int) -> Set<Int> {
        guard count > 0 else { return [] }
        let center = min(max(visibleIndex, 0), count - 1)
        var indices = Set(max(center - 1, 0)...min(center + 1, count - 1))
        if (0..<count).contains(selectedIndex) {
            indices.insert(selectedIndex)
        }
        return indices
    }

    static func relativeProgress(at index: Int, progress: CGFloat) -> CGFloat {
        min(max(CGFloat(index) - progress, -1), 1)
    }

    static func clampedProgress(_ progress: CGFloat, count: Int) -> CGFloat {
        min(max(progress, 0), CGFloat(max(count - 1, 0)))
    }

    static func opacity(at index: Int, progress: CGFloat) -> Double {
        // Earlier pages sit above later ones and uncover them as the scroll advances.
        1 - Double(min(max(progress - CGFloat(index), 0), 1))
    }
}

