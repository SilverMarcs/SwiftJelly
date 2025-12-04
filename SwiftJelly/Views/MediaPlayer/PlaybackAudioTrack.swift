import Foundation
import JellyfinAPI

struct PlaybackAudioTrack: Identifiable, Equatable {
    let id: Int
    let index: Int
    let displayName: String
    let languageCode: String?

    static func tracks(from info: PlaybackInfoResponse) -> [PlaybackAudioTrack] {
        guard let streams = info.mediaSource.mediaStreams else { return [] }
        return streams
            .filter { $0.type == .audio }
            .map { stream in
                let index = stream.index ?? 0
                let languageCode = stream.language?.lowercased()
                let languageName = languageCode
                    .flatMap { Locale.current.localizedString(forLanguageCode: $0) }
                    ?? stream.language
                let titleComponents = [stream.displayTitle, languageName, stream.codec?.uppercased()]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                let displayName = titleComponents.isEmpty
                    ? "Track \(index + 1)"
                    : titleComponents.joined(separator: " · ")

                return PlaybackAudioTrack(
                    id: index,
                    index: index,
                    displayName: displayName,
                    languageCode: languageCode
                )
            }
    }
}




