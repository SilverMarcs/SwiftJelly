import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    let show: BaseItemDto
    @State private var seasons: [BaseItemDto] = []
    @State private var selectedSeason: BaseItemDto?
    @State private var episodes: [BaseItemDto] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AsyncImage(url: ImageURLProvider.landscapeImageURL(for: show)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .frame(height: 150)
                }
                .backgroundExtensionEffect()
                
                VStack(alignment: .leading, spacing: 12) {
//                    Text(show.name ?? "Show")
//                        .font(.title)
//                        .fontWeight(.bold)
                    
                    if let overview = show.overview {
                        Text(overview)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    if !seasons.isEmpty {
                        Picker("Season", selection: $selectedSeason) {
                            ForEach(seasons) { season in
                                Text(season.name ?? "Season").tag(season as BaseItemDto?)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    
                
                    if !episodes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(episodes) { episode in
                                    PlayableCard(item: episode)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
        }
        #if os(macOS)
        .ignoresSafeArea(edges: .top)
        #endif
        .navigationTitle(show.name ?? "Show")
        .toolbarTitleDisplayMode(.inline)
        .task {
            await loadSeasons()
        }
        .task(id: selectedSeason) {
            await loadEpisodes(for: selectedSeason)
        }
    }
    
    private func loadSeasons() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedSeasons = try await JFAPI.shared.loadSeasons(for: show)
            self.seasons = loadedSeasons
            // Select most recent season with watched episodes, else first
            if let recent = loadedSeasons.first(where: {
                ($0.userData?.isPlayed == true) || (($0.userData?.playCount ?? 0) > 0)
            }) {
                self.selectedSeason = recent
            } else {
                self.selectedSeason = loadedSeasons.first
            }
            if let selected = self.selectedSeason {
                await loadEpisodes(for: selected)
            }
        } catch {
            // handle error
        }
    }
    
    private func loadEpisodes(for season: BaseItemDto?) async {
        guard let season else { episodes = []; return }
        do {
            self.episodes = try await JFAPI.shared.loadEpisodes(for: show, season: season)
        } catch {
            self.episodes = []
        }
    }
}
