import SwiftUI
import VLCUI

struct VLCPlayerProgressBar: View {
    var playbackState: PlaybackStateManager
    let proxy: VLCVideoPlayer.Proxy
    
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(timeString(from: playbackState.currentSeconds))
                    .font(.caption)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                
                Spacer()
                
                Text(timeString(from: playbackState.totalDuration))
                    .font(.caption)
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            
            Slider(
                value: isDragging ? $dragProgress : .constant(playbackState.currentProgress),
                in: 0...1,
                onEditingChanged: { editing in
                    if editing {
                        isDragging = true
                        dragProgress = playbackState.currentProgress
                    } else {
                        let newSeconds = Int(dragProgress * Double(playbackState.totalDuration))
                        proxy.setTime(.seconds(newSeconds))
                        isDragging = false
                    }
                }
            )
            .tint(.white)
            .accentColor(.white)
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
