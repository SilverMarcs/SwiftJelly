import SwiftUI
import JellyfinAPI
import VLCUI

struct MediaPlayerInfoBar: View {
    let item: BaseItemDto
    let proxy: VLCVideoPlayer.Proxy
    let playbackInfo: VLCVideoPlayer.PlaybackInformation?
    @ObservedObject var subtitleManager: SubtitleManager

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    if let season = item.parentIndexNumber, let episode = item.indexNumber {
                        Text("S\(season)E\(episode)")
                        
                        Text("•")
                    }
                    
                    if let showName = item.seriesName, !showName.isEmpty {
                        Text(showName)
                            .lineLimit(1)
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

                Text(item.name ?? "Unknown")
                    .font(.title.bold())
                    .lineLimit(1)
            }
            
            Spacer()
            
            SubtitlePicker(subtitleManager: subtitleManager)
            
//            AudioTrackPicker(proxy: proxy, tracks: playbackInfo?.audioTracks ?? [], selected: playbackInfo?.currentAudioTrack)
        }
    }
}
