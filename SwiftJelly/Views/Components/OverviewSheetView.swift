//
//  OverviewSheetView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/04/2026.
//

import SwiftUI
import JellyfinAPI

struct OverviewSheetView: View {
    let item: BaseItemDto
    let overview: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Ratings row
                    ratingsRow

                    // Metadata row (year, runtime, rating)
                    metadataRow

                    // Genres
                    if let genres = item.genres, !genres.isEmpty {
                        Text(genres.joined(separator: " \u{00B7} "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Overview text
                    Text(overview)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Tagline
                    if let tagline = item.taglines?.first, !tagline.isEmpty, tagline != overview {
                        Text("\"\(tagline)\"")
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle(item.name ?? "Overview")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(role: .close) {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var ratingsRow: some View {
        let hasRatings = item.communityRating != nil || item.criticRating != nil
        if hasRatings {
            HStack(spacing: 16) {
                // Community Rating (TMDB/IMDb style)
                if let communityRating = item.communityRating {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.subheadline)
                        unsafe Text(String(format: "%.1f", communityRating))
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("/ 10")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Critic Rating (Rotten Tomatoes)
                if let criticRating = item.criticRating {
                    HStack(spacing: 6) {
                        unsafe Text(criticRating >= 60 ? "🍅" : "🤢")
                            .font(.subheadline)
                        unsafe Text("\(Int(criticRating))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var metadataRow: some View {
        HStack(spacing: 8) {
            if let year = item.productionYear {
                Text(String(year))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let runTimeTicks = item.runTimeTicks, item.type != .series {
                let totalMinutes = runTimeTicks / 10_000_000 / 60
                let hours = totalMinutes / 60
                let minutes = totalMinutes % 60
                Text("\u{00B7}")
                    .foregroundStyle(.tertiary)
                if hours > 0 {
                    Text("\(hours)h \(minutes)m")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(minutes)m")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let rating = item.officialRating {
                Text("\u{00B7}")
                    .foregroundStyle(.tertiary)
                Text(rating)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.secondary, lineWidth: 0.75)
                    )
            }
        }
    }
}
