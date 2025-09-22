import Foundation
import JellyfinAPI
import VLCUI

struct SubtitleOption: Identifiable, Equatable {
    // Use VLC’s index or id so we set the exact same thing back.
    let id: Int      // VLC index or unique trackId from VLCUI’s MediaTrack
    let title: String
}

// SubtitleManager.swift
@Observable final class SubtitleManager {
    private let vlcProxy: VLCVideoPlayer.Proxy

    // UI state
    var options: [SubtitleOption] = []
    var selectedId: Int? = nil

    // One-time
    private(set) var initialized = false

    // Policy state
    private var decidedSource = false
    private var usingEmbedded = false
    private var usingServer = false
    private var requestedServerOnce = false

    // Jellyfin
    private var jellyfinStreams: [MediaStream] = []
    private var currentMediaItem: MediaItem?

    init(vlcProxy: VLCVideoPlayer.Proxy) {
        self.vlcProxy = vlcProxy
    }

    func primeServerStreams(from mediaItem: MediaItem) {
        currentMediaItem = mediaItem
        guard case .jellyfin(let item) = mediaItem,
              let mediaStreams = item.mediaSources?.first?.mediaStreams else { return }
        jellyfinStreams = mediaStreams.filter { s in
            (s.type == .subtitle || s.isTextSubtitleStream == true)
        }
    }

    // Call this exactly once, when VLC first exposes tracks
    func initializeIfNeeded(with tracks: [MediaTrack]) {
        guard !initialized else { return }

        // Filter usable text tracks (adjust predicate as needed)
        let textTracks = tracks.filter { t in
            !t.title.lowercased().contains("forced")
        }

        // Decide source once
        if !decidedSource {
            if !textTracks.isEmpty {
                usingEmbedded = true
            } else {
                usingEmbedded = false
                if !requestedServerOnce {
                    requestedServerOnce = true
                    addServerSubtitlesIfNeeded()
                    // After adding server subs, VLC will surface them as tracks;
                    // If you truly never get another update, you can also prebuild options
                    // from jellyfinStreams, but typically one more frame has updated tracks.
                }
                usingServer = true
            }
            decidedSource = true
        }

        // Build options from what VLC shows now (embedded or server—if they’re already visible)
        let visibleTextTracks = textTracks
        options = visibleTextTracks.map { t in
            SubtitleOption(id: t.index, title: t.title)
        }

        // Auto-select once
        if selectedId == nil, !options.isEmpty {
            if let defaultTrack = options.first(where: { $0.title.lowercased().contains("default") }) {
                selectSubtitle(withId: defaultTrack.id)
            } else if options.count > 1 { // skip "None"
                selectSubtitle(withId: options[1].id)
            }
        }

        initialized = true
    }

    private func addServerSubtitlesIfNeeded() {
        guard !jellyfinStreams.isEmpty else { return }
        for s in jellyfinStreams {
            if let child = createPlaybackChild(from: s) {
                vlcProxy.addPlaybackChild(child)
            }
        }
    }

    private func createPlaybackChild(from stream: MediaStream) -> VLCVideoPlayer.PlaybackChild? {
        guard let api = try? JFAPI.getAPIContext() else { return nil }
        if let deliveryURL = stream.deliveryURL {
            let clean = deliveryURL.hasPrefix("/") ? String(deliveryURL.dropFirst()) : deliveryURL
            guard let url = URL(string: clean, relativeTo: api.server.url) else { return nil }
            return .init(url: url, type: .subtitle, enforce: false)
        } else {
            guard let itemId = (currentMediaItem.flatMap {
                if case .jellyfin(let item) = $0 { return item.id }
                return nil
            }),
            let sourceId = (currentMediaItem.flatMap {
                if case .jellyfin(let item) = $0 { return item.mediaSources?.first?.id }
                return nil
            }),
            let index = stream.index else { return nil }
            let format = "vtt"
            let path = "/Videos/\(itemId)/\(sourceId)/Subtitles/\(index)/Stream.\(format)"
            guard let url = URL(string: path, relativeTo: api.server.url) else { return nil }
            return .init(url: url, type: .subtitle, enforce: false)
        }
    }

    func selectSubtitle(withId id: Int?) {
        selectedId = id
        vlcProxy.setSubtitleTrack(.absolute(id ?? -1))
    }
}
