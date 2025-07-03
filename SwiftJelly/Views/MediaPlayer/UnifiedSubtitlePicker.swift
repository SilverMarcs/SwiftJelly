import SwiftUI
import VLCUI

struct UnifiedSubtitlePicker: View {
    @ObservedObject var subtitleManager: SubtitleManager
    
    private var allSubtitles: [UnifiedSubtitle] {
        subtitleManager.availableSubtitles
    }
    
    var body: some View {
        Menu {
            if subtitleManager.isLoading {
                Text("Loading subtitles...")
                    .foregroundStyle(.secondary)
            } else if allSubtitles.count == 1 { // Only "None" option
                Text("No subtitles available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(allSubtitles, id: \.index) { subtitle in
                    Button {
                        subtitleManager.selectSubtitle(subtitle)
                    } label: {
                        HStack {
                            if subtitleManager.selectedSubtitle?.index == subtitle.index {
                                Label(subtitle.title, systemImage: "checkmark")
                            } else {
                                Text(subtitle.title)
                            }
                            
//                            if subtitle.isExternal {
//                                Text("(External)")
//                                    .foregroundStyle(.secondary)
//                                    .font(.caption)
//                            }
                            Text(subtitle.title)
                                
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
        .controlSize(.extraLarge)
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
    }
}
