import SwiftUI
import JellyfinAPI
import VLCUI

struct MediaPlayerInfoBar: View {
    let item: BaseItemDto
    let proxy: VLCVideoPlayer.Proxy
    let playbackInfo: VLCVideoPlayer.PlaybackInformation?

    var body: some View {
        HStack {
            Text(item.name ?? "Unknown")
                .font(.title.bold())
                .lineLimit(1)
                .foregroundStyle(.white)
            
            Spacer()
            
            SubtitlePicker(proxy: proxy, tracks: playbackInfo?.subtitleTracks ?? [], selected: playbackInfo?.currentSubtitleTrack)
            
            AudioTrackPicker(proxy: proxy, tracks: playbackInfo?.audioTracks ?? [], selected: playbackInfo?.currentAudioTrack)
        }
    }
}

private struct SubtitlePicker: View {
    let proxy: VLCVideoPlayer.Proxy
    let tracks: [MediaTrack]
    let selected: MediaTrack?
    @State private var selectedIndex: Int = 0

    var body: some View {
        Picker(selection: $selectedIndex) {
            ForEach(tracks, id: \.index) { track in
                Text(track.title.isEmpty ? "Track \(track.index + 1)" : track.title).tag(track.index)
            }
        } label: {
            Label("Subtitles", systemImage: "captions.bubble")
        }
        .labelsHidden()
        .onAppear {
            if let selected = selected {
                selectedIndex = selected.index
            }
        }
        .onChange(of: selectedIndex) {
            proxy.setSubtitleTrack(.absolute(selectedIndex))
        }
    }
}

private struct AudioTrackPicker: View {
    let proxy: VLCVideoPlayer.Proxy
    let tracks: [MediaTrack]
    let selected: MediaTrack?
    @State private var selectedIndex: Int = 0

    var body: some View {
        Picker(selection: $selectedIndex) {
            ForEach(tracks, id: \.index) { track in
                Text(track.title.isEmpty ? "Track \(track.index + 1)" : track.title).tag(track.index)
            }
        } label: {
            Label("Audio", systemImage: "speaker.wave.2")
        }
        .labelsHidden()
        .onAppear {
            if let selected = selected {
                selectedIndex = selected.index
            }
        }
        .onChange(of: selectedIndex) {
            proxy.setAudioTrack(.absolute(selectedIndex))
        }
    }
}
