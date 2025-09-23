import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @State private var currentItem: BaseItemDto
    @State private var isLoading = false
    
    init(item: BaseItemDto) {
        self._currentItem = State(initialValue: item)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    LandscapeImageView(item: currentItem)
                        .frame(maxHeight: 500)
                }
                .backgroundExtensionEffect()
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        LogoView(item: currentItem)

                        AttributesView(item: currentItem)
                            .padding(.leading, 2)
                        
                        MoviePlayButton(item: currentItem)
                            .animation(.default, value: currentItem)
                            .environment(\.refresh, fetchMovie)
                    }
                    .padding(16)
                }
            
                VStack(alignment: .leading, spacing: 5) {
                    if let firstTagline = currentItem.taglines?.first {
                        Text(firstTagline)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if let overview = currentItem.overview {
                        Text(overview)
                            .foregroundStyle(.secondary)
                    }
                }
                .scenePadding(.horizontal)
                
                if let people = currentItem.people {
                    PeopleScrollView(people: people)
                }
                
//                    if let studios = currentItem.studios, !studios.isEmpty {
//                        StudiosScrollView(studios: studios)
//                    }
                
                SimilarItemsView(item: currentItem)
            }
            .scenePadding(.bottom)
            .contentMargins(.horizontal, 18)
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(currentItem.name ?? "Movie")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await fetchMovie() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .refreshable {
            await fetchMovie()
        }
    }
    
    private func fetchMovie() async {
        isLoading = true
        defer { isLoading = false }
        do {
            currentItem = try await JFAPI.loadItem(by: currentItem.id ?? "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var aspectRatio: CGFloat {
        #if os(macOS)
        return 16 / 9
        #else
        return 9 / 13
        #endif
    }
}
