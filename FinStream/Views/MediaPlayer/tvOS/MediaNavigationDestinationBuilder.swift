import SwiftUI
import JellyfinAPI

enum MediaNavigationDestinationBuilder {
    static func viewController(for item: BaseItemDto) -> UIViewController {
        let rootView = NavigationStack {
            MediaDestinationView(item: item)
                .navigationDestinations()
        }
        return UIHostingController(rootView: rootView)
    }
}
