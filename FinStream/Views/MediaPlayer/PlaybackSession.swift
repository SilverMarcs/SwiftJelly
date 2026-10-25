import AVFoundation
import JellyfinAPI
import Observation

/// One owner for the player, native selection, reporting, and local/server resources.
@MainActor
@Observable final class PlaybackSession {
    let player: AVPlayer
    private(set) var prepared: PreparedPlayback
    private(set) var currentSeconds: Double
    private(set) var durationSeconds: Double
    private(set) var isStopped = false
    private(set) var errorDescription: String?
    private(set) var audioIndex: Int?
    private(set) var subtitleIndex: Int?
    private(set) var audioLanguage: String?
    var onTimeChanged: (() -> Void)?

    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var selectionObserver: NSObjectProtocol?
    @ObservationIgnored private var statusObserver: NSKeyValueObservation?
    @ObservationIgnored private var controlObserver: NSKeyValueObservation?
    @ObservationIgnored private var reportTask: Task<Void, Never>?
    @ObservationIgnored private var recoveryTask: Task<Void, Never>?
    @ObservationIgnored private var resumeTask: Task<Void, Never>?
    @ObservationIgnored private var resumeGeneration = UUID()
    @ObservationIgnored private var hasReportedStart = false
    @ObservationIgnored private var lastProgressDate = Date.distantPast
    @ObservationIgnored private var recoveryAttempted = false
    @ObservationIgnored private var isInBackground = false
    @ObservationIgnored private var wasBackgrounded = false

    init(prepared: PreparedPlayback, player: AVPlayer) {
        self.prepared = prepared
        self.player = player
        currentSeconds = prepared.resumeSeconds
        durationSeconds = Double(prepared.info.mediaSource.runTimeTicks ?? prepared.item.runTimeTicks ?? 0) / 10_000_000
    }

    func start(rate: Float = 1, subtitleIndex: Int? = nil) async {
        guard !isStopped else { return }
        let item = prepared.playerItem
        player.pause()
        player.replaceCurrentItem(with: item)
        if let index = prepared.initialAudioIndex, let group = prepared.selection.audioGroup,
           let option = prepared.selection.audioIndices.first(where: { $0.value == index })?.key {
            item.select(option, in: group)
        }
        if let subtitleIndex, let group = prepared.selection.subtitleGroup {
            if subtitleIndex == -1 { item.select(nil, in: group) }
            else if let option = prepared.selection.subtitleIndices.first(where: { $0.value == subtitleIndex })?.key {
                item.select(option, in: group)
            }
        }
        player.automaticallyWaitsToMinimizeStalling = true
        item.preferredForwardBufferDuration = 30
        #if os(macOS)
        player.preventsDisplaySleepDuringVideoPlayback = true
        #else
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        observePlayer()
        await player.seek(to: CMTime(seconds: max(0, prepared.resumeSeconds), preferredTimescale: 600))
        guard !isStopped, !Task.isCancelled, player.currentItem === item else { return }
        player.rate = rate
    }

