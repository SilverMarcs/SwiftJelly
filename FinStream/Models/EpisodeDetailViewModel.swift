import Foundation
import JellyfinAPI
import SwiftUI

@Observable
class EpisodeDetailViewModel {
    private(set) var episode: BaseItemDto
    private(set) var show: BaseItemDto?

    var isLoading: Bool = false

    init(item: BaseItemDto) {
        self.episode = item
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadEpisode() }
            group.addTask { await self.loadShow() }
        }
    }

    private func loadEpisode() async {
        let id = episode.id ?? ""
        guard !id.isEmpty else { return }
        if let fresh = try? await JFAPI.loadItem(by: id) {
            episode = fresh
        }
    }

    private func loadShow() async {
        guard let seriesID = episode.seriesID, !seriesID.isEmpty else { return }
        if show?.id == seriesID { return }
        if let loaded = try? await JFAPI.loadItem(by: seriesID) {
            show = loaded
        }
    }
}
