//
//  PlaybackDiagnostics.swift
//  SwiftJelly
//
//  Logging helpers used to diagnose playback failures (blank video plane,
//  silent AVPlayer errors, unsupported codecs/containers).
//

import AVFoundation
import Foundation
import JellyfinAPI
import os

nonisolated enum PlaybackLog {
    static let logger = Logger(subsystem: "de.finstream.playback", category: "Playback")

    /// Logs to both OSLog (visible in Console.app / `log stream`) and stdout so
    /// the messages also show up in the Xcode console for tvOS runs.
    static func log(_ message: String) {
        logger.log("\(message, privacy: .public)")
        print("[Playback] \(message)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        print("[Playback][ERROR] \(message)")
    }

    /// Describes the media streams of a source so unsupported codecs are obvious.
    static func describe(mediaSource: MediaSourceInfo) -> String {
        let streams = mediaSource.mediaStreams ?? []
        let streamDescriptions = streams.map { stream -> String in
            var parts: [String] = []
            parts.append("type=\(stream.type?.rawValue ?? "nil")")
            parts.append("index=\(stream.index.map(String.init) ?? "nil")")
            parts.append("codec=\(stream.codec ?? "nil")")
            if let profile = stream.profile { parts.append("profile=\(profile)") }
            if let level = stream.level { parts.append("level=\(level)") }
            if stream.type == .video {
                parts.append("size=\(stream.width.map(String.init) ?? "?")x\(stream.height.map(String.init) ?? "?")")
                if let range = stream.videoRange { parts.append("range=\(range.rawValue)") }
                if let fps = stream.realFrameRate { parts.append("fps=\(fps)") }
                if let bitDepth = stream.bitDepth { parts.append("bitDepth=\(bitDepth)") }
                parts.append("anamorphic=\(stream.isAnamorphic.map(String.init) ?? "nil")")
                parts.append("interlaced=\(stream.isInterlaced.map(String.init) ?? "nil")")
            }
            if stream.type == .audio {
                parts.append("channels=\(stream.channels.map(String.init) ?? "nil")")
                parts.append("lang=\(stream.language ?? "nil")")
            }
            if stream.type == .subtitle {
                parts.append("lang=\(stream.language ?? "nil")")
                parts.append("external=\(stream.isExternal.map(String.init) ?? "nil")")
            }
            if let bitrate = stream.bitRate { parts.append("bitrate=\(bitrate)") }
            return "{" + parts.joined(separator: " ") + "}"
        }

        var lines: [String] = []
        lines.append("mediaSource id=\(mediaSource.id ?? "nil") container=\(mediaSource.container ?? "nil") "
            + "protocol=\(mediaSource.protocol?.rawValue ?? "nil") "
            + "size=\(mediaSource.size.map(String.init) ?? "nil") "
            + "bitrate=\(mediaSource.bitrate.map(String.init) ?? "nil")")
        lines.append("  supportsDirectPlay=\(mediaSource.isSupportsDirectPlay.map(String.init) ?? "nil") "
            + "supportsDirectStream=\(mediaSource.isSupportsDirectStream.map(String.init) ?? "nil") "
            + "supportsTranscoding=\(mediaSource.isSupportsTranscoding.map(String.init) ?? "nil")")
        lines.append("  transcodingContainer=\(mediaSource.transcodingContainer ?? "nil") "
            + "transcodingSubProtocol=\(mediaSource.transcodingSubProtocol?.rawValue ?? "nil")")
        lines.append("  defaultAudioStreamIndex=\(mediaSource.defaultAudioStreamIndex.map(String.init) ?? "nil") "
            + "defaultSubtitleStreamIndex=\(mediaSource.defaultSubtitleStreamIndex.map(String.init) ?? "nil")")
        lines.append("  streams: " + (streamDescriptions.isEmpty ? "none" : streamDescriptions.joined(separator: " | ")))
        return lines.joined(separator: "\n")
    }

    /// Redacts the api key so URLs can be logged safely.
    static func sanitize(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return url.absoluteString
        }
        components.queryItems = queryItems.map { item in
            let sensitive = ["api_key", "apikey", "ApiKey", "Token", "X-Emby-Token"]
            guard sensitive.contains(where: { $0.caseInsensitiveCompare(item.name) == .orderedSame }) else { return item }
            return URLQueryItem(name: item.name, value: "<redacted>")
        }
        return components.url?.absoluteString ?? url.absoluteString
    }

    static func describe(error: Error?) -> String {
        guard let error else { return "nil" }

        if let decodingError = decodingError(in: error) {
            return "DecodingError " + describe(decodingError: decodingError)
        }

        let nsError = error as NSError
        var description = "\(nsError.domain) code=\(nsError.code) \(nsError.localizedDescription)"
        if let failureReason = nsError.localizedFailureReason {
            description += " reason=\(failureReason)"
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            description += " underlying=[\(underlying.domain) code=\(underlying.code) \(underlying.localizedDescription)]"
        }
        if let debugDescription = nsError.userInfo[NSDebugDescriptionErrorKey] as? String {
            description += " debug=\(debugDescription)"
        }
        return description
    }

    /// `JSONDecoder` failures usually arrive wrapped (Get's `DataLoaderError`,
    /// or bridged to NSCocoaErrorDomain 4864), which hides the one thing that
    /// matters: the coding path of the field that failed.
    private static func decodingError(in error: Error) -> DecodingError? {
        if let decodingError = error as? DecodingError { return decodingError }
        let nsError = error as NSError
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return decodingError(in: underlying)
        }
        return nil
    }

    private static func describe(decodingError: DecodingError) -> String {
        func path(_ context: DecodingError.Context) -> String {
            let codingPath = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "path=\(codingPath.isEmpty ? "<root>" : codingPath) detail=\(context.debugDescription)"
        }

        switch decodingError {
        case let .typeMismatch(type, context):
            return "typeMismatch expected=\(type) \(path(context))"
        case let .valueNotFound(type, context):
            return "valueNotFound expected=\(type) \(path(context))"
        case let .keyNotFound(key, context):
            return "keyNotFound key=\(key.stringValue) \(path(context))"
        case let .dataCorrupted(context):
            return "dataCorrupted \(path(context))"
        @unknown default:
            return "\(decodingError)"
        }
    }

    /// Logs the raw JSON the server sent, so an unexpected enum value or type
    /// is visible even when the decoder only reports a coding path.
    static func logRawPayload(_ data: Data, label: String, maxLength: Int = 20_000) {
        guard let json = String(data: data, encoding: .utf8) else {
            log("[\(label)] raw payload is not UTF-8 (\(data.count) bytes)")
            return
        }
        if json.count <= maxLength {
            log("[\(label)] raw payload (\(data.count) bytes):\n\(json)")
        } else {
            log("[\(label)] raw payload truncated to \(maxLength) of \(data.count) bytes:\n"
                + String(json.prefix(maxLength)))
        }
    }
}

