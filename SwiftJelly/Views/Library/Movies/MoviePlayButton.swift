import SwiftUI
import JellyfinAPI

struct MoviePlayButton: View {
    let item: BaseItemDto

    var body: some View {
        HStack(spacing: 12) {
            PlayMediaButton(item: item) {
                HStack(spacing: 8) {
                    if item.userData?.isPlayed == true {
                        Image(systemName: "play.fill")
                        
                        Text("Play Again")
                            .font(.caption)
                        
                    } else if let progress = item.playbackProgress, progress > 0, progress < 1 {
                        Image(systemName: "play.fill")
                        
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
                        
                        if let remaining = item.timeRemainingString {
                            Text(remaining)
                                .font(.caption)
                        }
                    } else {
                        Image(systemName: "play.fill")
                        
                        Text("Play")
                            .font(.caption)
                    }
                }
            }
            .tint(Color(.accent).secondary)
            .buttonBorderShape(.capsule)
            .controlSize(.extraLarge)
            .buttonStyle(.glassProminent)
            
            MarkPlayedButton(item: item)
        }
    }
}
