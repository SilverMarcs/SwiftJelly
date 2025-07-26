import SwiftUI
import VLCUI

struct VLCSubtitlePicker: View {
    var subtitleManager: SubtitleManager
    
    var body: some View {
        Menu {
            if subtitleManager.isLoading {
                Text("Loading subtitles...")
                    .foregroundStyle(.secondary)
            } else if subtitleManager.availableSubtitles.isEmpty {
                Text("No subtitles available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(subtitleManager.availableSubtitles, id: \.index) { subtitle in
                    Button {
                        subtitleManager.selectSubtitle(at: subtitle.index)
                    } label: {
                        if subtitleManager.selectedSubtitleIndex == subtitle.index {
                            Label(subtitle.title, systemImage: "checkmark")
                                .labelStyle(.titleAndIcon)
                        } else {
                            Label(subtitle.title, systemImage: "captions.bubble")
                                .labelStyle(.titleOnly)
                        }
                    }
                }
            }
        } label: {
            Label("Subtitles", systemImage: "captions.bubble")
                .imageScale(.large)
        }
        .labelStyle(.iconOnly)
        .menuIndicator(.hidden)
        .menuStyle(.button)
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}
