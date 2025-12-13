import SwiftUI
import JellyfinAPI

struct MovieOrEpisodeDetailView: View {
    @State private var item: BaseItemDto

    init(item: BaseItemDto) {
        self._item = State(initialValue: item)
    }
    
    var body: some View {
        DetailView(item: item) {
            if let people = item.people {
                PeopleScrollView(people: people)
                    #if os(tvOS)
                    .focusSection()
                    #endif
            }
            
            SimilarItemsView(item: item)
                #if os(tvOS)
                .focusSection()
                #endif
        } itemDetailContent: {
            HStack(spacing: spacing) {
                MovieOrEpisodePlayButton(item: item)
                
                MarkPlayedButton(item: item)
                
                if item.type != .episode {
                    FavoriteButton(item: item)
                }
            }
        }
//        .navigationTitle(movie.name ?? "")
        .environment(\.refresh, fetchMovie)
    }

    private func fetchMovie() async {
        do {
            item = try await JFAPI.loadItem(by: item.id ?? "")
        } catch {
            print("Error loading Movie Detail: \(error.localizedDescription)")
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
