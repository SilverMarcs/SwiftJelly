import SwiftUI
import JellyfinAPI

struct ShowDetailLoader: View {
    let episode: BaseItemDto
    @State private var show: BaseItemDto?

    var body: some View {
        if let show = show {
            ShowDetailView(item: show)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .task {
                    if let seriesId = episode.seriesID {
                        show = try? await JFAPI.loadItem(by: seriesId)
                    }
                }
        }
    }
}
