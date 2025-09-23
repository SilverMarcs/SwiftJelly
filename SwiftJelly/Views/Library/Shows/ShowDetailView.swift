import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    private var vm: ShowDetailViewModel
    
    init(item: BaseItemDto) {
        vm = ShowDetailViewModel(show: item)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LandscapeImageView(item: vm.show)
                    .frame(maxHeight: 450)
                    .backgroundExtensionEffect()
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
        .task { await vm.loadInitial() }
        .refreshable { await vm.refreshAll() }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(vm.show.name ?? "Show")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await vm.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

