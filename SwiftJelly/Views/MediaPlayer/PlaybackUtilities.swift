import AVKit
import JellyfinAPI

struct PlaybackLoadResult {
    let player: AVPlayer
    let info: PlaybackInfoResponse
    let item: BaseItemDto
}

struct PlaybackUtilities {
    /// Loads playback information and creates an AVPlayer
    static func loadPlaybackInfo(
        for item: BaseItemDto,
        into existingPlayer: AVPlayer? = nil,
        audioStreamIndex: Int? = nil,
        resumeSeconds: Double? = nil
    ) async throws -> PlaybackLoadResult {
        let hasSubtitleStreams = item.mediaSources?
            .first?
            .mediaStreams?
            .contains(where: { $0.type == .subtitle }) ?? false
        let itemForPlayback: BaseItemDto
        let didFetchItem: Bool
        if hasSubtitleStreams {
            itemForPlayback = item
            didFetchItem = false
        } else if let id = item.id, let freshItem = try? await JFAPI.loadItem(by: id) {
            itemForPlayback = freshItem
            didFetchItem = true
        } else {
            itemForPlayback = item
            didFetchItem = false
        }

        let preferredSubtitleCodecs: Set<String> = [
            "ass",
            "mov_text",
            "srt",
            "ssa",
            "subrip",
            "text",
            "ttml",
            "vtt",
            "webvtt"
        ]
        func selectSubtitleStreamIndex(from streams: [MediaStream]) -> Int? {
            streams
                .first(where: { stream in
                    guard let codec = stream.codec?.lowercased() else { return false }
                    return preferredSubtitleCodecs.contains(codec)
                })?
                .index ?? streams.first?.index
        }
        let subtitleStreams = itemForPlayback.mediaSources?
            .first?
            .mediaStreams?
            .filter { $0.type == .subtitle } ?? []
        let subtitleStreamIndex = selectSubtitleStreamIndex(from: subtitleStreams)
        // Start fetching playback info, then refresh the item in the background
        let resumeTicks: Int64? = {
            guard let resumeSeconds else { return nil }
            return Int64(resumeSeconds * 10_000_000)
        }()
        
        let initialInfo = try await JFAPI.getPlaybackInfo(
            for: itemForPlayback,
            subtitleStreamIndex: subtitleStreamIndex,
            audioStreamIndex: audioStreamIndex,
            startPositionTicks: resumeTicks
        )
        async let freshItemTask: BaseItemDto? = {
            guard let id = item.id else { return itemForPlayback }
            if didFetchItem {
                return itemForPlayback
            }
            return try? await JFAPI.loadItem(by: id)
        }()

        let info: PlaybackInfoResponse
        if subtitleStreamIndex == nil {
            let infoSubtitleStreams = initialInfo.mediaSource.mediaStreams?
                .filter { $0.type == .subtitle } ?? []
            if let streamIndex = selectSubtitleStreamIndex(from: infoSubtitleStreams) {
                info = try await JFAPI.getPlaybackInfo(
                    for: itemForPlayback,
                    subtitleStreamIndex: streamIndex,
                    audioStreamIndex: audioStreamIndex,
                    startPositionTicks: resumeTicks
                )
            } else {
                info = initialInfo
            }
        } else {
            info = initialInfo
        }
        
        guard item.id != nil else {
            throw PlaybackError.missingItemID
        }

        let latestItem = await freshItemTask ?? item

        let playerItem = AVPlayerItem(url: info.playbackURL)

        #if os(tvOS)
        let durationSeconds: Double? = {
            if let ticks = info.mediaSource.runTimeTicks, ticks > 0 {
                return Double(ticks) / 10_000_000
            }
            if let ticks = latestItem.runTimeTicks, ticks > 0 {
                return Double(ticks) / 10_000_000
            }
            return nil
        }()
        let navigationMarkers = await MediaNavigationMarkerBuilder.makeNavigationMarkerGroups(
            for: latestItem,
            chapters: latestItem.chapters,
            durationSeconds: durationSeconds
        )
        if !navigationMarkers.isEmpty {
            playerItem.navigationMarkerGroups = navigationMarkers
        }
        #endif
        
        #if !os(macOS)
        let metadata = await latestItem.createMetadataItems()
        playerItem.externalMetadata = metadata
        #endif
        
        let player = existingPlayer ?? AVPlayer()
        player.pause()
        player.replaceCurrentItem(with: playerItem)
        
        #if os(macOS)
        player.preventsDisplaySleepDuringVideoPlayback = true
        #endif
        
        // Prefer start time from freshly fetched item (to avoid stale progress)
        let fallbackStartSeconds = Double(latestItem.startTimeSeconds)
        let targetStartSeconds = resumeSeconds ?? fallbackStartSeconds
        let time = CMTime(seconds: targetStartSeconds, preferredTimescale: 1)
        await player.seek(to: time)
        
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        player.play()

        return PlaybackLoadResult(player: player, info: info, item: latestItem)
    }
    
    /// Reports current playback progress to Jellyfin server
    static func reportPlaybackProgress(
        player: AVPlayer,
        item: BaseItemDto,
        isPaused: Bool
    ) async {
        guard let itemID = item.id else { return }
        let ticks = player.currentTime().seconds.toPositionTicks
        await JFAPI.reportPlaybackProgress(
            itemID: itemID,
            mediaSourceID: item.mediaSources?.first?.id ?? itemID,
            positionTicks: ticks,
            isPaused: isPaused
        )
    }
    
    /// Gets video dimensions for window sizing
    static func getVideoDimensions(from item: BaseItemDto) -> (width: Int, height: Int) {
        // Prefer the first VIDEO stream for dimensions
        let videoStream = item.mediaSources?
            .first?
            .mediaStreams?
            .first(where: { $0.type == .video })

        let width = videoStream?.width ?? 1024
        let height = videoStream?.height ?? 576

        // Guard against invalid 0/negative sizes sometimes reported by non-video streams
        if width <= 0 || height <= 0 {
            return (1024, 576)
        }
        return (width, height)
    }
}
