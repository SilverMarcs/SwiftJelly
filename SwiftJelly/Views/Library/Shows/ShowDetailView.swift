import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var vm: ShowDetailViewModel
    
    init(item: BaseItemDto) {
        vm = ShowDetailViewModel(item: item)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Group {
                    if horizontalSizeClass == .compact {
                        PortraitImageView(item: vm.show)
                    } else {
                        LandscapeImageView(item: vm.show)
                            .frame(maxHeight: 450)
                    }
                }
                #if os(macOS)
                .backgroundExtensionEffect()
                #else
                .stretchy()
                #endif
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        AttributesView(item: vm.show)
                            .padding(.leading, 1)
                        
                        ShowPlayButton(vm: vm)
                    }
                    .padding(16)
                }
                
                OverviewView(item: vm.show)
                
                ShowSeasonsView(vm: vm)
                
                if let people = vm.show.people {
                    PeopleScrollView(people: people)
                }
                
                SimilarItemsView(item: vm.show)
            }
            .scenePadding(.bottom)
            .contentMargins(.horizontal, 18)
        }
        .overlay { if vm.isLoading { UniversalProgressView() } }
        .overlay { if vm.isLoadingEpisodes { UniversalProgressView() } }
        .task { await vm.reloadSeasonsAndEpisodes() }
        .refreshable { await vm.refreshAll() }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(vm.show.name ?? "Show")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FavoriteButton(item: vm.show)
                    .environment(\.refresh, vm.reloadSeasonsAndEpisodes)
            }
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await vm.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r")
            }
            #endif
        }
        .environment(\.refresh, vm.reloadSeasonsAndEpisodes)

    }
}

