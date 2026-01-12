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

    /// The prefetched next episode, if available.
    private(set) var nextEpisode: BaseItemDto?
    
    /// The time in seconds when credits start for the current item.
    var creditsStartSeconds: Double? {
        markers.creditsStartSeconds
    }

    @ObservationIgnored private var markers = MediaChapterMarkers(introRangeSeconds: nil, creditsStartSeconds: nil)
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
        } catch {
            // Intentionally ignore; just stop loading.
        }

        isLoading = false
    }

    func cleanup() async {
        stopObservingTime()
        nextEpisode = nil
        isFetchingNextEpisode = false

        guard let player else { return }
        player.pause()
        player.replaceCurrentItem(with: nil)

        self.player = nil
    }
    
    /// Internal cleanup for switching items without triggering endPlayback.
    func cleanupForSwitch() {
        stopObservingTime()
        nextEpisode = nil
        isFetchingNextEpisode = false
        
        if let player {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
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
        guard item.type == .episode, !isAutoLoadingNext else { return }
        player?.pause()
        
        isAutoLoadingNext = true
        defer { isAutoLoadingNext = false }

        stopObservingTime()

        let finishedItem = item

        let episodeToPlay: BaseItemDto?
        if let cachedNextEpisode = nextEpisode {
            episodeToPlay = cachedNextEpisode
        } else {
            episodeToPlay = try? await JFAPI.loadNextEpisode(after: finishedItem)
        }

        guard let episodeToPlay, episodeToPlay.id != finishedItem.id else { return }

        nextEpisode = nil
        item = episodeToPlay
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
        guard nextEpisode == nil, !isFetchingNextEpisode else { return }

        let duration = durationSeconds
        guard duration > 0 else { return }

        let remainingSeconds = duration - currentSeconds
        guard remainingSeconds <= 120 else { return }

        print("[NextEpisode] Prefetching next episode - remaining: \(remainingSeconds)s")
        isFetchingNextEpisode = true
        defer { isFetchingNextEpisode = false }
        nextEpisode = try? await JFAPI.loadNextEpisode(after: item)
        print("[NextEpisode] Prefetch complete - nextEpisode: \(nextEpisode?.name ?? "nil")")
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
