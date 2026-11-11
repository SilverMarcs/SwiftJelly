import AVFoundation
import JellyfinAPI

/// Preparation owns resources until a PlaybackSession adopts them. It never
/// changes a player, making cancellation safe before publication.
@MainActor
final class PreparedPlayback {
    let item: BaseItemDto
    let info: PlaybackInfoResponse
    let playerItem: AVPlayerItem
    let selection: PlaybackMediaSelection
    let context: JFAPI.APIContext?
    let adapter: LocalHLSAdapter?
    let encodingSessionIDs: [String]
    let resumeSeconds: Double
    let initialAudioIndex: Int?
    let outcome: PlaybackPreparationOutcome

    init(item: BaseItemDto, info: PlaybackInfoResponse, playerItem: AVPlayerItem, selection: PlaybackMediaSelection, context: JFAPI.APIContext?, adapter: LocalHLSAdapter? = nil, encodingSessionIDs: [String] = [], resumeSeconds: Double, initialAudioIndex: Int? = nil, outcome: PlaybackPreparationOutcome = .original) {
        self.item = item
        self.info = info
        self.playerItem = playerItem
        self.selection = selection
        self.context = context
        self.adapter = adapter
        self.encodingSessionIDs = encodingSessionIDs
        self.resumeSeconds = resumeSeconds
        self.initialAudioIndex = initialAudioIndex
        self.outcome = outcome
    }

    func discard() {
        adapter?.stop()
        guard let context else { return }
        let ids = encodingSessionIDs
        Task { await JFAPI.stopPlaybackEncodings(context: context, sessionIDs: ids) }
    }
}
