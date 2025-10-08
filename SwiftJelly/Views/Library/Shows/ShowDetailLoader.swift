import SwiftUI
import JellyfinAPI

struct ShowDetailLoader: View {
    let episode: BaseItemDto
    @State private var show: BaseItemDto?

    var body: some View {
        if let show = show {
            ShowDetailView(item: show)
        } else {
            UniversalProgressView()
                .task {
                    if let seriesId = episode.seriesID {
                        show = try? await JFAPI.loadItem(by: seriesId)
                    }
                }
        }
    }
}
