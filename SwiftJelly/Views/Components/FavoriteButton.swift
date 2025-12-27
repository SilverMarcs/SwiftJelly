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
                .fontWeight(.medium)
                .animation(.snappy, value: item.userData?.isFavorite)
    
        }
        .tint((item.userData?.isFavorite == true) ? .yellow : .primary)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .scaleEffect(0.97)
        #if os(tvOS)
        .controlSize(.regular)
        #else
        .controlSize(.extraLarge)
        #endif
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
