import SwiftUI
import JellyfinAPI

struct SearchView: View {
    enum SearchScope: String, CaseIterable, Identifiable {
        case all = "All"
        case movies = "Movies"
        case shows = "Shows"
        var id: String { rawValue }
    }
    
    @State private var query: String = ""
    @State private var searchScope: SearchScope = .all
    @State private var results: [BaseItemDto] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            MediaGrid(items: filteredResults, isLoading: isLoading)
                .navigationTitle("Search")
                .toolbarTitleDisplayMode(.inlineLarge)
                .searchable(text: $query)
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
                .toolbar {
                    Button(role: .close) {
                        results = []
                    } label: {
                        Text("Clear")
                    }
                    .disabled(results.isEmpty)
                }
        }
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
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        
        do {
            let items = try await JFAPI.shared.searchMedia(query: query)
            results = items
            isLoading = false
        } catch {
            results = []
            isLoading = false
        }
    }
}
