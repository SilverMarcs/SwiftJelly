//
//  SeerSeasonRequestView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerSeasonRequestView: View {
    @Environment(\.dismiss) private var dismiss

    let model: SeerRequestViewModel

    @State private var selectedSeasons: Set<Int> = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("All Seasons", isOn: allSeasonsBinding)
                }

                Section("Seasons") {
                    ForEach(model.seasons) { season in
                        SeerSeasonToggleRow(
                            season: season,
                            status: model.mediaInfo?.status(forSeason: season.seasonNumber),
                            isOn: seasonBinding(season.seasonNumber)
                        )
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Request Seasons")
            .platformNavigationToolbar(titleDisplayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Request") {
                        Task { await model.submit(seasons: selectedSeasons.sorted()) }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .disabled(selectedSeasons.isEmpty || model.isRequesting)
                }
            }
        }
    }

    private var requestableSeasonNumbers: [Int] {
        model.requestableSeasons.map(\.seasonNumber)
    }

    private var allSeasonsBinding: Binding<Bool> {
        Binding(
            get: { !requestableSeasonNumbers.isEmpty && selectedSeasons == Set(requestableSeasonNumbers) },
            set: { selectedSeasons = $0 ? Set(requestableSeasonNumbers) : [] }
        )
    }

    private func seasonBinding(_ seasonNumber: Int) -> Binding<Bool> {
        Binding(
            get: { selectedSeasons.contains(seasonNumber) },
            set: { isOn in
                if isOn {
                    selectedSeasons.insert(seasonNumber)
                } else {
                    selectedSeasons.remove(seasonNumber)
                }
            }
        )
    }
}
