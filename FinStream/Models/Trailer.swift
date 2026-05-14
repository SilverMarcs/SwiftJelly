import Foundation
import JellyfinAPI

struct Trailer: Identifiable, Hashable {
    let id: String
    let name: String?

    var watchURL: URL { URL(string: "https://www.youtube.com/watch?v=\(id)")! }
    var thumbnailURL: URL { URL(string: "https://img.youtube.com/vi/\(id)/maxresdefault.jpg")! }

    init?(from mediaURL: MediaURL) {
        guard let urlString = mediaURL.url,
              let components = URLComponents(string: urlString),
              let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value,
              !videoID.isEmpty
        else { return nil }
        self.id = videoID
        self.name = mediaURL.name
    }
}

extension BaseItemDto {
    var trailers: [Trailer] {
        Array((remoteTrailers ?? []).compactMap(Trailer.init).prefix(8))
    }
}
