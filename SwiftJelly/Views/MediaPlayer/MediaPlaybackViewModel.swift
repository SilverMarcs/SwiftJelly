import AVFoundation
import Foundation
import JellyfinAPI
import Observation

@MainActor
@Observable final class MediaPlaybackViewModel {
    var item: BaseItemDto
    var player: AVPlayer?
    var isLoading = true
    var isAutoLoadingNext = false
    var playbackToken = UUID()

    var playbackInfo: PlaybackInfoResponse?

    var audioTracks: [PlaybackAudioTrack] = []
    var selectedAudioTrack: PlaybackAudioTrack?
    var preferredAudioLanguage: String?
    var isSwitchingAudio = false

    var currentSeconds: Double = 0
    var durationSeconds: Double = 0

    var isFetchingNextEpisode = false

    @ObservationIgnored private var markers = MediaChapterMarkers(introRangeSeconds: nil, creditsStartSeconds: nil)
    @ObservationIgnored private var prefetchedNextEpisode: BaseItemDto?
    @ObservationIgnored private var playbackEndObserver: NSObjectProtocol?
    @ObservationIgnored private var timeObserverToken: Any?
    @ObservationIgnored private var requestedAudioStreamIndex: Int?
    @ObservationIgnored private var isLoadingTaskActive = false

    init(item: BaseItemDto) {
        self.item = item
    }

    func load() async {
        await load(audioIndex: requestedAudioStreamIndex, resumeSeconds: nil)
    }

    func load(audioIndex: Int?, resumeSeconds: Double?) async {
        guard !isLoadingTaskActive else { return }
        isLoadingTaskActive = true
        defer { isLoadingTaskActive = false }

        isLoading = true
        requestedAudioStreamIndex = audioIndex ?? requestedAudioStreamIndex
        stopObservingTime()
        removePlaybackEndObserver()

        do {
            let session = try await PlaybackUtilities.loadPlaybackInfo(
                for: item,
                into: player,
                audioStreamIndex: audioIndex,
                resumeSeconds: resumeSeconds
            )

            player = session.player
            playbackInfo = session.info
            item = session.item
            markers = MediaChapterMarkerResolver.resolve(from: session.item.chapters)

            audioTracks = PlaybackAudioTrack.tracks(from: session.info)
            selectedAudioTrack = resolveSelectedTrack(preferredIndex: audioIndex)

            startObservingTime(for: session.player)
            registerEndObserver(for: session.player)
        } catch {
            // Intentionally ignore; just stop loading.
        }

        isLoading = false
    }

    func cleanup() async {
        removePlaybackEndObserver()
        stopObservingTime()
        prefetchedNextEpisode = nil
        isFetchingNextEpisode = false

        guard let player else { return }
        await PlaybackUtilities.reportPlaybackAndCleanup(player: player, item: item)
        self.player = nil
    }

    var skipIntroTargetSeconds: Double? {
        guard let introRange = markers.introRangeSeconds else { return nil }
        let leadInSeconds = 2.0
        let showStart = max(0, introRange.lowerBound - leadInSeconds)
        guard currentSeconds >= showStart, currentSeconds < introRange.upperBound else { return nil }
        return introRange.upperBound
    }

    var shouldShowSkipIntro: Bool {
        skipIntroTargetSeconds != nil
    }

    var shouldShowNextEpisode: Bool {
        guard item.type == .episode else { return false }
        let duration = durationSeconds
        guard duration > 0 else { return false }
        let promptStartSeconds = markers.creditsStartSeconds ?? max(0, duration - 60)
        return currentSeconds >= promptStartSeconds
    }

