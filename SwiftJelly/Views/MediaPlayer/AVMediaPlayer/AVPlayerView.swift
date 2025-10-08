import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let item: BaseItemDto
    @State private var player: AVPlayer?
    @State private var timeObserverToken: Any?
    @State private var isLoading = true
    @State private var showInfoSheet = false

    var body: some View {
        Group {
            if isLoading {
                UniversalProgressView()
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task { await loadPlaybackInfo() }
            } else if let player {
                PlatformPlayerContainer(player: player)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle(item.name ?? "Media Player")
        .toolbar {
            Button {
                showInfoSheet = true
            } label: {
                Image(systemName: "info")
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
        .onDisappear {
            #if !os(macOS)
            OrientationManager.shared.lockOrientation(.all)
            #endif
            cleanup()
        }
        .onAppear {
            #if !os(macOS)
            OrientationManager.shared.lockOrientation(.landscape, andRotateTo: .landscapeRight)
            #endif
        }
    }

    private func loadPlaybackInfo() async {
        do {
            let item = self.item
            let subtitleStreamIndex = item.mediaSources?
                .first?
                .mediaStreams?
                .first(where: { $0.type == .subtitle })?
                .index

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

            // report every 5s
            self.timeObserverToken = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 5, preferredTimescale: 1),
                queue: .main
            ) { time in
                let seconds = Int(time.seconds)
                Task {
                    try? await JFAPI.reportPlaybackProgress(
                        for: item,
                        positionTicks: seconds.toPositionTicks
                    )
                }
            }

            // initial progress
            Task {
                try? await JFAPI.reportPlaybackProgress(
                    for: item,
                    positionTicks: item.startTimeSeconds.toPositionTicks
                )
            }
        } catch {
            self.isLoading = false
        }
    }

    private func cleanup() {
        guard let player = player else { return }
        player.pause()

        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }

        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if let handler = RefreshHandlerContainer.shared.refresh {
                await handler()
            }
        }
    }
}
