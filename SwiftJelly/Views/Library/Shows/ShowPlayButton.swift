import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    var vm: ShowDetailViewModel
    
    var body: some View {
        HStack {
            animatedButton
            MarkPlayedButton(item: vm.selectedSeason ?? BaseItemDto())
            FavoriteButton(item: vm.show)
        }
    }
    
    private var animatedButton: some View {
        PlayMediaButton(item: vm.nextEpisode ?? BaseItemDto()) {
            ZStack {
                if vm.nextEpisode == nil {
                    HStack(spacing: 8) { ProgressView().controlSize(.mini); Text("Loading…").font(.caption) }
                        .transition(.opacity)
                    
                } else if let nextEpisode = vm.nextEpisode {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        if let s = nextEpisode.parentIndexNumber, let e = nextEpisode.indexNumber { Text("S\(s)E\(e)").font(.caption) }
                        if let progress = nextEpisode.playbackProgress, progress > 0, progress < 0.95 {
                            Gauge(value: progress) { EmptyView() } currentValueLabel: { EmptyView() } minimumValueLabel: { EmptyView() } maximumValueLabel: { EmptyView() }
                                .tint(.white)
                                .gaugeStyle(.accessoryLinearCapacity)
                                .controlSize(.mini)
                                .frame(width: 40)
                        }
                        if let remaining = nextEpisode.timeRemainingString { Text(remaining).font(.caption) }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: vm.nextEpisode?.id)
        }
        .tint(Color(.accent).secondary)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .buttonStyle(.glassProminent)
        .environment(\.refresh, vm.refreshAll)
    }
}

