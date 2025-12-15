import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewMac: View {
    @State private var model: MediaPlaybackViewModel
    @State private var showInfoSheet = false
    @State private var didConfigureWindow = false

    init(item: BaseItemDto) {
        _model = State(initialValue: MediaPlaybackViewModel(item: item))
    }

    var body: some View {
        Group {
            if let player = model.player {
                AVPlayerMac(player: player) {
                    MediaPlayerOverlayControls(model: model)
                }
                .task(id: player.timeControlStatus) {
                    await PlaybackUtilities.reportPlaybackProgress(player: player, item: model.item)
                }
            } else if model.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task(id: model.playbackToken) {
                        await model.load()
                    }
            }
        }
        .ignoresSafeArea()
        .navigationTitle(model.item.seriesName ?? model.item.name ?? "Media Player")
        .navigationSubtitle(model.item.seasonEpisodeString ?? "")
        .windowFullScreenBehavior(.disabled)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .gesture(WindowDragGesture())
        .inspector(isPresented: $showInfoSheet) {
            Form {
                Section {
                    Text(model.item.name ?? "Unknown")
                }

                if let overview = model.item.overview, !overview.isEmpty {
                    Section("Overview") { Text(overview) }
                }

                if let year = model.item.productionYear {
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

            if model.audioTracks.count > 1 {
                Menu {
                    ForEach(model.audioTracks) { track in
                        Button(track.displayName) {
                            Task { await model.switchAudioTrack(to: track) }
                        }
                        .disabled(model.isSwitchingAudio || track == model.selectedAudioTrack)
                    }
                } label: {
                    Label("Audio", systemImage: "speaker.wave.2.fill")
                }
                .menuIndicator(.hidden)
            }
        }
        .onAppear {
            if !didConfigureWindow {
                configureWindow()
                didConfigureWindow = true
            }
        }
        .task(id: model.item.id) {
            configureWindow()
        }
        .onDisappear {
            Task { await model.cleanup() }
        }
    }

    private func configureWindow() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "media-player-AppWindow-1" }) {
            let (videoWidth, videoHeight) = PlaybackUtilities.getVideoDimensions(from: model.item)
            
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
