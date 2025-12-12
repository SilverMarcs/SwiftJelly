import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

struct MovieDetailView: View {
    @State private var movie: BaseItemDto

    init(item: BaseItemDto) {
        self._movie = State(initialValue: item)
    }
    
    var body: some View {
        DetailView(item: movie, action: {}) {
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
                
                FavoriteButton(item: movie)
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
