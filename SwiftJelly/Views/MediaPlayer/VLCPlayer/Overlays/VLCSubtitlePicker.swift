import SwiftUI
import VLCUI

struct VLCSubtitlePicker: View {
    var subtitleManager: SubtitleManager
    var body: some View {
        Menu {
            ForEach(subtitleManager.options) { opt in
                Button {
                    subtitleManager.selectSubtitle(withId: opt.id)
                } label: {
                    if subtitleManager.selectedId == opt.id {
                        Label(opt.title, systemImage: "checkmark").labelStyle(.titleAndIcon)
                    } else {
                        Label(opt.title, systemImage: "captions.bubble").labelStyle(.titleOnly)
                    }
                }
            }
        } label: {
            Label("Subtitles", systemImage: "captions.bubble").imageScale(.large)
        }
        .labelStyle(.iconOnly)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
    }
}
