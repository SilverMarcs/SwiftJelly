import SwiftUI
import JellyfinAPI

struct MoviePlayButton: View {
    let item: BaseItemDto
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    @State private var showPlayer = false

    private var progress: Double? {
        guard let ticks = item.userData?.playbackPositionTicks, let runtime = item.runTimeTicks, runtime > 0 else { return nil }
        let percent = Double(ticks) / Double(runtime)
        return percent > 1 ? 1 : percent
    }
    
    private var timeRemaining: String? {
        guard let ticks = item.userData?.playbackPositionTicks, let runtime = item.runTimeTicks, runtime > 0, ticks < runtime else { return nil }
        let seconds = (runtime - ticks) / 10_000_000
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(seconds))
    }

    var body: some View {
        Button {
            #if os(macOS)
            openWindow(id: "media-player", value: item)
            #else
            showPlayer = true
            #endif
        } label: {
            HStack(spacing: 8) {
                if item.userData?.isPlayed == true {
                    Image(systemName: "play.fill")
                        .imageScale(.large)
                    
                    Text("Play Again")
                        .font(.subheadline)
                    
                } else if let progress = progress, progress > 0, progress < 1 {
                    Image(systemName: "play.fill")
                        .imageScale(.large)
                    
                    ProgressView(value: progress)
                        .controlSize(.mini)
                        .frame(width: 40)
                    
                    if let remaining = timeRemaining {
                        Text(remaining)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "play.fill")
                        .imageScale(.large)
                    
                    Text("Play")
                        .font(.subheadline)
                }
            }
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .tint(.white)
        #if !os(macOS)
        .fullScreenCover(isPresented: $showPlayer) {
            MediaPlayerView(item: item)
        }
        #endif
    }
}
