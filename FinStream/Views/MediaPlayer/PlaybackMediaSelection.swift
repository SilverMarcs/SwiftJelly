import AVFoundation
import JellyfinAPI

@MainActor
struct PlaybackMediaSelection {
    let audioGroup: AVMediaSelectionGroup?
    let subtitleGroup: AVMediaSelectionGroup?
    let audioIndices: [AVMediaSelectionOption: Int]
    let subtitleIndices: [AVMediaSelectionOption: Int]

    static func load(asset: AVAsset, source: MediaSourceInfo) async throws -> Self {
        let audio = try await asset.loadMediaSelectionGroup(for: .audible)
        let subtitles = try await asset.loadMediaSelectionGroup(for: .legible)
        let streams = source.mediaStreams ?? []
        return Self(
            audioGroup: audio, subtitleGroup: subtitles,
            audioIndices: indices(options: audio?.options ?? [], streams: streams.filter { $0.type == .audio }, characteristic: HLSMediaIdentity.audio),
            subtitleIndices: indices(options: subtitles?.options ?? [], streams: streams.filter { $0.type == .subtitle }, characteristic: HLSMediaIdentity.subtitle)
        )
    }

    private static func indices(options: [AVMediaSelectionOption], streams: [MediaStream], characteristic: (Int) -> String) -> [AVMediaSelectionOption: Int] {
        var result: [AVMediaSelectionOption: Int] = [:]
        for option in options {
            if let stream = streams.first(where: { stream in
                guard let index = stream.index else { return false }
                return option.hasMediaCharacteristic(AVMediaCharacteristic(rawValue: characteristic(index)))
            }), let index = stream.index {
                result[option] = index
                continue
            }
            // Original files need no adapter. Only infer a server index when
            // their language identifies exactly one stream; never guess by label.
            let language = option.extendedLanguageTag.map { Locale.Language(identifier: $0).minimalIdentifier }
            let matches = streams.filter { stream in
                guard let code = stream.language, let language else { return streams.count == 1 }
                return Locale.Language(identifier: code).minimalIdentifier == language
            }
            if matches.count == 1, let index = matches.first?.index { result[option] = index }
        }
        return result
    }
}
