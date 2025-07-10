import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let movie: BaseItemDto
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    if horizontalSizeClass == .compact {
                        PortraitImageView(item: movie)
                    } else {
                        LandscapeImageView(item: movie)
                    }
                }
                .backgroundExtensionEffect()
                .overlay(alignment: .bottomLeading) {
                    MoviePlayButton(item: movie)
                        .padding(16)
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
        .ignoresSafeArea(edges: .top)
        .navigationTitle(movie.name ?? "Movie")
        .toolbarTitleDisplayMode(.inline)
    }
    
    var aspectRatio: CGFloat {
        #if os(macOS)
        return 16 / 9
        #else
        return 9 / 13
        #endif
    }
}
