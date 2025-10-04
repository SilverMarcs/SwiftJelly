import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let item: BaseItemDto
    @State private var player: AVPlayer?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                UniversalProgressView()
                .background(.black, ignoresSafeAreaEdges: .all)
                .frame(width: 1024, height: 576)
            } else if let player = player {
                #if os(macOS)
                AVPlayerMac(player: player)
                    .ignoresSafeArea()
                    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                    .aspectRatio(16/9, contentMode: .fit)
                    .gesture(WindowDragGesture())
                    .navigationTitle(item.name ?? "Media Player")
                    .onDisappear {
                        cleanup()
                    }
                #else
                AVPlayerIos(player: player)
                    .ignoresSafeArea()
                    .onDisappear {
                        cleanup()
                        OrientationManager.shared.lockOrientation(.all)
                    }
                    .onAppear {
                        OrientationManager.shared.lockOrientation(.landscape, andRotateTo: .landscapeRight)
                    }
                #endif
            }
        }
        .task {
            await loadPlaybackInfo()
        }
    }

    private func loadPlaybackInfo() async {
        do {
            let item = self.item
            // Get first available subtitle stream index to make subtitles available in player
            let subtitleStreamIndex = item.mediaSources?.first?.mediaStreams?.first(where: { $0.type == .subtitle })?.index
            
            // Request playback info with device profile for AVPlayer compatibility
            let info = try await JFAPI.getPlaybackInfo(
                for: item,
                subtitleStreamIndex: subtitleStreamIndex
            )
        
            let player = AVPlayer(url: info.playbackURL)
            self.player = player
            self.isLoading = false
            
            let time = CMTime(seconds: Double(item.startTimeSeconds), preferredTimescale: 1)
            await player.seek(to: time)
            player.play()
            
            // Send start progress
            Task {
                try? await JFAPI.reportPlaybackProgress(for: item, positionTicks: item.startTimeSeconds.toPositionTicks)
            }
        } catch {
            self.isLoading = false
        }
    }
    
    private func cleanup() {
        guard let player = player else { return }
        guard let time = player.currentItem?.currentTime() else { return }

        let seconds = Int(time.seconds)
        
        // Send stop progress
        Task {
            try? await JFAPI.reportPlaybackProgress(for: item, positionTicks: seconds.toPositionTicks)
        }
        
        player.pause()
        
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if let handler = RefreshHandlerContainer.shared.refresh {
                await handler()
            }
        }
    }
}