    func stop() {
        guard !isStopped else { return }
        let snapshot = reportState()
        isStopped = true
        recoveryTask?.cancel()
        resumeTask?.cancel()
        removeObservers()
        if player.currentItem === prepared.playerItem {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        prepared.adapter?.stop()
        let priorReport = reportTask
        let context = prepared.context
        let ids = prepared.encodingSessionIDs
        let reported = hasReportedStart
        reportTask = Task {
            await priorReport?.value
            guard let context else { return }
            if reported { await JFAPI.reportPlaybackStopped(context: context, state: snapshot) }
            await JFAPI.stopPlaybackEncodings(context: context, sessionIDs: ids)
        }
    }

    func finishStopping() async { await reportTask?.value }

    func didEnterBackground() {
        guard !isStopped else { return }
        isInBackground = true
        wasBackgrounded = true
        resumeTask?.cancel()
    }

    func didBecomeActive() {
        guard !isStopped, wasBackgrounded else { return }
        isInBackground = false
        wasBackgrounded = false
        let previous = resumeTask
        let generation = UUID()
        resumeGeneration = generation
        let item = prepared.playerItem
        resumeTask = Task { [weak self] in
            // Serialize rapid background/foreground transitions so cancellation
            // of an older start cannot close the replacement listener.
            await previous?.value
            guard let self else { return }
            defer { if self.resumeGeneration == generation { self.resumeTask = nil } }
            guard !Task.isCancelled, !self.isStopped, !self.isInBackground, self.player.currentItem === item else { return }
            do {
                if let adapter = self.prepared.adapter {
                    try await adapter.restart()
                }
                guard !Task.isCancelled, !self.isStopped, !self.isInBackground, self.player.currentItem === item else { return }
                // A failed AVPlayerItem cannot be revived by a listener restart.
                if item.status == .failed { self.recover(mode: .automatic) }
                else if self.prepared.adapter != nil, self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    // Refresh waiting playback at its current position once
                    // the local playlists are available again.
                    let time = self.player.currentTime()
                    let rate = self.player.rate > 0 ? self.player.rate : self.player.defaultRate
                    let finished = await self.player.seek(to: time.seconds.isFinite ? time : CMTime(seconds: self.currentSeconds, preferredTimescale: 600))
                    guard !Task.isCancelled, !self.isStopped, !self.isInBackground, self.player.currentItem === item else { return }
                    if item.status == .failed { self.recover(mode: .automatic) }
                    else if finished, self.player.timeControlStatus != .paused { self.player.playImmediately(atRate: rate) }
                }
            } catch {
                guard !Task.isCancelled, !self.isStopped, !self.isInBackground, self.player.currentItem === item else { return }
                self.recover(mode: .automatic)
            }
        }
    }

    func reportProgress() async {
        guard !isStopped, hasReportedStart, let context = prepared.context else { return }
        let snapshot = reportState()
        let priorReport = reportTask
        lastProgressDate = .now
        let task = Task {
            await priorReport?.value
            await JFAPI.reportPlaybackProgress(context: context, state: snapshot)
        }
        reportTask = task
        await task.value
    }

