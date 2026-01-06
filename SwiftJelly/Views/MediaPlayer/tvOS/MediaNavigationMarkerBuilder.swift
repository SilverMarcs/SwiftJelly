import AVFoundation
import JellyfinAPI
import AVKit

enum MediaNavigationMarkerBuilder {
    static func makeNavigationMarkerGroups(
        from chapters: [ChapterInfo]?,
        durationSeconds: Double?
    ) -> [AVNavigationMarkersGroup] {
        guard let chapters, !chapters.isEmpty else {
            return []
        }

        let normalized = chapters.enumerated()
            .compactMap { index, chapter -> (index: Int, title: String, startSeconds: Double)? in
                guard let ticks = chapter.startPositionTicks else { return nil }
                let startSeconds = Double(ticks) / 10_000_000
                guard startSeconds.isFinite, startSeconds >= 0 else { return nil }
                let title = chapter.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return (index: index, title: title, startSeconds: startSeconds)
            }
            .sorted { $0.startSeconds < $1.startSeconds }

        guard !normalized.isEmpty else {
            return []
        }

        let resolvedDurationSeconds: Double? = {
            guard let durationSeconds,
                  durationSeconds.isFinite,
                  durationSeconds > 0 else {
                return nil
            }
            return durationSeconds
        }()

        var timedGroups: [AVTimedMetadataGroup] = []
        timedGroups.reserveCapacity(normalized.count)

        for (offset, chapter) in normalized.enumerated() {
            let title = chapter.title.isEmpty ? "Chapter \(offset + 1)" : chapter.title
            let start = chapter.startSeconds
            let end: Double = {
                if offset + 1 < normalized.count {
                    return normalized[offset + 1].startSeconds
                }
                if let duration = resolvedDurationSeconds {
                    return duration
                }
                return start + 1
            }()
            let safeEnd = end > start ? end : start + 1

            let metadata = [makeMetadataItem(.commonIdentifierTitle, value: title)]
            let timeRange = CMTimeRangeFromTimeToTime(
                start: CMTime(seconds: start, preferredTimescale: 600),
                end: CMTime(seconds: safeEnd, preferredTimescale: 600)
            )

            timedGroups.append(AVTimedMetadataGroup(items: metadata, timeRange: timeRange))
        }

        return [AVNavigationMarkersGroup(title: nil, timedNavigationMarkers: timedGroups)]
    }

    private static func makeMetadataItem(_ identifier: AVMetadataIdentifier, value: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString
        item.extendedLanguageTag = "und"
        return item.copy() as? AVMetadataItem ?? item
    }
}
