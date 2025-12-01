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
                        .padding(.leading, 80)
                        .padding(.top, 48)
                        .focusSection()
                }
                
                SimilarItemsView(item: movie)
                    .padding(.leading, 80)
                    .padding(.top, 48)
                    .padding(.bottom, 80)
                    .focusSection()
            }
        } itemDetailContent: {
            HStack(spacing: 16) {
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
}
