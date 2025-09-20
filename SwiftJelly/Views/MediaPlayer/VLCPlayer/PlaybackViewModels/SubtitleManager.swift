import Foundation
import JellyfinAPI
import VLCUI

struct SubtitleOption: Identifiable, Equatable {
    // Use VLC’s index or id so we set the exact same thing back.
    let id: Int      // VLC index or unique trackId from VLCUI’s MediaTrack
    let title: String
}

@Observable final class SubtitleManager {
    private let vlcProxy: VLCVideoPlayer.Proxy
    
    // UI state
    var options: [SubtitleOption] = []
    var selectedId: Int? = nil
    
    // Policy state
    private var decidedSource = false
    private var usingEmbedded = false
    private var usingServer = false
    private var requestedServerOnce = false
    
    // Keep Jellyfin streams around to build PlaybackChildren if needed
    private var jellyfinStreams: [MediaStream] = []
    private var currentMediaItem: MediaItem?
    
    init(vlcProxy: VLCVideoPlayer.Proxy) {
        self.vlcProxy = vlcProxy
    }
    
    func primeServerStreams(from mediaItem: MediaItem) {
        currentMediaItem = mediaItem
        guard case .jellyfin(let item) = mediaItem,
              let mediaStreams = item.mediaSources?.first?.mediaStreams else { return }
        
        // Keep only textual subs; ignore bitmap/PGS/teletext etc.
        jellyfinStreams = mediaStreams.filter { s in
            (s.type == .subtitle || s.isTextSubtitleStream == true)
        }
    }
    
    // Called on every onSecondsUpdated with info.subtitleTracks
    func onVLCTracksUpdated(_ tracks: [MediaTrack]) {
        // Filter to usable text tracks; guard against “Track 1/2” placeholders where type/codec isn’t text
        let textTracks = tracks.filter { t in
            // Prefer: t.isText or t.codec in ["subrip", "webvtt", "ssa", "ass"]
            // Fallback: filter out “forced” by name if that’s policy
            !t.title.lowercased().contains("forced")
        }
        
        // Decide once which source we use
        if !decidedSource {
            if !textTracks.isEmpty {
                usingEmbedded = true
                decidedSource = true
            } else {
                usingEmbedded = false
                decidedSource = true
                // Ask to add server subs if available; only once
                if !requestedServerOnce {
                    requestedServerOnce = true
                    addServerSubtitlesIfNeeded()
                }
            }
        }
        
        // If we decided to use embedded, show embedded-only list
        // If we decided to use server, we still rebuild from VLC’s tracks after adding playback children
        if (usingEmbedded && !textTracks.isEmpty) || usingServer {
            options = textTracks.map { t in
                SubtitleOption(id: t.index, title: t.title)
            }

            // Auto-select previously selected or default track
            if selectedId == nil {
                if let defaultTrack = options.first(where: { $0.title.lowercased().contains("default") }) {
                    selectSubtitle(withId: defaultTrack.id)
                } else if options.count > 1 { // first actual track (skip None)
                    selectSubtitle(withId: options[1].id)
                }
            }
        }
    }
    
    private func addServerSubtitlesIfNeeded() {
        guard !jellyfinStreams.isEmpty else { return }
        usingServer = true
        
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
