import Foundation
import JellyfinAPI
import VLCUI

@Observable class SubtitleManager {
    var availableSubtitles: [SubtitleTrack] = []
    var selectedSubtitleIndex: Int = -1
    
    private let vlcProxy: VLCVideoPlayer.Proxy
    private var serverSubtitles: [MediaStream] = []
    private var embeddedSubtitles: [MediaTrack] = []
    private var hasLoadedServerSubtitles = false
    private var currentMediaItem: MediaItem?
    
    init(vlcProxy: VLCVideoPlayer.Proxy) {
        self.vlcProxy = vlcProxy
    }
    
    func loadServerSubtitles(from mediaItem: MediaItem) {
        guard !hasLoadedServerSubtitles else { return }
        hasLoadedServerSubtitles = true
        currentMediaItem = mediaItem
        
        switch mediaItem {
        case .jellyfin(let item):
            guard let mediaSource = item.mediaSources?.first,
                  let mediaStreams = mediaSource.mediaStreams else { return }
            
            // Filter for text subtitles only (exclude embedded bitmap subs)
            serverSubtitles = mediaStreams.filter { stream in
                stream.type == .subtitle || stream.isTextSubtitleStream == true
            }
            
            // Add server subtitles to VLC as playback children immediately
            addServerSubtitlesToVLC()
            
        case .local:
            // Local files don't have server subtitles
            break
        }
        
        updateAvailableSubtitles()
    }
    
    func loadSubtitlesFromVLC(tracks: [MediaTrack]) {
        embeddedSubtitles = tracks.filter { !$0.title.lowercased().contains("forced") }
        updateAvailableSubtitles()
    }
    
    private func updateAvailableSubtitles() {
        var combinedSubtitles: [SubtitleTrack] = []
        
        // Add embedded subtitles first 
        for (offset, embeddedTrack) in embeddedSubtitles.enumerated() {
            combinedSubtitles.append(SubtitleTrack(
                index: offset, // VLC embedded tracks start at 0
                title: embeddedTrack.title,
                isServerSubtitle: false,
                serverStream: nil
            ))
        }
        
        // Add server subtitles after embedded ones
        for (offset, serverStream) in serverSubtitles.enumerated() {
            let serverTrackIndex = embeddedSubtitles.count + offset
            let title = createServerSubtitleTitle(from: serverStream)
            
            combinedSubtitles.append(SubtitleTrack(
                index: serverTrackIndex,
                title: title,
                isServerSubtitle: true,
                serverStream: serverStream
            ))
        }
        
        availableSubtitles = combinedSubtitles
        
        // Auto-select default subtitle if available
        selectDefaultSubtitle()
    }
    
    private func selectDefaultSubtitle() {
        // Don't auto-select if user has already made a selection
        guard selectedSubtitleIndex == -1 else { return }
        
        // Look for default server subtitle first
        for track in availableSubtitles {
            if track.isServerSubtitle, let serverStream = track.serverStream, serverStream.isDefault == true {
                selectedSubtitleIndex = track.index
                selectSubtitle(at: track.index)
                return
            }
        }
        
        // If no server default, check embedded defaults
        for track in availableSubtitles {
            if !track.isServerSubtitle && track.title.lowercased().contains("default") {
                selectedSubtitleIndex = track.index
                selectSubtitle(at: track.index)
                return
            }
        }
    }
    
    private func createServerSubtitleTitle(from stream: MediaStream) -> String {
        var title = "Server"
        
        if let language = stream.language {
            title += " - \(language)"
        }
        
        if let displayTitle = stream.displayTitle {
            title = displayTitle
        } else if let streamTitle = stream.title {
            title = streamTitle
        }
        
        if stream.isForced == true {
            title += " (Forced)"
        }
        
        if stream.isDefault == true {
            title += " (Default)"
        }
        
        return title
    }
    
