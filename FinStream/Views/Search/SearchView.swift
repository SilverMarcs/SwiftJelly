import SwiftUI
import JellyfinAPI

struct SearchView: View {
    @State var searchText: String = ""
    @State private var searchScope: SearchScope = .all
    @State private var searchSource: SearchSource = .all
    @State private var viewModel = SearchViewModel()
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool
    @Environment(\.searchFocusRequest) private var searchFocusRequest

    private var isSeerConfigured: Bool {
        DataManager.shared.server?.seer?.isAuthenticated == true
    }

    var body: some View {
        MediaGrid(items: viewModel.results(for: searchScope), isLoading: viewModel.isLoading)
            .navigationTitle("Search")
            .platformNavigationToolbar()
            #if os(iOS)
            .profileToolbarItem()
            #endif
            .searchable(text: $searchText, placement: placement, prompt: "Search movies, shows, or people")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .onChange(of: searchSource) { _, _ in
                scheduleSearch(debounce: false)
            }
            #if !os(tvOS)
            .searchFocused($isSearchFocused)
            // Focus the field whenever the Search tab is activated or reselected.
            .onChange(of: searchFocusRequest, initial: true) {
                isSearchFocused = true
            }
            #endif
            #if os(tvOS)
            .safeAreaInset(edge: .top) {
                if isSeerConfigured {
                    SearchSourcePicker(source: $searchSource)
                        .frame(maxWidth: 900)
                        .focusSection()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .focusSection()
            .onChange(of: searchText) { _, _ in
                scheduleSearch(debounce: true)
            }
            .onDisappear {
                searchTask?.cancel()
                viewModel.isLoading = false
            }
            #else
            .toolbar {
                if isSeerConfigured {
                    ToolbarItem(placement: .primaryAction) {
                        SearchSourcePicker(source: $searchSource)
                    }
                }
            }
            .searchScopes($searchScope) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .onSubmit(of: .search) {
                scheduleSearch(debounce: false)
            }
            #endif
    }

    private func scheduleSearch(debounce: Bool) {
        searchTask?.cancel()
        let query = searchText
        viewModel.isLoading = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        searchTask = Task {
            if debounce {
                try? await Task.sleep(for: .milliseconds(800))
            }
            guard !Task.isCancelled else { return }
            await viewModel.search(for: query, source: searchSource)
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
