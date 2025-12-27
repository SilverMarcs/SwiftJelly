import SwiftUI
import JellyfinAPI

struct MovieHeroActions: View {
    let movie: BaseItemDto
    
    var body: some View {
        HStack(spacing: spacing) {
            MoviePlayButton(item: movie)
            
            MarkPlayedButton(item: movie)
            
            FavoriteButton(item: movie)
        }
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        15
        #elseif os(macOS)
        8
        #else
        4
        #endif
    }
}
