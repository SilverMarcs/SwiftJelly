import SwiftUI
import JellyfinAPI

struct FavoriteButton: View {
    let item: BaseItemDto
    @Environment(\.refresh) private var refresh
    
    var body: some View {
        Button {
            Task {
                await toggleFavoriteStatus()
            }
        } label: {
            Image(systemName: (item.userData?.isFavorite == true) ? "star.fill" : "star")
                .animation(.snappy, value: item.userData?.isFavorite)
        }
        #if os(tvOS)
        .controlSize(.extraLarge)
//        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        #endif
        #if os(macOS)
        .controlSize(.extraLarge)
        #elseif !os(tvOS)
        .controlSize(.large)
        #endif
        .buttonStyle(.glass)
        .tint((item.userData?.isFavorite == true) ? .yellow : .secondary)
    }
    
    private func toggleFavoriteStatus() async {
        do {
            try await JFAPI.toggleItemFavoriteStatus(item: item)
            await refresh()
        } catch {
            print("Error toggling favorite status: \(error)")
        }
    }
}
