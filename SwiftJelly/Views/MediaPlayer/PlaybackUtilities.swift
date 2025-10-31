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

        let info = try await JFAPI.getPlaybackInfo(
            for: item,
            subtitleStreamIndex: subtitleStreamIndex
        )

        let playerItem = AVPlayerItem(url: info.playbackURL)
        
        #if !os(macOS)
        let metadata = await item.createMetadataItems()
        playerItem.externalMetadata = metadata
        #endif
        
        let player = AVPlayer(playerItem: playerItem)
        
        #if os(macOS)
        player.preventsDisplaySleepDuringVideoPlayback = true
        #endif
        
        let time = CMTime(seconds: Double(item.startTimeSeconds), preferredTimescale: 1)
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
        }
    }
    
    /// Gets video dimensions for window sizing
    static func getVideoDimensions(from item: BaseItemDto) -> (width: Int, height: Int) {
        let width = item.mediaSources?.first?.mediaStreams?.first?.width ?? 1024
        let height = item.mediaSources?.first?.mediaStreams?.first?.height ?? 576
        return (width, height)
    }
}
