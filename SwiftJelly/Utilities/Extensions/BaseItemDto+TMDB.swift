import Foundation
import JellyfinAPI

extension BaseItemDto {
    var tmdbID: Int? {
        guard let providerIDs else { return nil }

        if let raw = providerIDs["Tmdb"] ?? providerIDs["tmdb"] {
            return Int(raw)
        }

        if let (key, value) = providerIDs.first(where: { $0.key.lowercased() == "tmdb" }) {
            _ = key
            return Int(value)
        }

        return nil
    }
}

