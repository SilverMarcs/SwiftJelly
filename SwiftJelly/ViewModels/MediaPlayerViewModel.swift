import Foundation
import JellyfinAPI
import Combine
import VLCUI

class MediaPlayerViewModel: ObservableObject {
    @Published var playbackPosition: Int = 0
    @Published var duration: Int = 1
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var subtitleTracks: [MediaTrack] = []
    @Published var selectedSubtitleIndex: Int? = nil

    let item: BaseItemDto
    let server: Server
    let user: User
    let proxy: VLCVideoPlayer.Proxy = .init()
    private let api = JFAPI.shared
    private var updateTask: Task<Void, Never>?
    private var lastSentPosition: Int = 0

    init(item: BaseItemDto, server: Server, user: User) {
        self.item = item
        self.server = server
        self.user = user
    }

    func updatePlaybackPosition(_ seconds: Int) {
        playbackPosition = seconds
    }

    func setSubtitleTracks(_ tracks: [MediaTrack]) {
        subtitleTracks = tracks
    }

    func selectSubtitle(index: Int) {
        selectedSubtitleIndex = index
        proxy.setSubtitleTrack(.absolute(index))
    }
}
