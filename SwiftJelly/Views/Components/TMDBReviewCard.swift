import SwiftUI
import SwiftMediaViewer

struct TMDBReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(review.author)
                        .bold()

                    if let createdAt = review.createdAt {
                        Text(createdAt, format: .dateTime.year().month().day())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                if let rating = review.authorDetails?.rating {
                    Text(rating, format: .number.precision(.fractionLength(1)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(review.content)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3, reservesSpace: true)
        }
        .padding()
        .frame(width: 320, alignment: .leading)
        .background(.background.secondary)
        #if !os(tvOS)
        .clipShape(.rect(cornerRadius: 16))
        #endif
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = avatarURL {
            CachedAsyncImage(url: url, targetSize: 100) {
                Circle()
                    .fill(.tertiary)
            }
            .scaledToFill()
            .frame(width: 30, height: 30)
            .clipShape(.circle)
            .clipped()
        } else {
            Circle()
                .fill(.background.secondary)
                .frame(width: 30, height: 30)
        }
    }

    private var avatarURL: URL? {
        guard var avatarPath = review.authorDetails?.avatarPath, !avatarPath.isEmpty else { return nil }

        if avatarPath.hasPrefix("/https://") || avatarPath.hasPrefix("/http://") {
            avatarPath.removeFirst()
            return URL(string: avatarPath)
        }

        if avatarPath.hasPrefix("https://") || avatarPath.hasPrefix("http://") {
            return URL(string: avatarPath)
        }

        if avatarPath.hasPrefix("/") {
            return URL(string: "https://image.tmdb.org/t/p/w185\(avatarPath)")
        }

        return nil
    }
}
