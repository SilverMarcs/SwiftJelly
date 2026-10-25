import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewMac: View {
    @State private var playbackManager = PlaybackManager.shared
    @State private var showInfoSheet = false
    @State private var didConfigureWindow = false

    var body: some View {
        Group {
            if let model = playbackManager.viewModel, let error = model.errorDescription {
                PlaybackFailureView(message: error) { Task { await model.load() } }
            } else if let model = playbackManager.viewModel, let player = model.player {
                AVPlayerMac(player: player) {
                    MediaPlayerOverlayControls(model: model)
                }
            } else if let model = playbackManager.viewModel, model.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task(id: model.item.id) {
                        await model.load()
                    }
            }
        }
        .ignoresSafeArea()
        .navigationTitle(playbackManager.viewModel?.item.seriesName ?? playbackManager.viewModel?.item.name ?? "Media Player")
        .navigationSubtitle(navigationSubtitleText)
        .windowFullScreenBehavior(.disabled)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .gesture(WindowDragGesture())
        .inspector(isPresented: $showInfoSheet) {
            Form {
                Section {
                    Text(playbackManager.viewModel?.item.name ?? "Unknown")
                }

                if let overview = playbackManager.viewModel?.item.overview, !overview.isEmpty {
                    Section("Overview") { Text(overview) }
                }

                if let year = playbackManager.viewModel?.item.productionYear {
                    Section("Year") { Text(String(year)) }
                }
            }
            .formStyle(.grouped)
        }
        .toolbar {
            Button {
                showInfoSheet.toggle()
            } label: {
                Image(systemName: "info")
            }
        }
        .onAppear {
            if !didConfigureWindow {
                configureWindow()
                didConfigureWindow = true
            }
        }
        .task(id: playbackManager.viewModel?.item.id) {
            configureWindow()
        }
        .onDisappear {
            playbackManager.endPlayback()
        }
    }

    private var navigationSubtitleText: String {
        guard let item = playbackManager.viewModel?.item,
              let seasonEpisode = item.seasonEpisodeString else { return "" }
        if let name = item.name, !name.isEmpty {
            return "\(seasonEpisode) · \(name)"
        }
        return seasonEpisode
    }

    private func configureWindow() {
        guard let model = playbackManager.viewModel else { return }
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "media-player-AppWindow-1" }) {
            let (videoWidth, videoHeight) = model.item.videoDimensions

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
}
