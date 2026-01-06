import Foundation
import JellyfinAPI

struct MediaChapterMarkers: Equatable, Sendable {
    var introRangeSeconds: Range<Double>?
    var creditsStartSeconds: Double?
}

enum MediaChapterMarkerResolver {
    static func resolve(from chapters: [ChapterInfo]?) -> MediaChapterMarkers {
        guard let chapters, !chapters.isEmpty else {
            return .init(introRangeSeconds: nil, creditsStartSeconds: nil)
        }

        let normalized = chapters
            .compactMap { chapter -> (name: String, startSeconds: Double)? in
                guard let ticks = chapter.startPositionTicks else { return nil }
                let startSeconds = Double(ticks) / 10_000_000
                guard startSeconds.isFinite, startSeconds >= 0 else { return nil }
                return (chapter.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", startSeconds)
            }
            .sorted(by: { $0.startSeconds < $1.startSeconds })

        let introKeywords = ["intro", "introduction", "opening", "opening credits"]
        let creditsKeywords = ["credits", "end credits", "ending credits"]

        let introIndex = firstIndex(matchingAnyOf: introKeywords, in: normalized)
        let introRangeSeconds: Range<Double>? = {
            guard let introIndex else { return nil }
            let start = normalized[introIndex].startSeconds
            guard introIndex + 1 < normalized.count else { return nil }
            let end = normalized[introIndex + 1].startSeconds
            guard end > start else { return nil }
            return start..<end
        }()

        let creditsStartSeconds: Double? = {
            guard let creditsIndex = firstIndex(matchingAnyOf: creditsKeywords, in: normalized) else { return nil }
            return normalized[creditsIndex].startSeconds
        }()

        return .init(introRangeSeconds: introRangeSeconds, creditsStartSeconds: creditsStartSeconds)
    }

    private static func firstIndex(
        matchingAnyOf keywords: [String],
        in chapters: [(name: String, startSeconds: Double)]
    ) -> Int? {
        chapters.firstIndex { chapter in
            let name = chapter.name
            return keywords.contains { name.localizedStandardContains($0) }
        }
    }
}

