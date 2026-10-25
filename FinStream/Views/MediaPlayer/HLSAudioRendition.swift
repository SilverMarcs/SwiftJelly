import Foundation

/// A Jellyfin video rendition with this audio stream multiplexed into it.
struct HLSAudioRendition: Sendable {
    let streamIndex: Int
    let name: String
    let language: String?
    let channels: Int
    let playSessionID: String
}
