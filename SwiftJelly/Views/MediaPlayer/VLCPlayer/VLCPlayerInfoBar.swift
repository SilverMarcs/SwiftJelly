import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerInfoBar: View {
    let item: BaseItemDto
    let proxy: VLCVideoPlayer.Proxy
    let playbackInfo: VLCVideoPlayer.PlaybackInformation?
    let subtitleManager: SubtitleManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unknown")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                if !subtitleManager.availableSubtitles.isEmpty {
                    VLCSubtitlePicker(subtitleManager: subtitleManager)
                }
                
//                Button {
//                    // Audio track picker
//                } label: {
//                    Image(systemName: "speaker.wave.2")
//                        .foregroundStyle(.white)
//                }
//                .buttonStyle(.glass)
            }
        }
        .padding(.vertical)
    }
}
