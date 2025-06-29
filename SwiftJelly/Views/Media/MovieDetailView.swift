import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    let movie: BaseItemDto
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: ImageURLProvider.landscapeImageURL(for: movie)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .frame(height: 180)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 8)
                
                Text(movie.name ?? "Movie")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let overview = movie.overview {
                    Text(overview)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                if let year = movie.productionYear {
                    Text("Year: \(year)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let duration = movie.runTimeTicks {
                    Text("Duration: \(duration / 10_000_000 / 60) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(movie.name ?? "Movie")
        .toolbarTitleDisplayMode(.inline)
    }
}
