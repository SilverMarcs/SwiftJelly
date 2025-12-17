import SwiftUI
import JellyfinAPI

struct TMDBReviewsView: View {
    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    
    let item: BaseItemDto

    @State private var isLoading = false
    @State private var reviews: [Review] = []
    @State private var errorMessage: String?

    var body: some View {
        if !tmdbAPIKey.isEmpty {
            SectionContainer("Reviews", showHeader: !reviews.isEmpty || isLoading || errorMessage != nil) {
                VStack(alignment: .leading, spacing: 10) {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(reviews) { review in
                        DisclosureGroup {
                            Text(review.content)
                                .textSelection(.enabled)
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(review.author)
                                        .bold()
                                    
                                    Spacer()
                                    
                                    if let rating = review.authorDetails?.rating {
                                        Text(rating, format: .number.precision(.fractionLength(1)))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                if let createdAt = review.createdAt {
                                    Text(createdAt, format: .dateTime.year().month().day())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    if isLoading {
                        UniversalProgressView()
                    }
                }
                .scenePadding(.horizontal)
            }
            .task {
                await load()
            }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        guard !tmdbAPIKey.isEmpty else { return }
        guard let tmdbID = item.tmdbID else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch item.type {
            case .movie:
                reviews = try await TMDBAPI.fetchMovieReviews(apiKey: tmdbAPIKey, movieID: tmdbID)
            case .series:
                reviews = try await TMDBAPI.fetchTVReviews(apiKey: tmdbAPIKey, seriesID: tmdbID)
            default:
                break
            }
        } catch {
            errorMessage = "Couldn’t load reviews."
            print("Error loading Reviews: \(error)")
        }
    }
}
