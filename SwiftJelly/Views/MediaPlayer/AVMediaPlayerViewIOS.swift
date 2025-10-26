import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewIOS: View {
    @Environment(\.scenePhase) var scenePhase
    
    let item: BaseItemDto
    @State private var player: AVPlayer?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let player = player {
                AVPlayerIos(player: player)
            } else if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
            }
        }
        .ignoresSafeArea()
        .task {
            OrientationManager.shared.lockOrientation(.landscape, andRotateTo: .landscapeRight)
            await loadPlaybackInfo()
        }
        .onDisappear {
            OrientationManager.shared.lockOrientation(.all)
            Task {
                await cleanup()
            }
        }
    }

    private func loadPlaybackInfo() async {
        do {
            let player = try await PlaybackUtilities.loadPlaybackInfo(for: item)
            self.player = player
            self.isLoading = false
        } catch {
            self.isLoading = false
        }
    }

    private func cleanup() async {
        guard let player = player else { return }
        await PlaybackUtilities.reportPlaybackAndCleanup(player: player, item: item)
        self.player = nil
    }
}
