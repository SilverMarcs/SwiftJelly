import SwiftUI
import VLCUI

struct SubtitlePicker: View {
    @ObservedObject var subtitleManager: SubtitleManager
    
    private var allSubtitles: [Subtitle] {
        subtitleManager.availableSubtitles
    }
    
    var body: some View {
        Menu {
            if subtitleManager.isLoading {
                Text("Loading subtitles...")
                    .foregroundStyle(.secondary)
            } else if allSubtitles.isEmpty {
                Text("No subtitles available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(allSubtitles, id: \.index) { subtitle in
                    Button {
                        subtitleManager.selectSubtitle(subtitle)
                    } label: {
                        if subtitleManager.selectedSubtitle?.index == subtitle.index {
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
                .foregroundStyle(.secondary)
        }
        .labelStyle(.iconOnly)
        .menuIndicator(.hidden)
        .menuStyle(.button)
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
    }
}
