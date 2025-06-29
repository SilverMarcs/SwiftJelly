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
        // Only send update every 5 seconds or on stop
        if abs(seconds - lastSentPosition) >= 5 {
            lastSentPosition = seconds
            sendWatchTimeToServer(seconds: seconds)
        }
    }

    func sendWatchTimeToServer(seconds: Int) {
        Task {
            do {
                let positionTicks = Int64(seconds * 10_000_000) // Convert seconds to ticks (1 second = 10,000,000 ticks)
                try await api.reportPlaybackProgress(
                    for: item,
                    positionTicks: positionTicks,
                    isPaused: !isPlaying
                )
            } catch {
                print("Error reporting playback progress: \(error)")
//                handleError(error)
            }
        }
    }

    func reportPlaybackStopped() {
        Task {
            do {
                let positionTicks = Int64(playbackPosition * 10_000_000)
                try await api.reportPlaybackStopped(for: item, positionTicks: positionTicks)
            } catch {
                print("Error reporting playback stopped: \(error)")
//                handleError(error)
            }
        }
    }

    func setSubtitleTracks(_ tracks: [MediaTrack]) {
        subtitleTracks = tracks
    }

    func selectSubtitle(index: Int) {
        selectedSubtitleIndex = index
        proxy.setSubtitleTrack(.absolute(index))
    }
}
