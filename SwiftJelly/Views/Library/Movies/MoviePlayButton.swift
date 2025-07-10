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
                            .imageScale(.large)
                        
                        Text("Play Again")
                            .font(.subheadline)
                        
                    } else if let progress = item.playbackProgress, progress > 0, progress < 1 {
                        Image(systemName: "play.fill")
                            .imageScale(.large)
                        
                        ProgressView(value: progress)
                            .controlSize(.mini)
                            .frame(width: 40)
                        
                        if let remaining = item.timeRemainingString {
                            Text(remaining)
                                .font(.subheadline)
                        }
                    } else {
                        Image(systemName: "play.fill")
                            .imageScale(.large)
                        
                        Text("Play")
                            .font(.subheadline)
                    }
                }
            }
            .buttonBorderShape(.capsule)
            .controlSize(.extraLarge)
            .buttonStyle(.glass)
            
            MarkPlayedButton(item: item)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.extraLarge)
        }
    }
}
