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
        let subtitleStreamIndex = item.mediaSources?
            .first?
            .mediaStreams?
            .first(where: { $0.type == .subtitle })?
            .index

        // Start fetching playback info and a fresh item concurrently
        let resumeTicks: Int64? = {
            guard let resumeSeconds else { return nil }
            return Int64(resumeSeconds * 10_000_000)
        }()
        
        async let infoTask = JFAPI.getPlaybackInfo(
            for: item,
            subtitleStreamIndex: subtitleStreamIndex,
            audioStreamIndex: audioStreamIndex,
            startPositionTicks: resumeTicks
        )
        async let freshItemTask: BaseItemDto? = {
            guard let id = item.id else { return nil }
            return try? await JFAPI.loadItem(by: id)
        }()

        let info = try await infoTask
        
        guard item.id != nil else {
            throw PlaybackError.missingItemID
        }

        let latestItem = await freshItemTask ?? item

        let playerItem = AVPlayerItem(url: info.playbackURL)
        
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
