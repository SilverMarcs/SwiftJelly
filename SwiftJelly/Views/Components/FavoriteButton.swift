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
        .tint((item.userData?.isFavorite == true) ? .yellow : .primary)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.extraLarge)
        .scaleEffect(0.97)
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
