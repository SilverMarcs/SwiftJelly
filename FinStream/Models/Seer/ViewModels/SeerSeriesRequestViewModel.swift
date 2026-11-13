//
//  SeerSeriesRequestViewModel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

@MainActor
@Observable
final class SeerSeriesRequestViewModel {
    private(set) var requestModel: SeerRequestViewModel?
    private var loadedSeriesID: String?

    var showsRequestMore: Bool {
        guard let requestModel, requestModel.hasLoaded else { return false }
        return !requestModel.requestableSeasons.isEmpty
    }

    func load(for series: BaseItemDto) async {
        guard SeerAPI.isConfigured, let seriesID = series.id, loadedSeriesID != seriesID else { return }
        guard let tmdbID = await SeerLibraryResolver.tmdbID(for: series) else { return }

        let model = SeerRequestViewModel(reference: SeerMediaReference(mediaType: .tv, tmdbID: tmdbID))
        await model.load()
        requestModel = model
        loadedSeriesID = seriesID
    }
}
