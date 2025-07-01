import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    let movie: BaseItemDto
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(aspectRatio, contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .frame(height: 150)
                    }
                    .backgroundExtensionEffect()
                    .overlay(alignment: .bottomLeading) {
                        MoviePlayButton(item: movie)
                            .padding(16)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let overview = movie.overview {
                        Text(overview)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    if let year = movie.productionYear {
                        Text("Year: \(String(year))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let duration = movie.runTimeTicks {
                        Text("Duration: \(duration / 10_000_000 / 60) min")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
//        #if os(macOS)
        .ignoresSafeArea(edges: .top)
//        #endif
        .navigationTitle(movie.name ?? "Movie")
        .toolbarTitleDisplayMode(.inline)
    }
    
    var imageUrl: URL? {
        #if os(macOS)
        ImageURLProvider.landscapeImageURL(for: movie)
        #else
        ImageURLProvider.portraitImageURL(for: movie)
        #endif
    }
    
    var aspectRatio: CGFloat {
        #if os(macOS)
        return 16 / 9
        #else
        return 9 / 13
        #endif
    }
}
