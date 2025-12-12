import SwiftUI
import JellyfinAPI

struct SearchView: View {
    @State var searchText: String = ""
    @State private var searchScope: SearchScope = .all
    @State private var results: [BaseItemDto] = []
    @State private var isLoading = false
    
    var body: some View {
        MediaGrid(items: filteredResults, isLoading: isLoading)
            .contentMargins(.vertical, 10)
            .navigationTitle("Search")
            .searchable(text: $searchText, placement: placement, prompt: "Search movies or shows")
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
            #if os(tvOS)
            .toolbar(.hidden, for: .navigationBar)
            #else
            .toolbarTitleDisplayMode(.inlineLarge)
            #endif
    }
    
    private var filteredResults: [BaseItemDto] {
        switch searchScope {
        case .all:
            return results
        case .movies:
            return results.filter { $0.type == .movie }
        case .shows:
            return results.filter { $0.type == .series }
        }
    }
    
    private func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let items = try await JFAPI.searchMedia(query: searchText)
            results = items
        } catch {
            results = []
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
    var id: String { rawValue }
}
