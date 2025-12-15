import AVKit
import JellyfinAPI

private actor PlaybackSessionRegistry {
    private var contexts: [ObjectIdentifier: PlaybackSessionContext] = [:]
    
    func set(_ context: PlaybackSessionContext, for player: AVPlayer) {
        contexts[ObjectIdentifier(player)] = context
    }
    
    func context(for player: AVPlayer) -> PlaybackSessionContext? {
        contexts[ObjectIdentifier(player)]
    }
    
    func remove(for player: AVPlayer) -> PlaybackSessionContext? {
        contexts.removeValue(forKey: ObjectIdentifier(player))
    }
}

private struct PlaybackSessionContext: Sendable {
    let itemID: String
    let mediaSourceID: String?
    let playSessionID: String?
    let playMethod: String?
    let audioStreamIndex: Int?
    let subtitleStreamIndex: Int?
    let canSeek: Bool
}

struct PlaybackLoadResult {
    let player: AVPlayer
    let info: PlaybackInfoResponse
    let item: BaseItemDto
}

struct PlaybackUtilities {
    private static let sessionRegistry = PlaybackSessionRegistry()
    
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
        
        guard let itemID = item.id else {
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
        
        let context = PlaybackSessionContext(
            itemID: itemID,
            mediaSourceID: info.mediaSource.id,
            playSessionID: info.playSessionId,
            playMethod: info.playMethod.jellyfinValue?.rawValue,
            audioStreamIndex: audioStreamIndex,
            subtitleStreamIndex: subtitleStreamIndex,
            canSeek: (info.mediaSource.runTimeTicks ?? 0) > 0
        )
        await sessionRegistry.set(context, for: player)
        
        Task.detached {
            await JFAPI.reportPlaybackStart(
                itemID: context.itemID,
                mediaSourceID: context.mediaSourceID,
                playSessionID: context.playSessionID,
                playMethod: context.playMethod.flatMap(JellyfinAPI.PlayMethod.init(rawValue:)),
                audioStreamIndex: context.audioStreamIndex,
                subtitleStreamIndex: context.subtitleStreamIndex,
                canSeek: context.canSeek,
                positionTicks: resumeTicks
            )
        }
        
        return PlaybackLoadResult(player: player, info: info, item: latestItem)
    }
    
    /// Reports current playback progress to Jellyfin server
    static func reportPlaybackProgress(
        player: AVPlayer,
        item: BaseItemDto
    ) async {
        guard let itemID = item.id else { return }
        let ticks = player.currentTime().seconds.toPositionTicks
        let context = await sessionRegistry.context(for: player)
        await JFAPI.reportPlaybackProgress(
            itemID: itemID,
            mediaSourceID: context?.mediaSourceID ?? item.mediaSources?.first?.id ?? itemID,
            playSessionID: context?.playSessionID,
            playMethod: context?.playMethod.flatMap(JellyfinAPI.PlayMethod.init(rawValue:)),
            audioStreamIndex: context?.audioStreamIndex,
            subtitleStreamIndex: context?.subtitleStreamIndex,
            positionTicks: ticks,
            canSeek: context?.canSeek ?? true,
            isPaused: false
        )
    }
    
    /// Reports final playback progress and cleans up resources
    static func reportPlaybackAndCleanup(
        player: AVPlayer,
        item: BaseItemDto
    ) async {
        player.pause()
        
        await endPlaybackSession(player: player, item: item)
        
        player.replaceCurrentItem(with: nil)
        
        try? await Task.sleep(for: .milliseconds(100))
        if let handler = RefreshHandlerContainer.shared.refresh {
            await handler()
            RefreshHandlerContainer.shared.refresh = nil
        }
    }
    
    static func reportPlaybackStop(
        player: AVPlayer,
        item: BaseItemDto
    ) async {
        await endPlaybackSession(player: player, item: item)
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
    
    private static func endPlaybackSession(
        player: AVPlayer,
        item: BaseItemDto
    ) async {
        guard let itemID = item.id else { return }
        let ticks = player.currentTime().seconds.toPositionTicks
        if let context = await sessionRegistry.context(for: player) {
            await JFAPI.reportPlaybackProgress(
                itemID: itemID,
                mediaSourceID: context.mediaSourceID ?? item.mediaSources?.first?.id ?? itemID,
                playSessionID: context.playSessionID,
                playMethod: context.playMethod.flatMap(JellyfinAPI.PlayMethod.init(rawValue:)),
                audioStreamIndex: context.audioStreamIndex,
                subtitleStreamIndex: context.subtitleStreamIndex,
                positionTicks: ticks,
                canSeek: context.canSeek,
                isPaused: false
            )
            await JFAPI.reportPlaybackStopped(
                itemID: context.itemID,
                mediaSourceID: context.mediaSourceID,
                playSessionID: context.playSessionID,
                positionTicks: ticks
            )
            _ = await sessionRegistry.remove(for: player)
        } else {
            await JFAPI.reportPlaybackProgress(
                itemID: itemID,
                mediaSourceID: item.mediaSources?.first?.id ?? itemID,
                playSessionID: nil,
                playMethod: nil,
                audioStreamIndex: nil,
                subtitleStreamIndex: nil,
                positionTicks: ticks,
                canSeek: true,
                isPaused: false
            )
        }
    }
}

private extension PlaybackInfoResponse.PlayMethod {
    var jellyfinValue: JellyfinAPI.PlayMethod? {
        switch self {
        case .directPlay:
            return .directPlay
        case .transcode:
            return .transcode
        }
    }
}
