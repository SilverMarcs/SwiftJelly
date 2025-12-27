import SwiftUI
import JellyfinAPI

struct SearchView: View {
    @State var searchText: String = ""
    @State private var searchScope: SearchScope = .all
    @State private var mediaResults: [BaseItemDto] = []
    @State private var isLoading = false
    
    var body: some View {
        MediaGrid(items: filteredMediaResults, isLoading: isLoading)
            #if os(tvOS)
            .focusSection()
            #endif
            .navigationTitle("Search")
            .searchable(text: $searchText, placement: placement, prompt: "Search movies, shows, or people")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .searchScopes($searchScope) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .onSubmit(of: .search) {
                Task {
                    await performSearch()
                }
            }
            .onChange(of: searchText) { _, newValue in
                Task {
                    await performSearch()
                    try? await Task.sleep(for: .seconds(0.5))
                    if !newValue.isEmpty && newValue == searchText {
                        await performSearch()
                    }
                }
            }
            .platformNavigationToolbar()
    }
    private var filteredMediaResults: [BaseItemDto] {
        switch searchScope {
        case .all:
            return mediaResults
        case .movies:
            return mediaResults.filter { $0.type == .movie }
        case .shows:
            return mediaResults.filter { $0.type == .series }
        case .people:
            return mediaResults.filter { $0.type == .person }
        }
    }
    
    private func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let content = JFAPI.searchMedia(query: searchText)
            async let persons = JFAPI.searchPersons(query: searchText)
            
            let (contentResults, personResults) = try await (content, persons)
            mediaResults = contentResults + personResults
        } catch {
            print("Error Searching: \(error.localizedDescription)")
        }
    }
    
    private var placement: SearchFieldPlacement {
        #if os(tvOS)
        .automatic
        #else
        .toolbarPrincipal
        #endif
    }
}

enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case movies = "Movies"
    case shows = "Shows"
    case people = "People"
    var id: String { rawValue }
}
