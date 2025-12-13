import SwiftUI
import JellyfinAPI

struct EpisodeDetailView: View {
    @State private var episode: BaseItemDto

    init(item: BaseItemDto) {
        self._episode = State(initialValue: item)
    }
    
    var body: some View {
        DetailView(item: episode) {
            if let people = episode.people {
                PeopleScrollView(people: people)
                    #if os(tvOS)
                    .focusSection()
                    #endif
            }
            
            SimilarItemsView(item: episode)
                #if os(tvOS)
                .focusSection()
                #endif
        } itemDetailContent: {
            HStack(spacing: spacing) {
                MovieOrEpisodePlayButton(item: episode)
                
                MarkPlayedButton(item: episode)
            }
        }
        .environment(\.refresh, fetchEpisode)
    }

    private func fetchEpisode() async {
        do {
            episode = try await JFAPI.loadItem(by: episode.id ?? "")
        } catch {
            print("Error loading Episode Detail: \(error.localizedDescription)")
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
