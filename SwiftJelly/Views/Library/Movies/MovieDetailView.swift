import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

struct MovieDetailView: View {
    @State private var movie: BaseItemDto
    
#if os(tvOS)
    private var spacing: CGFloat = 15
#else
    private var spacing: CGFloat = 4
#endif

    init(item: BaseItemDto) {
        self._movie = State(initialValue: item)
    }
    
    var body: some View {
        DetailView(item: movie, action: fetchMovie) {
            VStack {
                if let people = movie.people {
                    PeopleScrollView(people: people)
                        #if os(tvOS)
                        .focusSection()
                        #endif
                }
                
                SimilarItemsView(item: movie)
                    #if os(tvOS)
                    .focusSection()
                    #endif
            }
        } itemDetailContent: {
            HStack(spacing: spacing) {
                MoviePlayButton(item: movie)
                    .environment(\.refresh, fetchMovie)
                MarkPlayedButton(item: movie)
                
                #if os(tvOS)
                FavoriteButton(item: movie)
                #endif
            }
        }
    }

    private func fetchMovie() async {
        do {
            movie = try await JFAPI.loadItem(by: movie.id ?? "")
        } catch {
            print("Error loading Movie Detail: \(error.localizedDescription)")
        }
    }
}
