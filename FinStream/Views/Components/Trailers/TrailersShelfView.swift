#if !os(tvOS)
import SwiftUI
import JellyfinAPI

struct TrailersShelfView: View {
    let item: BaseItemDto

    @State private var selected: Trailer?

    var body: some View {
        let trailers = item.trailers

        SectionContainer(isVisible: !trailers.isEmpty) {
            HorizontalShelf(spacing: 12) {
                ForEach(trailers) { trailer in
                    Button {
                        selected = trailer
                    } label: {
                        TrailerCard(trailer: trailer)
                    }
                    .adaptiveCardButtonStyle()
                }
            }
        } header: {
            Text("Trailers")
        }
        .sheet(item: $selected) { trailer in
            TrailerSheetView(trailer: trailer)
        }
    }
}
#endif
