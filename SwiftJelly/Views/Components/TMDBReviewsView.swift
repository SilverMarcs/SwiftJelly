import SwiftUI
import JellyfinAPI

struct TMDBReviewsView: View {
    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    
    let item: BaseItemDto

    @State private var isLoading = false
    @State private var reviews: [Review] = []
    @State private var selectedReview: Review?

    var body: some View {
        if !tmdbAPIKey.isEmpty {
            SectionContainer("Reviews", showHeader: !reviews.isEmpty) {
                HorizontalShelf(spacing: 12) {
                    ForEach(reviews) { review in
                        cardButton(review: review)
                    }
                }
                
                if isLoading {
                    UniversalProgressView()
                }                
            } destination: {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 320), spacing: 12, alignment: .top)],
                        alignment: .leading,
                        spacing: 12
                    ) {
                        ForEach(reviews) { review in
                            cardButton(review: review)
                        }
                    }
                    .scenePadding()
                }
            }
            .sheet(item: $selectedReview) { review in
                ScrollView {
                    Text(review.content)
                        .textSelection(.enabled)
                        .scenePadding()
                }
                .frame(maxWidth: 500, maxHeight: 500)
                .presentationDetents([.medium, .large])
            }
            .task {
                await load()
            }
        }
    }
    
    func cardButton(review: Review) -> some View {
        Button {
            selectedReview = review
        } label: {
            TMDBReviewCard(review: review)
        }
        #if os(tvOS)
        .buttonStyle(.card)
        #else
        .buttonStyle(.plain)
        #endif
    }

    private func load() async {
        guard !isLoading else { return }
        guard !tmdbAPIKey.isEmpty else { return }
        guard let tmdbID = item.tmdbID else { return }

        isLoading = true
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
            print("Error loading Reviews: \(error.localizedDescription)")
        }
    }
}
