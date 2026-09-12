import AVKit
import JellyfinAPI

struct PlaybackLoadResult {
    let player: AVPlayer
    let info: PlaybackInfoResponse
    let item: BaseItemDto
}

struct PlaybackUtilities {
    /// Keeps the diagnostics observers alive for the item currently loaded.
    @MainActor private static var activeDiagnostics: PlaybackItemDiagnostics?

    /// Loads playback information and creates an AVPlayer
    static func loadPlaybackInfo(
        for item: BaseItemDto,
        into existingPlayer: AVPlayer? = nil,
        audioStreamIndex: Int? = nil,
        resumeSeconds: Double? = nil
    ) async throws -> PlaybackLoadResult {
        PlaybackLog.log("loadPlaybackInfo item=\(item.name ?? "?") id=\(item.id ?? "nil") type=\(item.type?.rawValue ?? "nil") "
            + "audioStreamIndex=\(audioStreamIndex.map(String.init) ?? "nil") "
            + "resumeSeconds=\(resumeSeconds.map { String(Int($0)) } ?? "nil")")
        if let source = item.mediaSources?.first {
            PlaybackLog.log("Source as known before playback info: \(PlaybackLog.describe(mediaSource: source))")
        }

        // Offline path: play from local file if a completed download exists.
        if let localURL: URL = await MainActor.run(body: {
            guard let id = item.id else { return nil as URL? }
            return DownloadManager.shared.localFileURL(for: id)
        }) {
            return try await loadLocalPlayback(
                for: item,
                fileURL: localURL,
                existingPlayer: existingPlayer,
                resumeSeconds: resumeSeconds
            )
        }

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
        #if DEBUG
        if !subtitleStreams.isEmpty {
            let streamDescriptions = subtitleStreams.map { stream in
                let index = stream.index.map(String.init) ?? "nil"
                let codec = stream.codec ?? "nil"
                let language = stream.language ?? "nil"
                let title = stream.displayTitle ?? "nil"
                return "index=\(index) codec=\(codec) lang=\(language) title=\(title)"
            }
            // print(
                // "Playback subtitle streams for item \(itemForPlayback.id ?? "unknown"): \(streamDescriptions.joined(separator: " | "))"
            // )
        } else {
            // print("Playback subtitle streams for item \(itemForPlayback.id ?? "unknown"): none")
        }
        // print("Selected subtitle stream index: \(subtitleStreamIndex.map(String.init) ?? "nil")")
        #endif

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
                #if DEBUG
                print("Retrying playback info with subtitle stream index: \(streamIndex)")
                #endif
                info = try await JFAPI.getPlaybackInfo(
                    for: itemForPlayback,
                    subtitleStreamIndex: streamIndex,
                    audioStreamIndex: audioStreamIndex,
                    startPositionTicks: resumeTicks,
                    mediaSourceID: initialInfo.mediaSource.id
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
        
        let player = existingPlayer ?? AVPlayer()
        player.pause()
        player.replaceCurrentItem(with: playerItem)
        attachDiagnostics(player: player, playerItem: playerItem, label: latestItem.name ?? latestItem.id ?? "item")

        #if !os(macOS)
        // Set externalMetadata AFTER replaceCurrentItem so AVPlayerViewController
        // observes it as a change on the currentItem.
        let metadata = await latestItem.createMetadataItems()
        playerItem.externalMetadata = metadata
        #endif

        player.automaticallyWaitsToMinimizeStalling = true
        playerItem.preferredForwardBufferDuration = 30
        
        #if os(macOS)
        player.preventsDisplaySleepDuringVideoPlayback = true
        #endif
        
        // Prefer start time from freshly fetched item (to avoid stale progress)
        let fallbackStartSeconds = Double(latestItem.startTimeSeconds)
        let targetStartSeconds = resumeSeconds ?? fallbackStartSeconds
        let time = CMTime(seconds: targetStartSeconds, preferredTimescale: 1)
        await player.seek(to: time)
        
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        player.play()

        return PlaybackLoadResult(player: player, info: info, item: latestItem)
    }
    
    private static func loadLocalPlayback(
        for item: BaseItemDto,
        fileURL: URL,
        existingPlayer: AVPlayer?,
        resumeSeconds: Double?
    ) async throws -> PlaybackLoadResult {
        let playerItem = AVPlayerItem(url: fileURL)

        PlaybackLog.log("Playing local downloaded file for \(item.name ?? "?"): \(fileURL.lastPathComponent)")

        let player = existingPlayer ?? AVPlayer()
        player.pause()
        player.replaceCurrentItem(with: playerItem)
        attachDiagnostics(player: player, playerItem: playerItem, label: (item.name ?? "item") + " [local]")

        #if !os(macOS)
        // Set externalMetadata AFTER replaceCurrentItem so AVPlayerViewController
        // observes it as a change on the currentItem.
        let metadata = await item.createMetadataItems()
        playerItem.externalMetadata = metadata
        #endif

        player.automaticallyWaitsToMinimizeStalling = true
        playerItem.preferredForwardBufferDuration = 30

        let fallbackStartSeconds = Double(item.startTimeSeconds)
        let targetStartSeconds = resumeSeconds ?? fallbackStartSeconds
        await player.seek(to: CMTime(seconds: targetStartSeconds, preferredTimescale: 1))

        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        player.play()

        let mediaSource = item.mediaSources?.first ?? MediaSourceInfo()
        let info = PlaybackInfoResponse(
            playbackURL: fileURL,
            mediaSource: mediaSource,
            playMethod: .directPlay,
            playSessionId: nil
        )
        return PlaybackLoadResult(player: player, info: info, item: item)
    }

    @MainActor
    private static func attachDiagnostics(player: AVPlayer, playerItem: AVPlayerItem, label: String) {
        activeDiagnostics = PlaybackItemDiagnostics(player: player, playerItem: playerItem, label: label)
        logAssetTracks(for: playerItem, label: label)
    }

    /// Asynchronously reports what AVFoundation actually managed to load from
    /// the asset. A playable asset with no video track is the classic cause of
    /// a blank/black video plane on tvOS.
    private static func logAssetTracks(for playerItem: AVPlayerItem, label: String) {
        let asset = playerItem.asset
        Task.detached {
            do {
                let isPlayable = try await asset.load(.isPlayable)
                let duration = try await asset.load(.duration)
                let tracks = try await asset.load(.tracks)
                let descriptions = try await withThrowingTaskGroup(of: String.self) { group -> [String] in
                    for track in tracks {
                        group.addTask {
                            let formats = try await track.load(.formatDescriptions)
                            let codecs = formats.map { format in
                                let code = CMFormatDescriptionGetMediaSubType(format)
                                return String(bytes: [
                                    UInt8((code >> 24) & 0xFF),
                                    UInt8((code >> 16) & 0xFF),
                                    UInt8((code >> 8) & 0xFF),
                                    UInt8(code & 0xFF)
                                ], encoding: .ascii) ?? "\(code)"
                            }
                            let isTrackPlayable = try await track.load(.isPlayable)
                            let size = try await track.load(.naturalSize)
                            return "{media=\(track.mediaType.rawValue) id=\(track.trackID) playable=\(isTrackPlayable) "
                                + "codecs=\(codecs.joined(separator: ",")) size=\(Int(size.width))x\(Int(size.height))}"
                        }
                    }
                    var results: [String] = []
                    for try await description in group { results.append(description) }
                    return results
                }

                let hasVideo = tracks.contains { $0.mediaType == .video }
                PlaybackLog.log("[\(label)] asset playable=\(isPlayable) duration=\(duration.seconds) "
                    + "tracks=\(descriptions.isEmpty ? "none" : descriptions.joined(separator: " | "))")
                if !hasVideo {
                    PlaybackLog.error("[\(label)] asset has NO video track — this is why the video plane stays blank")
                }
            } catch {
                PlaybackLog.error("[\(label)] failed to load asset properties: \(PlaybackLog.describe(error: error))")
            }
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
