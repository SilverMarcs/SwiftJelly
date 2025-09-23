import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    let show: BaseItemDto
    
    @State private var nextEpisode: BaseItemDto? = nil
    @State private var isLoading = true
    
    var body: some View {
        HStack {
            animatedButton
            MarkPlayedButton(item: nextEpisode ?? BaseItemDto())
            FavoriteButton(item: nextEpisode ?? BaseItemDto())
        }
        .task {
            await refreshNextEpisode()
        }
    }
    
    private var animatedButton: some View {
        PlayMediaButton(item: nextEpisode ?? BaseItemDto()) {
            ZStack {
                // Loading content
                HStack(spacing: 8) {
                    ProgressView().controlSize(.mini)
                    Text("Loading…").font(.caption)
                }
                .opacity(isLoading || nextEpisode == nil ? 1 : 0)
                
                // Play content
                Group {
                    if let nextEpisode {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            if let s = nextEpisode.parentIndexNumber, let e = nextEpisode.indexNumber {
                                Text("S\(s)E\(e)").font(.caption)
                            }
                            if let progress = nextEpisode.playbackProgress, progress > 0, progress < 0.95 {
                                Gauge(value: progress) { EmptyView() } currentValueLabel: { EmptyView() } minimumValueLabel: { EmptyView() } maximumValueLabel: { EmptyView() }
                                    .tint(.white)
                                    .gaugeStyle(.accessoryLinearCapacity)
                                    .controlSize(.mini)
                                    .frame(width: 40)
                            }
                            if let remaining = nextEpisode.timeRemainingString {
                                Text(remaining).font(.caption)
                            }
                        }
                    }
                }
                .opacity(isLoading || nextEpisode == nil ? 0 : 1)
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
            .animation(.easeInOut(duration: 0.2), value: nextEpisode?.id)
        }
        .tint(Color(.accent).secondary)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .buttonStyle(.glassProminent)
    }
}

// MARK: - Loading / Selection

private extension ShowPlayButton {
    func refreshNextEpisode() async {
        isLoading = true
        defer { isLoading = false }
        
        nextEpisode = nil
        let episode = await JFAPI.loadNextEpisode(for: show)
        nextEpisode = episode
    }
}
