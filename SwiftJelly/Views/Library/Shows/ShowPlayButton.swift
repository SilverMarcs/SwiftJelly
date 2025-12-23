import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    var vm: ShowDetailViewModel
    
    var body: some View {
        animatedButton
    }
    
    private var animatedButton: some View {
        PlayMediaButton(item: vm.nextEpisode ?? BaseItemDto()) {
            ZStack {
                if vm.nextEpisode == nil {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.primary)
                            .controlSize(.mini)
                        Text("Loading…")
                    }
                    .transition(.opacity)
                    
                } else if let nextEpisode = vm.nextEpisode {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        
                        if let s = nextEpisode.parentIndexNumber, let e = nextEpisode.indexNumber {
                            Text("S\(s), E\(e)")
                        }
                        
                        if let progress = nextEpisode.playbackProgress, progress > 0, progress < 0.95 {
                            #if os(tvOS)
                            ProgressView(value: progress)
                                .tint(.primary)
                                .frame(width: 60)
                            #else
                            Gauge(value: progress) {
                                EmptyView()
                            } currentValueLabel: {
                                EmptyView()
                            } minimumValueLabel: {
                                EmptyView()
                            } maximumValueLabel: {
                                EmptyView()
                            }
                            .tint(.white)
                            .gaugeStyle(.accessoryLinearCapacity)
                            .controlSize(.mini)
                            .frame(width: 40)
                            #endif
                        }
                        
                        if let remaining = nextEpisode.timeRemainingString {
                            Text(remaining)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .font(.callout)
            .fontWeight(.semibold)
            .animation(.easeInOut(duration: 0.2), value: vm.nextEpisode?.id)
        }
        .tint(Color(.accent).secondary)
        .buttonBorderShape(.capsule)
        .buttonStyle(.glassProminent)
        .environment(\.refresh, vm.refreshAll)
        #if !os(tvOS)
        .controlSize(.extraLarge)
        .disabled(vm.playButtonDisabled)
        #else
        .opacity(vm.playButtonDisabled ? 0.5 : 1)
        #endif
    }
}
