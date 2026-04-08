//
//  DiscoverView.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

struct DiscoverView: View {
    @State private var vm = DiscoverViewModel()
    @State private var matchingItemID: String?
    @State private var matchedItem: BaseItemDto?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(vm.results, id: \.uniqueID) { item in
                    DiscoverCard(item: item, isMatching: matchingItemID == item.uniqueID) {
                        Task { await navigateToMatch(for: item) }
                    }
                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    .onAppear {
                        if item.uniqueID == vm.results.last?.uniqueID {
                            Task { await vm.loadMore() }
                        }
                    }
                }
            }
            .scenePadding()

            if vm.isLoading && !vm.results.isEmpty {
                UniversalProgressView()
                    .padding(.vertical, 24)
            }
        }
        .overlay {
            if vm.isLoading && vm.results.isEmpty {
                UniversalProgressView()
            }
        }
        .navigationTitle("Discover")
        .navigationDestination(item: $matchedItem) { item in
            MediaDestinationView(item: item)
        }
        #if !os(tvOS)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Type", selection: $vm.selectedType) {
                    ForEach(DiscoverViewModel.MediaType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }

            DiscoverFilterMenu(vm: vm)
        }
        #endif
        .onChange(of: vm.selectedType) {
            // Reset genre when switching type since movie/TV genres differ
            vm.filters.genre = nil
            Task { await vm.reload() }
        }
        .onChange(of: vm.filters) {
            Task { await vm.reload() }
        }
        .task {
            await vm.loadIfNeeded()
        }
    }

    private func navigateToMatch(for item: SeerrSearchResult) async {
        matchingItemID = item.uniqueID
        defer { matchingItemID = nil }

        guard let results = try? await JFAPI.searchMedia(query: item.displayTitle, includeProviderId: true) else { return }
        let expectedType: BaseItemKind = item.isMovie ? .movie : .series
        let tmdbID = String(item.id)

        let matched = results.first { jfItem in
            guard jfItem.type == expectedType else { return false }
            if let providers = jfItem.providerIDs, providers["Tmdb"] == tmdbID { return true }
            return jfItem.name?.lowercased() == item.displayTitle.lowercased()
        }

        if let matched {
            matchedItem = matched
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: posterWidth), spacing: gridSpacing)]
    }

    private var gridSpacing: CGFloat {
        #if os(tvOS)
        30
        #elseif os(iOS)
        12
        #elseif os(macOS)
        10
        #endif
    }
}