    func skipIntro() async {
        guard let player, let targetSeconds = skipIntroTargetSeconds else { return }
        let time = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        await withCheckedContinuation { continuation in
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                continuation.resume()
            }
        }
    }

    func transitionToNextEpisode() async {
        guard item.type == .episode, !isAutoLoadingNext, let currentPlayer = player else { return }

        isAutoLoadingNext = true
        defer { isAutoLoadingNext = false }

        removePlaybackEndObserver()
        stopObservingTime()

        let finishedItem = item
        await PlaybackUtilities.reportPlaybackStop(player: currentPlayer, item: finishedItem)

        let nextEpisode: BaseItemDto?
        if let cachedNextEpisode = prefetchedNextEpisode {
            nextEpisode = cachedNextEpisode
        } else {
            nextEpisode = try? await JFAPI.loadNextEpisode(after: finishedItem)
        }

        guard let nextEpisode, nextEpisode.id != finishedItem.id else { return }

        prefetchedNextEpisode = nil
        item = nextEpisode
        await load(audioIndex: requestedAudioStreamIndex, resumeSeconds: nil)
    }

    func switchAudioTrack(to track: PlaybackAudioTrack) async {
        guard track != selectedAudioTrack else { return }
        preferredAudioLanguage = track.languageCode ?? preferredAudioLanguage
        requestedAudioStreamIndex = track.index

        isSwitchingAudio = true
        defer { isSwitchingAudio = false }

        let resumeSeconds = player?.currentTime().seconds ?? 0
        await load(audioIndex: track.index, resumeSeconds: resumeSeconds)
    }

    private func registerEndObserver(for player: AVPlayer) {
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.transitionToNextEpisode()
            }
        }
    }

    private func removePlaybackEndObserver() {
        if let observer = playbackEndObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackEndObserver = nil
        }
    }

    private func startObservingTime(for player: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 10)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentSeconds = time.seconds.isFinite ? max(0, time.seconds) : 0
                self.durationSeconds = self.resolvedDurationSeconds(for: player)
                await self.prefetchNextEpisodeIfNeeded()

                guard self.item.type == .episode,
                      !self.isAutoLoadingNext,
                      !self.isLoadingTaskActive else {
                    return
                }
            }
        }
    }

    private func stopObservingTime() {
        guard let token = timeObserverToken else { return }
        player?.removeTimeObserver(token)
        timeObserverToken = nil
    }

    private func resolvedDurationSeconds(for player: AVPlayer) -> Double {
        if let duration = player.currentItem?.duration.seconds, duration.isFinite, duration > 0 {
            return duration
        }
        if let ticks = playbackInfo?.mediaSource.runTimeTicks, ticks > 0 {
            return Double(ticks) / 10_000_000
        }
        if let ticks = item.runTimeTicks, ticks > 0 {
            return Double(ticks) / 10_000_000
        }
        return 0
    }

    private func prefetchNextEpisodeIfNeeded() async {
        guard item.type == .episode else { return }
        guard prefetchedNextEpisode == nil, !isFetchingNextEpisode else { return }

        let duration = durationSeconds
        guard duration > 0 else { return }

        let remainingSeconds = duration - currentSeconds
        guard remainingSeconds <= 120 else { return }

        isFetchingNextEpisode = true
        defer { isFetchingNextEpisode = false }
        prefetchedNextEpisode = try? await JFAPI.loadNextEpisode(after: item)
    }

    private func resolveSelectedTrack(preferredIndex: Int?) -> PlaybackAudioTrack? {
        if let preferredIndex,
           let match = audioTracks.first(where: { $0.index == preferredIndex }) {
            preferredAudioLanguage = match.languageCode ?? preferredAudioLanguage
            return match
        }

        if let preferredAudioLanguage,
           let languageMatch = audioTracks.first(where: { $0.languageCode?.lowercased() == preferredAudioLanguage.lowercased() }) {
            return languageMatch
        }

        if let defaultIndex = playbackInfo?.mediaSource.defaultAudioStreamIndex,
           let defaultMatch = audioTracks.first(where: { $0.index == defaultIndex }) {
            preferredAudioLanguage = defaultMatch.languageCode ?? preferredAudioLanguage
            return defaultMatch
        }

        preferredAudioLanguage = audioTracks.first?.languageCode ?? preferredAudioLanguage
        return audioTracks.first
    }
}