    private func addServerSubtitlesToVLC() {
        for serverStream in serverSubtitles {
            if let playbackChild = createPlaybackChild(from: serverStream) {
                print("Adding server subtitle: \(serverStream.displayTitle ?? "Unknown") - URL: \(playbackChild.url)")
                vlcProxy.addPlaybackChild(playbackChild)
            } else {
                print("Failed to create playback child for server subtitle: \(serverStream.displayTitle ?? "Unknown")")
                print("  - deliveryURL: \(serverStream.deliveryURL ?? "nil")")
                print("  - index: \(serverStream.index ?? -1)")
                print("  - isExternal: \(serverStream.isExternal ?? false)")
            }
        }
    }
    
    private func createPlaybackChild(from stream: MediaStream) -> VLCVideoPlayer.PlaybackChild? {
        // Get the current API context to build the full URL
        guard let apiContext = try? JFAPI.getAPIContext() else {
            print("Failed to get API context for server subtitle")
            return nil
        }
        
        let fullURL: URL
        
        if let deliveryURL = stream.deliveryURL {
            // Use delivery URL if available
            let cleanPath = deliveryURL.hasPrefix("/") ? String(deliveryURL.dropFirst()) : deliveryURL
            guard let url = URL(string: cleanPath, relativeTo: apiContext.server.url) else {
                print("Failed to create URL from deliveryURL: \(cleanPath)")
                return nil
            }
            fullURL = url
        } else {
            // Construct subtitle URL manually for server-stored subtitles
            guard let mediaItemId = getMediaItemId(),
                  let mediaSourceId = getMediaSourceId(),
                  let streamIndex = stream.index else {
                print("Missing required parameters for subtitle URL construction:")
                print("  - mediaItemId: \(getMediaItemId() ?? "nil")")
                print("  - mediaSourceId: \(getMediaSourceId() ?? "nil")")
                print("  - streamIndex: \(stream.index ?? -1)")
                return nil
            }
            
            // Default format for server subtitles
            let format = "vtt" // WebVTT format is widely supported
            
            let subtitlePath = "/Videos/\(mediaItemId)/\(mediaSourceId)/Subtitles/\(streamIndex)/Stream.\(format)"
            print("Constructing subtitle URL: \(subtitlePath)")
            
            guard let url = URL(string: subtitlePath, relativeTo: apiContext.server.url) else {
                print("Failed to construct subtitle URL: \(subtitlePath)")
                return nil
            }
            fullURL = url
        }
        
        return VLCVideoPlayer.PlaybackChild(
            url: fullURL,
            type: .subtitle,
            enforce: false
        )
    }
    
    private func getMediaItemId() -> String? {
        // Extract from the current media item
        guard let mediaItem = currentMediaItem else { return nil }
        switch mediaItem {
        case .jellyfin(let item):
            return item.id
        case .local:
            return nil
        }
    }
    
    private func getMediaSourceId() -> String? {
        // Extract from the current media item's media source
        guard let mediaItem = currentMediaItem else { return nil }
        switch mediaItem {
        case .jellyfin(let item):
            return item.mediaSources?.first?.id
        case .local:
            return nil
        }
    }
    
    func selectSubtitle(at index: Int) {
        selectedSubtitleIndex = index
        
        guard index < availableSubtitles.count else { return }
        let selectedTrack = availableSubtitles[index]
        
        print("Selecting subtitle: \(selectedTrack.title) (index: \(index), isServer: \(selectedTrack.isServerSubtitle))")
        
        if index == -1 {
            // Disable all subtitles - VLC handles this automatically
            vlcProxy.setSubtitleTrack(.absolute(-1))
        } else if selectedTrack.isServerSubtitle {
            // Server subtitle: VLC should have embedded tracks + server tracks
            // Server tracks come after embedded tracks in VLC's track list
            let vlcTrackIndex = embeddedSubtitles.count + (selectedTrack.index - embeddedSubtitles.count)
            print("Setting VLC server subtitle track to index: \(vlcTrackIndex)")
            vlcProxy.setSubtitleTrack(.absolute(vlcTrackIndex))
        } else {
            // Embedded subtitle: use VLC's embedded track index directly
            print("Setting VLC embedded subtitle track to index: \(selectedTrack.index)")
            vlcProxy.setSubtitleTrack(.absolute(selectedTrack.index))
        }
    }
}

struct SubtitleTrack {
    let index: Int
    let title: String
    let isServerSubtitle: Bool
    let serverStream: MediaStream?
}
