import SwiftUI
import JellyfinAPI

struct RecentlyAddedView: View {
    let items: [BaseItemDto]
    var header: String
    
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(header)")
                    .font(.title2)
                    .bold()
                    .scenePadding(.leading)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items, id: \.id) { item in
                            NavigationLink {
                                switch item.type {
                                case .movie:
                                    MovieDetailView(item: item)
                                case .series:
                                    ShowDetailView(item: item)
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
}
