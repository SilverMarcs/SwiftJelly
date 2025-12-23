import SwiftUI
import JellyfinAPI

struct MoviePlayButton: View {
    let item: BaseItemDto

    var body: some View {
        PlayMediaButton(item: item) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                
                if item.userData?.isPlayed == true {
                    Text("Play Again")
                } else if let progress = item.playbackProgress, progress > 0, progress < 1 {
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
                    
                    if let remaining = item.timeRemainingString {
                        Text(remaining)
                    }
                } else {
                    Text("Play")
                }
            }
            .font(.callout)
            .fontWeight(.semibold)
        }
        .animation(.default, value: item.userData?.isPlayed)
        #if os(tvOS)
        .tint(Color(.accent).secondary)
        .controlSize(.regular)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        #else
        .tint(Color(.accent).secondary)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .buttonStyle(.glassProminent)
        #endif
    }
}
