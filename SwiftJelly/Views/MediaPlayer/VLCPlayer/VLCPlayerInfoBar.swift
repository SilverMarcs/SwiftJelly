import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerInfoBar: View {
    let proxy: VLCVideoPlayer.Proxy
    let subtitleManager: SubtitleManager
    
    var body: some View {
        HStack {
            Spacer()
            if !subtitleManager.availableSubtitles.isEmpty {
                VLCSubtitlePicker(subtitleManager: subtitleManager)
            }
        }
        .padding(.vertical)
    }
}
