import SwiftUI
import JellyfinAPI

struct SearchView: View {
    @State var searchText: String = ""
    @State private var searchScope: SearchScope = .all
    @State private var mediaResults: [BaseItemDto] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        MediaGrid(items: filteredMediaResults, isLoading: isLoading)
            .navigationTitle("Search")
            .platformNavigationToolbar()
            .searchable(text: $searchText, placement: placement, prompt: "Search movies, shows, or people")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .searchScopes($searchScope) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            #if os(tvOS)
            .frame(maxWidth: .infinity, alignment: .leading)
            .focusSection()
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(800))
                    guard !Task.isCancelled else { return }
                    await performSearch(for: newValue)
                }
            }
            .onDisappear {
                searchTask?.cancel()
            }
            #else
            .onSubmit(of: .search) {
                Task {
                    await performSearch(for: searchText)
                }
            }
            #endif
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
    
    private func performSearch(for query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            mediaResults = []
            isLoading = false
            return
        }
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let content = JFAPI.searchMedia(query: trimmedQuery)
            async let persons = JFAPI.searchPersons(query: trimmedQuery)
            
            let (contentResults, personResults) = try await (content, persons)
            guard !Task.isCancelled else { return }
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