    private func observePlayer() {
        let item = prepared.playerItem
        selectionObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.mediaSelectionDidChangeNotification, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateSelection()
                await self?.reportProgress()
            }
        }
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isStopped, self.player.currentItem === item, item.status == .failed else { return }
                self.handleFailure()
            }
        }
        controlObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in await self?.reportPlaybackState() }
        }
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, !self.isStopped, self.player.currentItem === item else { return }
                if time.seconds.isFinite { self.currentSeconds = max(0, time.seconds) }
                let duration = self.prepared.playerItem.duration.seconds
                if duration.isFinite && duration > 0 { self.durationSeconds = duration }
                self.onTimeChanged?()
                if Date.now.timeIntervalSince(self.lastProgressDate) >= 10 { await self.reportPlaybackState() }
            }
        }
        updateSelection()
    }

    private func updateSelection() {
        let selection = prepared.selection
        if let group = selection.audioGroup, let option = prepared.playerItem.currentMediaSelection.selectedMediaOption(in: group) {
            audioIndex = selection.audioIndices[option]
            audioLanguage = option.extendedLanguageTag
        } else if selection.audioGroup == nil {
            let streams = prepared.info.mediaSource.mediaStreams?.filter { $0.type == .audio } ?? []
            audioIndex = streams.count == 1 ? streams.first?.index : (prepared.info.playMethod == .transcode ? prepared.initialAudioIndex : nil)
            audioLanguage = streams.first(where: { $0.index == audioIndex })?.language
        } else {
            audioIndex = nil
            audioLanguage = nil
        }
        if let group = selection.subtitleGroup {
            if let option = prepared.playerItem.currentMediaSelection.selectedMediaOption(in: group) {
                subtitleIndex = selection.subtitleIndices[option]
            } else { subtitleIndex = -1 }
        } else { subtitleIndex = -1 }
    }

    private func reportPlaybackState() async {
        guard !isStopped, player.currentItem === prepared.playerItem, let context = prepared.context else { return }
        if !hasReportedStart {
            guard player.timeControlStatus == .playing else { return }
            hasReportedStart = true
            lastProgressDate = .now
            let snapshot = reportState()
            let previous = reportTask
            let task = Task {
                await previous?.value
                await JFAPI.reportPlaybackStart(context: context, state: snapshot)
            }
            reportTask = task
            await task.value
        } else { await reportProgress() }
    }

    private func reportState() -> PlaybackProgressInfo {
        updateSelection()
        let seconds = player.currentItem === prepared.playerItem ? player.currentTime().seconds : currentSeconds
        return PlaybackProgressInfo(audioStreamIndex: audioIndex, canSeek: durationSeconds > 0, isMuted: player.isMuted, isPaused: player.timeControlStatus == .paused, itemID: prepared.info.itemID, mediaSourceID: prepared.info.mediaSource.id, playMethod: prepared.info.playMethod == .directPlay ? .directPlay : .transcode, playSessionID: prepared.info.playSessionId, positionTicks: Int(max(0, seconds.isFinite ? seconds : currentSeconds) * 10_000_000), subtitleStreamIndex: subtitleIndex)
    }

    private func handleFailure() {
        // A suspended local listener or expired server stream needs fresh
        // resources, rather than permanently abandoning native media selection.
        guard !isInBackground, resumeTask == nil, recoveryTask == nil else { return }
        updateSelection()
        guard case .adapted = prepared.outcome, !recoveryAttempted else {
            errorDescription = "This video could not be played. Please try again."
            return
        }
        recoveryAttempted = true
        recover(mode: .original)
    }

    private func recover(mode: PlaybackPreparer.Mode) {
        guard !isStopped, recoveryTask == nil else { return }
        updateSelection()
        let savedSubtitleIndex = subtitleIndex
        let savedRate = player.timeControlStatus == .paused ? 0 : (player.rate > 0 ? player.rate : player.defaultRate)
        recoveryTask = Task { [weak self] in
            guard let self else { return }
            defer { self.recoveryTask = nil }
            do {
                let replacement = try await PlaybackPreparer.prepare(for: self.prepared.item, preferredLanguage: self.audioLanguage, audioIndex: self.audioIndex, resumeSeconds: self.currentSeconds, context: self.prepared.context, mode: mode)
                guard !self.isStopped, !self.isInBackground, !Task.isCancelled else { replacement.discard(); return }
                if self.hasReportedStart, let context = self.prepared.context {
                    let snapshot = self.reportState()
                    let priorReport = self.reportTask
                    self.reportTask = Task {
                        await priorReport?.value
                        await JFAPI.reportPlaybackStopped(context: context, state: snapshot)
                    }
                }
                self.hasReportedStart = false
                self.audioIndex = nil
                self.subtitleIndex = nil
                self.removeObservers()
                self.prepared.discard()
                self.prepared = replacement
                self.currentSeconds = replacement.resumeSeconds
                self.errorDescription = nil
                await self.start(rate: savedRate, subtitleIndex: savedSubtitleIndex)
            } catch {
                guard !self.isStopped, !Task.isCancelled else { return }
                self.errorDescription = "This video could not be played. Please try again."
            }
        }
    }

    private func removeObservers() {
        if let timeObserver { player.removeTimeObserver(timeObserver); self.timeObserver = nil }
        if let selectionObserver { NotificationCenter.default.removeObserver(selectionObserver); self.selectionObserver = nil }
        statusObserver?.invalidate()
        controlObserver?.invalidate()
        statusObserver = nil
        controlObserver = nil
    }
}
