import SwiftUI
import JellyfinAPI

struct LatestMediaView: View {
    let items: [BaseItemDto]
    var header: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest \(header)")
                .font(.title2)
                .bold()
                .scenePadding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items, id: \.id) { item in
                        NavigationLink {
                            switch item.type {
                            case .movie:
                                MovieDetailView(movie: item)
                            case .series:
                                ShowDetailView(show: item)
                            default:
                                Text("Unsupported item type")
                            }
                        } label: {
                            MediaCard(item: item)
                                .frame(width: 150)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
