import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    let vm: ShowDetailViewModel
    
    var body: some View {
        PlayMediaButton(item: vm.nextEpisode ?? BaseItemDto()) {
            ZStack {
                if vm.nextEpisode == nil {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.primary)
                            .controlSize(.mini)

                        Text("Loading…")
                    }
                    #if os(macOS)
                    .padding(.vertical, 0.5)
                    #endif
                    .transition(.opacity)
                    
                } else if let nextEpisode = vm.nextEpisode {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")

                        if let seasonEpisodeString = nextEpisode.seasonEpisodeString {
                            Text(seasonEpisodeString)
                        }
                        
                        if let progress = nextEpisode.playbackProgress, progress > 0, progress < 0.95 {
                            ProgressView(value: progress)
                            .tint(.primary)
                            #if os(tvOS)
                            .frame(width: 60)
                            #else
                            .controlSize(.mini)
                            .frame(width: 40)
                            #endif
                            
                            if let remaining = nextEpisode.timeRemainingString {
                                Text(remaining)
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .font(.callout)
            .fontWeight(.semibold)
        }
        .tint(Color(.accent).secondary)
        .buttonBorderShape(.capsule)
        #if os(tvOS)
        .controlSize(.regular)
        #else
        .controlSize(.extraLarge)
        #endif
        .buttonStyle(.glassProminent)
        .environment(\.refresh, vm.refreshAll)
        .adaptiveDisabled(vm.playButtonDisabled)
    }
}
