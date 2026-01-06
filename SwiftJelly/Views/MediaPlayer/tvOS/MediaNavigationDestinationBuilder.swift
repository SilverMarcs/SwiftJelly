import SwiftUI
import JellyfinAPI

enum MediaNavigationDestinationBuilder {
    static func viewController(for item: BaseItemDto) -> UIViewController {
        let rootView = NavigationStack {
            destinationView(for: item)
                .navigationDestinations()
        }
        return UIHostingController(rootView: rootView)
    }

    @ViewBuilder
    private static func destinationView(for item: BaseItemDto) -> some View {
        switch item.type {
        case .movie:
            MovieDetailView(item: item)
        case .series:
            ShowDetailView(item: item)
        case .episode:
            ShowDetailView(item: BaseItemDto(id: item.seriesID))
        case .person:
            FilteredMediaView(filter: .person(id: item.id ?? "", name: item.name ?? "Person"))
        case .collectionFolder, .boxSet:
            FilteredMediaView(filter: .library(item))
        default:
            ContentUnavailableView(
                "Unsupported Media Type",
                systemImage: "questionmark.circle",
                description: Text("Cannot display \(item.type?.rawValue.capitalized ?? "unknown") items")
            )
        }
    }
}
