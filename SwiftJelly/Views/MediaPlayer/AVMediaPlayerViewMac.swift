import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewMac: View {
    let item: BaseItemDto
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var showInfoSheet = false

    var body: some View {
        Group {
            if let player = player {
                AVPlayerMac(player: player)
                    .onChange(of: player.timeControlStatus) {
                        Task {
                            await PlaybackUtilities.reportPlaybackProgress(player: player, item: item)
                        }
                    }
            } else if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
            }
        }
        .ignoresSafeArea()
        .navigationTitle(item.seriesName ?? item.name ?? "Media Player")
        .navigationSubtitle(item.seasonEpisodeString ?? "")
        .windowFullScreenBehavior(.disabled)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .gesture(WindowDragGesture())
        .toolbar {
            Button {
                showInfoSheet = true
            } label: {
                Image(systemName: "info")
            }
        }
        .task {
            configureWindow()
            await loadPlaybackInfo()
        }
        .onDisappear {
            Task {
                await cleanup()
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            Form {
                Section {
                    Text(item.name ?? "Unknown")
                }

                if let overview = item.overview, !overview.isEmpty {
                    Section("Overview") { Text(overview) }
                }

                if let year = item.productionYear {
                    Section("Year") { Text(String(year)) }
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: 400)
        }
    }

    private func configureWindow() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "media-player-AppWindow-1" }) {
            let (videoWidth, videoHeight) = PlaybackUtilities.getVideoDimensions(from: item)
            
            window.aspectRatio = NSSize(width: videoWidth, height: videoHeight)
            
            let maxWidth: CGFloat = 1024
            let maxHeight: CGFloat = 576
            
            let widthRatio = maxWidth / CGFloat(videoWidth)
            let heightRatio = maxHeight / CGFloat(videoHeight)
            let scale = min(widthRatio, heightRatio, 1.0)
            
            let scaledWidth = CGFloat(videoWidth) * scale
            let scaledHeight = CGFloat(videoHeight) * scale
            
            window.setContentSize(NSSize(width: scaledWidth, height: scaledHeight))
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
