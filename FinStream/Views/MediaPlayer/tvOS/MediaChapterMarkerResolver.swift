import Foundation
import JellyfinAPI

struct MediaChapterMarkers: Equatable, Sendable {
    var introRangeSeconds: Range<Double>?
    var creditsStartSeconds: Double?
}

enum MediaChapterMarkerResolver {
    /// Resolves markers from media segments provided by server plugins such as
    /// the Intro Skipper plugin. This is the authoritative source when
    /// available; chapters are only a fallback.
    static func resolve(from segments: [MediaSegmentDto]) -> MediaChapterMarkers {
        guard !segments.isEmpty else {
            return .init(introRangeSeconds: nil, creditsStartSeconds: nil)
        }

        // Treat both Intro and Recap segments as skippable "intro" ranges.
        // Prefer the earliest such range in the item.
        let introRangeSeconds: Range<Double>? = segments
            .filter { $0.type == .intro || $0.type == .recap }
            .compactMap { segment -> Range<Double>? in
                guard let start = segment.startSeconds,
                      let end = segment.endSeconds,
                      start.isFinite, end.isFinite, end > start else { return nil }
                return start..<end
            }
            .min(by: { $0.lowerBound < $1.lowerBound })

        // The credits/outro prompt starts at the beginning of the Outro segment.
        let creditsStartSeconds: Double? = segments
            .filter { $0.type == .outro }
            .compactMap { segment -> Double? in
                guard let start = segment.startSeconds, start.isFinite, start >= 0 else { return nil }
                return start
            }
            .min()

        return .init(introRangeSeconds: introRangeSeconds, creditsStartSeconds: creditsStartSeconds)
    }

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

        let introEndSeconds = introRangeSeconds?.upperBound ?? 0
        let creditsStartSeconds: Double? = {
            let creditsIndex = normalized.lastIndex { chapter in
                guard chapter.startSeconds >= introEndSeconds else { return false }
                return matchesAny(of: creditsKeywords, in: chapter.name)
                    && !matchesAny(of: introKeywords, in: chapter.name)
            }
            return creditsIndex.map { normalized[$0].startSeconds }
        }()

        return .init(introRangeSeconds: introRangeSeconds, creditsStartSeconds: creditsStartSeconds)
    }

    private static func firstIndex(
        matchingAnyOf keywords: [String],
        in chapters: [(name: String, startSeconds: Double)]
    ) -> Int? {
        chapters.firstIndex { chapter in
            matchesAny(of: keywords, in: chapter.name)
        }
    }

    private static func matchesAny(of keywords: [String], in text: String) -> Bool {
        keywords.contains { text.localizedStandardContains($0) }
    }
}
