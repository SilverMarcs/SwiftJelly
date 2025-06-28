import Foundation
import JellyfinAPI
import Combine
import VLCUI

@MainActor
class ContinueWatchingPlayerViewModel: ObservableObject {
    @Published var playbackPosition: Int = 0
    @Published var duration: Int = 1
    @Published var isPlaying: Bool = false
    @Published var subtitleTracks: [MediaTrack] = []
    @Published var selectedSubtitleIndex: Int? = nil
    
    let item: BaseItemDto
    let server: Server
    let user: User
    let proxy: VLCVideoPlayer.Proxy = .init()
    private var updateTask: Task<Void, Never>?
    private var lastSentPosition: Int = 0
    
    init(item: BaseItemDto, server: Server, user: User) {
        self.item = item
        self.server = server
        self.user = user
    }
    
    func updatePlaybackPosition(_ seconds: Int) {
        playbackPosition = seconds
        // Only send update every 5 seconds or on stop
        if abs(seconds - lastSentPosition) >= 5 {
            lastSentPosition = seconds
            sendWatchTimeToServer(seconds: seconds)
        }
    }
    
    func sendWatchTimeToServer(seconds: Int) {
        // TODO: Implement actual API call to Jellyfin to update playstate
        // Use server.url, user.accessToken, item.id
    }
    
    func setSubtitleTracks(_ tracks: [MediaTrack]) {
        subtitleTracks = tracks
    }
    
    func selectSubtitle(index: Int) {
        selectedSubtitleIndex = index
        proxy.setSubtitleTrack(.absolute(index))
    }
}
