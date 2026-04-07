//
//  DiscoverFilterMenu.swift
//  SwiftJelly
//

import SwiftUI

struct DiscoverFilterMenu: ToolbarContent {
    @Bindable var vm: DiscoverViewModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Menu {
                // MARK: Language
                Menu("Language") {
                    Button {
                        vm.filters.language = nil
                    } label: {
                        label("All", isSelected: vm.filters.language == nil)
                    }

                    Divider()

                    ForEach(DiscoverLanguages.all) { lang in
                        Button {
                            vm.filters.language = lang.code
                        } label: {
                            label(lang.name, isSelected: vm.filters.language == lang.code)
                        }
                    }
                }

                // MARK: Genre
                Menu("Genre") {
                    Button {
                        vm.filters.genre = nil
                    } label: {
                        label("All", isSelected: vm.filters.genre == nil)
                    }

                    Divider()

                    ForEach(genres) { genre in
                        Button {
                            vm.filters.genre = genre
                        } label: {
                            label(genre.name, isSelected: vm.filters.genre == genre)
                        }
                    }
                }

                // MARK: Watch Provider
                Menu("Streaming Service") {
                    Button {
                        vm.filters.watchProvider = nil
                    } label: {
                        label("All", isSelected: vm.filters.watchProvider == nil)
                    }

                    Divider()

                    ForEach(WatchProviders.popular) { provider in
                        Button {
                            vm.filters.watchProvider = provider
                        } label: {
                            label(provider.name, isSelected: vm.filters.watchProvider == provider)
                        }
                    }
                }

                Divider()

                // MARK: Vote Score
                Menu("User Score") {
                    Button {
                        vm.filters.voteAverageGte = nil
                    } label: {
                        label("Any", isSelected: vm.filters.voteAverageGte == nil)
                    }

                    Divider()

                    ForEach(VoteScorePreset.allCases) { preset in
                        Button {
                            vm.filters.voteAverageGte = preset.rawValue
                        } label: {
                            label(preset.label, isSelected: vm.filters.voteAverageGte == preset.rawValue)
                        }
                    }
                }

                // MARK: Vote Count
                Menu("Minimum Votes") {
                    Button {
                        vm.filters.voteCountGte = nil
                    } label: {
                        label("Any", isSelected: vm.filters.voteCountGte == nil)
                    }

                    Divider()

                    ForEach(VoteCountPreset.allCases) { preset in
                        Button {
                            vm.filters.voteCountGte = preset.rawValue
                        } label: {
                            label(preset.label, isSelected: vm.filters.voteCountGte == preset.rawValue)
                        }
                    }
                }

                if vm.filters.isActive {
                    Divider()

                    Button("Reset Filters", role: .destructive) {
                        vm.filters.reset()
                    }
                }
            } label: {
                Label("Filter", systemImage: vm.filters.isActive
                      ? "line.3.horizontal.decrease"
                      : "line.3.horizontal.decrease")
            }
            .disabled(vm.isLoading)
        }
    }

    private var genres: [TMDBGenre] {
        vm.selectedType == .movies ? TMDBGenres.movie : TMDBGenres.tv
    }

    private func label(_ text: String, isSelected: Bool) -> some View {
        HStack {
            Text(text)
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}
