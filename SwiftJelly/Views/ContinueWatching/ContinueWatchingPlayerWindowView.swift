import SwiftUI
import JellyfinAPI
import VLCUI

struct ContinueWatchingPlayerWindowView: View {
    let item: BaseItemDto
    let server: Server
    let user: User

    var body: some View {
        if let url = playbackURL {
            VLCVideoPlayer(
                configuration: .init(
                    url: url,
                    autoPlay: true,
                    startSeconds: .seconds(Int64(startTimeSeconds))
                )
            )
        } else {
            Text("Unable to play this item.")
                .padding()
        }
    }

    private var playbackURL: URL? {
        guard let id = item.id else { return nil }

        // Use proper Jellyfin streaming URL with authentication
        var components = URLComponents(url: server.url, resolvingAgainstBaseURL: false)
        components?.path = "/Videos/\(id)/stream"

        // Add query parameters for streaming
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "Static", value: "true"),
            URLQueryItem(name: "mediaSourceId", value: id),
            URLQueryItem(name: "api_key", value: user.accessToken)
        ]

        // Add device info if available
        queryItems.append(URLQueryItem(name: "deviceId", value: "deviceId"))
        

        components?.queryItems = queryItems
        return components?.url
    }

    private var startTimeSeconds: Int {
        guard let ticks = item.userData?.playbackPositionTicks else { return 0 }
        return Int(ticks / 10_000_000)
    }
}
