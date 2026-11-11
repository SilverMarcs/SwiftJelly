import AVFoundation
import JellyfinAPI
import OSLog

@MainActor
enum PlaybackPreparer {
    enum Mode { case automatic, original }
    private static let logger = Logger(subsystem: "com.SilverMarcs.SwiftJelly", category: "Playback")

    static func prepare(for item: BaseItemDto, preferredLanguage: String? = nil, audioIndex: Int? = nil, resumeSeconds: Double? = nil, context suppliedContext: JFAPI.APIContext? = nil, mode: Mode = .automatic) async throws -> PreparedPlayback {
        try Task.checkCancellation()
        guard let itemID = item.id else { throw PlaybackError.missingItemID }
        if let localURL = DownloadManager.shared.localFileURL(for: itemID) {
            let info = PlaybackInfoResponse(itemID: itemID, playbackURL: localURL, mediaSource: item.mediaSources?.first ?? MediaSourceInfo(), playMethod: .directPlay, playSessionId: nil)
            let asset = AVURLAsset(url: localURL)
            let selection = try await PlaybackMediaSelection.load(asset: asset, source: info.mediaSource)
            try Task.checkCancellation()
            return PreparedPlayback(item: item, info: info, playerItem: AVPlayerItem(asset: asset), selection: selection, context: suppliedContext ?? (try? JFAPI.getAPIContext()), resumeSeconds: resumeSeconds ?? Double(item.startTimeSeconds))
        }

        let context = try suppliedContext ?? JFAPI.getAPIContext()
        let latest: BaseItemDto
        do { latest = try await JFAPI.loadItem(by: itemID, fields: .MinimumFields + [.mediaSources, .mediaStreams], context: context) }
        catch is CancellationError { throw CancellationError() }
        catch { try Task.checkCancellation(); latest = item }
        try Task.checkCancellation()
        let source = latest.mediaSources?.first
        let streams = source?.mediaStreams ?? []
        let preferredIndex = audioIndex ?? streams.first(where: {
            guard $0.type == .audio, let language = $0.language, let preferredLanguage else { return false }
            return Locale.Language(identifier: language).minimalIdentifier == Locale.Language(identifier: preferredLanguage).minimalIdentifier
        })?.index ?? source?.defaultAudioStreamIndex
        let textCodecs: Set = ["ass", "ssa", "srt", "subrip", "text", "ttml", "mov_text", "vtt", "webvtt"]
        let subtitleIndex = streams.first(where: { $0.type == .subtitle && textCodecs.contains($0.codec?.lowercased() ?? "") })?.index
        let info = try await JFAPI.getPlaybackInfo(for: latest, subtitleStreamIndex: subtitleIndex, audioStreamIndex: preferredIndex, mediaSourceID: source?.id, context: context)
        let effectiveAudioIndex = audioIndex ?? info.mediaSource.mediaStreams?.first(where: {
            guard $0.type == .audio, let language = $0.language, let preferredLanguage else { return false }
            return Locale.Language(identifier: language).minimalIdentifier == Locale.Language(identifier: preferredLanguage).minimalIdentifier
        })?.index ?? preferredIndex ?? info.mediaSource.defaultAudioStreamIndex
        var encodingIDs = info.playSessionId.map { [$0] } ?? []
        var adapter: LocalHLSAdapter?
        do {
            let originalAsset = AVURLAsset(url: info.playbackURL)
            let originalSelection = try await PlaybackMediaSelection.load(asset: originalAsset, source: info.mediaSource)
            try Task.checkCancellation()
            let tracks = PlaybackAudioTrack.tracks(from: info)
            let needsAudio = tracks.count > (originalSelection.audioGroup?.options.count ?? 0) && tracks.count > 1
            let originalQuery = URLComponents(url: info.playbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let usesFragments = originalQuery.contains { $0.name.lowercased() == "segmentcontainer" && $0.value?.lowercased() == "mp4" }
            let hasSubtitles = info.mediaSource.mediaStreams?.contains(where: { $0.type == .subtitle }) == true
            let needsSubtitleCompatibility = info.playbackURL.pathExtension.lowercased() == "m3u8" && usesFragments && hasSubtitles
            if mode == .original || (!needsAudio && !needsSubtitleCompatibility) {
                return PreparedPlayback(item: latest, info: info, playerItem: AVPlayerItem(asset: originalAsset), selection: originalSelection, context: context, encodingSessionIDs: encodingIDs, resumeSeconds: resumeSeconds ?? Double(latest.startTimeSeconds), initialAudioIndex: effectiveAudioIndex)
            }

            do {
                let selectedIndex = effectiveAudioIndex ?? tracks.first?.index
                let rootSessionID = info.playSessionId ?? UUID().uuidString
                if !encodingIDs.contains(rootSessionID) { encodingIDs.append(rootSessionID) }
                let masterURL = needsAudio
                    ? try JellyfinPlaybackPolicy.hlsURL(context: context, info: info, sessionID: rootSessionID, audioIndex: selectedIndex, subtitleIndex: subtitleIndex)
                    : info.playbackURL
                let (master, resolvedURL) = try await LocalHLSAdapter.fetchText(from: masterURL)
                let renditions = needsAudio ? tracks.map { track in
                    HLSAudioRendition(streamIndex: track.index, name: tracks.count(where: { $0.displayName == track.displayName }) > 1 ? "\(track.displayName) · \(track.details) · \(track.index)" : track.displayName, language: track.languageCode.map { Locale.Language(identifier: $0).minimalIdentifier }, channels: min(JellyfinPlaybackPolicy.maxAudioChannels, max(1, info.mediaSource.mediaStreams?.first(where: { $0.index == track.index })?.channels ?? 2)), playSessionID: "\(rootSessionID)-audio-\(track.index)")
                } : []
                encodingIDs += renditions.map(\.playSessionID)
                let subtitles = HLSManifest.subtitlePlaylists(in: master, sourceURL: resolvedURL)
                let paths = Dictionary(subtitles.map { ($0.value, $0.key) }, uniquingKeysWith: { first, _ in first })
                let manifest = try HLSManifest.make(master: master, sourceURL: resolvedURL, renditions: renditions, selectedIndex: selectedIndex ?? -1, subtitlePlaylistPaths: paths)
                let local = try LocalHLSAdapter(manifest: manifest, subtitlePlaylists: subtitles, subtitleTimestamp: 0)
                adapter = local
                let localURL = try await local.start()
                let asset = AVURLAsset(url: localURL)
                let selection = try await PlaybackMediaSelection.load(asset: asset, source: info.mediaSource)
                if needsAudio && selection.audioIndices.count != tracks.count { throw URLError(.cannotParseResponse) }
                try Task.checkCancellation()
                let playerItem = AVPlayerItem(asset: asset)
                let adaptedInfo = PlaybackInfoResponse(itemID: itemID, playbackURL: masterURL, mediaSource: info.mediaSource, playMethod: needsAudio ? .transcode : info.playMethod, playSessionId: rootSessionID)
                return PreparedPlayback(item: latest, info: adaptedInfo, playerItem: playerItem, selection: selection, context: context, adapter: local, encodingSessionIDs: encodingIDs, resumeSeconds: resumeSeconds ?? Double(latest.startTimeSeconds), initialAudioIndex: selectedIndex, outcome: .adapted)
            } catch {
                adapter?.stop()
                try Task.checkCancellation()
                logger.notice("Native media preparation failed; using original stream. Error: \(String(describing: type(of: error)), privacy: .public)")
                return PreparedPlayback(item: latest, info: info, playerItem: AVPlayerItem(asset: originalAsset), selection: originalSelection, context: context, encodingSessionIDs: encodingIDs, resumeSeconds: resumeSeconds ?? Double(latest.startTimeSeconds), initialAudioIndex: effectiveAudioIndex, outcome: .fallback("Some media options are unavailable for this video."))
            }
        } catch {
            adapter?.stop()
            Task { await JFAPI.stopPlaybackEncodings(context: context, sessionIDs: encodingIDs) }
            throw error
        }
    }
}