/// Observes a single `AVPlayerItem` (and its player) and logs everything that
/// AVFoundation normally reports silently: status changes, decode errors,
/// stalls, and the error/access logs the HLS stack fills in.
nonisolated final class PlaybackItemDiagnostics: @unchecked Sendable {
    private let label: String
    private weak var player: AVPlayer?
    private weak var playerItem: AVPlayerItem?
    private var observations: [NSKeyValueObservation] = []
    private var notificationObservers: [NSObjectProtocol] = []

    init(player: AVPlayer, playerItem: AVPlayerItem, label: String) {
        self.player = player
        self.playerItem = playerItem
        self.label = label
        startObserving(player: player, playerItem: playerItem)
    }

    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func startObserving(player: AVPlayer, playerItem: AVPlayerItem) {
        observations.append(playerItem.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                PlaybackLog.log("[\(self.label)] item status=readyToPlay "
                    + "duration=\(item.duration.seconds) "
                    + "presentationSize=\(item.presentationSize.width)x\(item.presentationSize.height)")
            case .failed:
                PlaybackLog.error("[\(self.label)] item status=FAILED error=\(PlaybackLog.describe(error: item.error))")
                self.dumpErrorLog()
            case .unknown:
                PlaybackLog.log("[\(self.label)] item status=unknown")
            @unknown default:
                PlaybackLog.log("[\(self.label)] item status=@unknown(\(item.status.rawValue))")
            }
        })

        observations.append(playerItem.observe(\.presentationSize, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            let size = item.presentationSize
            PlaybackLog.log("[\(self.label)] presentationSize=\(size.width)x\(size.height)"
                + (size == .zero ? " (no video track rendering — audio-only or unsupported video codec)" : ""))
        })

        observations.append(playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            PlaybackLog.log("[\(self.label)] likelyToKeepUp=\(item.isPlaybackLikelyToKeepUp) "
                + "bufferEmpty=\(item.isPlaybackBufferEmpty) bufferFull=\(item.isPlaybackBufferFull)")
        })

        observations.append(player.observe(\.status, options: [.initial, .new]) { [weak self] player, _ in
            guard let self else { return }
            if player.status == .failed {
                PlaybackLog.error("[\(self.label)] player status=FAILED error=\(PlaybackLog.describe(error: player.error))")
            } else {
                PlaybackLog.log("[\(self.label)] player status=\(player.status.rawValue)")
            }
        })

        observations.append(player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard let self else { return }
            let reason = player.reasonForWaitingToPlay?.rawValue ?? "nil"
            PlaybackLog.log("[\(self.label)] timeControlStatus=\(player.timeControlStatus.rawValue) waitingReason=\(reason)")
        })

        addNotificationObserver(.AVPlayerItemFailedToPlayToEndTime, for: playerItem) { [weak self] notification in
            guard let self else { return }
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            PlaybackLog.error("[\(self.label)] failedToPlayToEndTime error=\(PlaybackLog.describe(error: error))")
            self.dumpErrorLog()
        }

        addNotificationObserver(.AVPlayerItemNewErrorLogEntry, for: playerItem) { [weak self] _ in
            guard let self else { return }
            guard let event = self.playerItem?.errorLog()?.events.last else { return }
            PlaybackLog.error("[\(self.label)] newErrorLogEntry: status=\(event.errorStatusCode) "
                + "domain=\(event.errorDomain) comment=\(event.errorComment ?? "nil") uri=\(event.uri ?? "nil")")
        }

        addNotificationObserver(.AVPlayerItemPlaybackStalled, for: playerItem) { [weak self] _ in
            guard let self else { return }
            PlaybackLog.error("[\(self.label)] playbackStalled")
            self.dumpErrorLog()
        }

        addNotificationObserver(.AVPlayerItemDidPlayToEndTime, for: playerItem) { [weak self] _ in
            guard let self else { return }
            PlaybackLog.log("[\(self.label)] didPlayToEndTime")
        }
    }

    private func addNotificationObserver(
        _ name: Notification.Name,
        for playerItem: AVPlayerItem,
        handler: @escaping @Sendable (Notification) -> Void
    ) {
        let observer = NotificationCenter.default.addObserver(
            forName: name,
            object: playerItem,
            queue: .main,
            using: handler
        )
        notificationObservers.append(observer)
    }

    private func dumpErrorLog() {
        guard let playerItem else { return }
        if let errorLog = playerItem.errorLog() {
            for event in errorLog.events {
                PlaybackLog.error("[\(label)] errorLog: status=\(event.errorStatusCode) "
                    + "domain=\(event.errorDomain) comment=\(event.errorComment ?? "nil") "
                    + "uri=\(event.uri ?? "nil")")
            }
        }
        if let accessLog = playerItem.accessLog(), let lastEvent = accessLog.events.last {
            PlaybackLog.log("[\(label)] accessLog: uri=\(lastEvent.uri ?? "nil") "
                + "indicatedBitrate=\(lastEvent.indicatedBitrate) observedBitrate=\(lastEvent.observedBitrate) "
                + "stalls=\(lastEvent.numberOfStalls) droppedFrames=\(lastEvent.numberOfDroppedVideoFrames)")
        }
    }
}
