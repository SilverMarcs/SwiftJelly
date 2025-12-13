import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewIOS: View {
    let item: BaseItemDto
    
    @State private var nowPlaying: BaseItemDto
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var playbackToken = UUID()
    @State private var playbackEndObserver: NSObjectProtocol?
    @State private var isAutoLoadingNext = false
    
    init(item: BaseItemDto) {
        self.item = item
        _nowPlaying = State(initialValue: item)
    }

    var body: some View {
        Group {
            if let player = player {
                AVPlayerIos(player: player)
                    .task(id: player.timeControlStatus) {
                        await PlaybackUtilities.reportPlaybackProgress(player: player, item: nowPlaying)
                    }
            } else if isLoading {
                ProgressView()
                    .tint(.primary)
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task(id: playbackToken) {
                        await loadPlayer()
                    }
            }
        }
        .ignoresSafeArea()
        .onDisappear {
            Task {
                await cleanup()
            }
        }
        .overlay {
            if isAutoLoadingNext {
                ProgressView()
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func loadPlayer() async {
        do {
            let session = try await PlaybackUtilities.loadPlaybackInfo(for: nowPlaying)
            await MainActor.run {
                removePlaybackEndObserver()
                player = session.player
                isLoading = false
                registerEndObserver(for: session.player)
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func cleanup() async {
        removePlaybackEndObserver()
        guard let player = player else { return }
        await PlaybackUtilities.reportPlaybackAndCleanup(player: player, item: nowPlaying)
        await MainActor.run {
            self.player = nil
        }
    }

    private func registerEndObserver(for player: AVPlayer) {
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            handlePlaybackCompletion()
        }
    }

    private func removePlaybackEndObserver() {
        if let observer = playbackEndObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackEndObserver = nil
        }
    }

    private func handlePlaybackCompletion() {
        guard nowPlaying.type == .episode,
              !isAutoLoadingNext,
              let currentPlayer = player else {
            return
        }
        
        isAutoLoadingNext = true
        removePlaybackEndObserver()
        let finishedItem = nowPlaying

        Task {
            await PlaybackUtilities.reportPlaybackStop(player: currentPlayer, item: finishedItem)
            await MainActor.run {
                currentPlayer.replaceCurrentItem(with: nil)
            }
            
            let nextEpisode = try? await JFAPI.loadNextEpisode(after: finishedItem)
            
            await MainActor.run {
                defer { isAutoLoadingNext = false }
                guard let nextEpisode,
                      nextEpisode.id != finishedItem.id else {
                    return
                }
                
                nowPlaying = nextEpisode
                player = nil
                isLoading = true
                playbackToken = UUID()
            }
        }
    }
}
