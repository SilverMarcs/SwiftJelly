import AVFoundation
import Foundation
import JellyfinAPI
import Observation

@MainActor
@Observable final class MediaPlaybackViewModel {
    var item: BaseItemDto
    var isLoading = true
    var isAutoLoadingNext = false
    var isFetchingNextEpisode = false
    private(set) var nextEpisode: BaseItemDto?
    private var session: PlaybackSession?
    private var preparationError: String?
    private var preferredAudioLanguage: String?
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var markers = MediaChapterMarkers(introRangeSeconds: nil, creditsStartSeconds: nil)

    var player: AVPlayer? { session?.isStopped == false ? session?.player : nil }
    var currentSeconds: Double { session?.currentSeconds ?? 0 }
    var durationSeconds: Double { session?.durationSeconds ?? 0 }
    var errorDescription: String? { preparationError ?? session?.errorDescription }
    var creditsStartSeconds: Double? { markers.creditsStartSeconds }

    init(item: BaseItemDto) { self.item = item }

    func load() async {
        if let loadTask { await loadTask.value; return }
        let id = UUID()
        generation = id
        let task = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.prepareAndStart(generation: id)
        }
        // The view's loading indicator may disappear while start() is seeking.
        // This task belongs to the model, not that temporary view's lifetime.
        loadTask = task
        await task.value
        if generation == id { loadTask = nil }
    }

    private func prepareAndStart(generation id: UUID) async {
        isLoading = true
        preparationError = nil
        defer { if generation == id { isLoading = false } }
        let language = session?.audioLanguage ?? preferredAudioLanguage
        let resume = session?.prepared.info.itemID == item.id ? session?.currentSeconds : nil
        do {
            let prepared = try await PlaybackPreparer.prepare(for: item, preferredLanguage: language, resumeSeconds: resume)
            guard !Task.isCancelled, generation == id else { prepared.discard(); return }
            let player = session?.player ?? AVPlayer()
            session?.stop()
            let active = PlaybackSession(prepared: prepared, player: player)
            session = active
            item = prepared.item
            markers = MediaChapterMarkerResolver.resolve(from: prepared.item.chapters)
            active.onTimeChanged = { [weak self] in
                Task { @MainActor [weak self] in await self?.prefetchNextEpisodeIfNeeded() }
            }
            await active.start()
        } catch {
            guard !Task.isCancelled, generation == id else { return }
            preparationError = "This video could not be loaded. Please try again."
        }
    }

    func cleanupForSwitch() { stopPlaybackImmediately() }

    func stopPlaybackImmediately() {
        preferredAudioLanguage = session?.audioLanguage ?? preferredAudioLanguage
        generation = UUID()
        loadTask?.cancel()
        loadTask = nil
        session?.stop()
        nextEpisode = nil
        isFetchingNextEpisode = false
        isLoading = false
    }

    func finishStoppingPlayback() async { await session?.finishStopping() }
    func reportProgress() async { await session?.reportProgress() }

    func didEnterBackground() {
        session?.didEnterBackground()
        Task { await reportProgress() }
    }

    func didBecomeActive() { session?.didBecomeActive() }

    var skipIntroTargetSeconds: Double? {
        guard let introRange = markers.introRangeSeconds else { return nil }
        guard currentSeconds >= max(0, introRange.lowerBound - 2), currentSeconds < introRange.upperBound else { return nil }
        return introRange.upperBound
    }

    var shouldShowSkipIntro: Bool { skipIntroTargetSeconds != nil }

    var shouldShowNextEpisode: Bool {
        guard item.type == .episode, !isAutoLoadingNext, durationSeconds > 0 else { return false }
        return currentSeconds >= (markers.creditsStartSeconds ?? max(0, durationSeconds - 60))
    }

    func skipIntro() async {
        guard let player, let seconds = skipIntroTargetSeconds else { return }
        await player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func transitionToNextEpisode() async {
        guard item.type == .episode, !isAutoLoadingNext else { return }
        let next = nextEpisode
        let finishedItem = item
        // Stop before the async episode lookup so AVKit cannot restart the old item.
        stopPlaybackImmediately()
        let switchGeneration = generation
        isAutoLoadingNext = true
        defer { isAutoLoadingNext = false }
        let episode: BaseItemDto?
        if let next { episode = next }
        else { episode = try? await JFAPI.loadNextEpisode(after: finishedItem) }
        guard generation == switchGeneration, !Task.isCancelled,
              let episode, episode.id != finishedItem.id else { return }
        item = episode
        await load()
    }

    func transition(to episode: BaseItemDto) async {
        guard !isAutoLoadingNext else { return }
        if episode.id == item.id { player?.play(); return }
        stopPlaybackImmediately()
        isAutoLoadingNext = true
        defer { isAutoLoadingNext = false }
        item = episode
        await load()
    }

    private func prefetchNextEpisodeIfNeeded() async {
        guard item.type == .episode, nextEpisode == nil, !isFetchingNextEpisode,
              durationSeconds > 0, durationSeconds - currentSeconds <= 120 else { return }
        let id = item.id
        let activeGeneration = generation
        isFetchingNextEpisode = true
        let next = try? await JFAPI.loadNextEpisode(after: item)
        guard generation == activeGeneration, item.id == id else { return }
        isFetchingNextEpisode = false
        nextEpisode = next
    }
}
