import AVKit
import JellyfinAPI

struct PlaybackUtilities {
    
    /// Loads playback information and creates an AVPlayer
    static func loadPlaybackInfo(for item: BaseItemDto) async throws -> AVPlayer {
        let subtitleStreamIndex = item.mediaSources?
            .first?
            .mediaStreams?
            .first(where: { $0.type == .subtitle })?
            .index

        // Start fetching playback info and fresh item concurrently
        async let infoTask = JFAPI.getPlaybackInfo(
            for: item,
            subtitleStreamIndex: subtitleStreamIndex
        )
        async let freshItemTask: BaseItemDto? = {
            guard let id = item.id else { return nil }
            return try? await JFAPI.loadItem(by: id)
        }()

        let info = try await infoTask

        let playerItem = AVPlayerItem(url: info.playbackURL)
        
        #if !os(macOS)
        let metadata = await item.createMetadataItems()
        playerItem.externalMetadata = metadata
        #endif
        
        let player = AVPlayer(playerItem: playerItem)
        
        #if os(macOS)
        player.preventsDisplaySleepDuringVideoPlayback = true
        #endif
        
        // Prefer start time from freshly fetched item (to avoid stale progress)
        let latestItem = await freshItemTask
        let startSeconds = latestItem?.startTimeSeconds ?? item.startTimeSeconds
        let time = CMTime(seconds: Double(startSeconds), preferredTimescale: 1)
        await player.seek(to: time)
        
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        
        player.play()
        
        return player
    }
    
    /// Reports current playback progress to Jellyfin server
    static func reportPlaybackProgress(
        player: AVPlayer,
        item: BaseItemDto
    ) async {
        let currentTime = player.currentTime()
        let seconds = Int(currentTime.seconds)
        
        try? await JFAPI.reportPlaybackProgress(
            for: item,
            positionTicks: seconds.toPositionTicks
        )
    }
    
    /// Reports final playback progress and cleans up resources
    static func reportPlaybackAndCleanup(
        player: AVPlayer,
        item: BaseItemDto
    ) async {
        player.pause()
        
        await reportPlaybackProgress(player: player, item: item)
        
        player.replaceCurrentItem(with: nil)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        if let handler = RefreshHandlerContainer.shared.refresh {
            await handler()
            RefreshHandlerContainer.shared.refresh = nil
        }
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
