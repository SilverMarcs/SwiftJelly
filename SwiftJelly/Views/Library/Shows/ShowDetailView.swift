import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let id: String
    
    @State private var show: BaseItemDto?
    @State private var seasons: [BaseItemDto] = []
    @State private var selectedSeason: BaseItemDto?
    @State private var episodes: [BaseItemDto] = []
    @State private var isLoading = false
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    
    var body: some View {
        ScrollView {
            if let show {
                VStack(alignment: .leading, spacing: 14) {
                    Group {
                        if horizontalSizeClass == .compact {
                            PortraitImageView(item: show)
                        } else {
                            LandscapeImageView(item: show)
                        }
                    }
                    .backgroundExtensionEffect()
                    .overlay(alignment: .bottomLeading) {
                        ShowPlayButton(show: show, episodes: episodes)
                            .animation(.default, value: show)
                            .environment(\.refresh, fetchShow)
                            .padding(16)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let overview = show.overview {
                            Text(overview)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    
                        if !seasons.isEmpty {
                            Picker("Season", selection: $selectedSeason) {
                                ForEach(seasons) { season in
                                    Text(season.name ?? "Season").tag(season as BaseItemDto?)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                        }
                    }
                    .scenePadding(.horizontal)

                    if !episodes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(episodes) { episode in
                                    PlayableCard(item: episode, showNavigation: false)
                                        .id(episode.id)
                                        .environment(\.refresh, fetchShow)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                            .scrollTargetLayout()
                        }
                        .scrollPosition($episodeScrollPosition)
                    }
                }
                .scenePadding(.bottom)
                
            } else if isLoading {
                UniversalProgressView()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(show?.name ?? "Show")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await fetchShow() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            if show == nil {
                await fetchShow()
            }
        }
        .refreshable {
            await fetchShow()
        }
        .task(id: selectedSeason) {
            await loadEpisodes(for: selectedSeason)
        }
        .task(id: episodes) {
            if let latest = episodes.filter({
                let ticks = $0.userData?.playbackPositionTicks ?? 0
                return ticks > 0
            }).sorted(by: { ($0.userData?.lastPlayedDate ?? .distantPast) > ($1.userData?.lastPlayedDate ?? .distantPast) }).first,
               let id = latest.id {
                withAnimation {
                    episodeScrollPosition.scrollTo(id: id, anchor: .trailing)
                }
            }
        }
    }
    
    private func fetchShow() async {
        isLoading = true
        defer { isLoading = false }
        do {
            show = try await JFAPI.shared.loadItem(by: id)
            await loadSeasons()
        } catch {
            show = nil
            seasons = []
            episodes = []
        }
    }
    
    private func loadSeasons() async {
        guard let show else { seasons = []; return }
        guard seasons.isEmpty else { return } // Don't reload if already loaded
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedSeasons = try await JFAPI.shared.loadSeasons(for: show)
            self.seasons = loadedSeasons
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
            self.seasons = []
        }
    }
    
    private func loadEpisodes(for season: BaseItemDto?) async {
        guard let show, let season else { episodes = []; return }
        do {
            self.episodes = try await JFAPI.shared.loadEpisodes(for: show, season: season)
        } catch {
            self.episodes = []
        }
    }
}
