//
//  MediaPlaybackViewModel+NowPlaying.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 11/01/2026.
//

import AVFoundation
import JellyfinAPI
import MediaPlayer
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformImage = NSImage
#endif

extension MediaPlaybackViewModel {
    func attachNowPlayingObservers(to player: AVPlayer) {
        rateObservation = player.observe(\.rate, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.updateNowPlayingPlaybackInfo() }
        }
        statusObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.updateNowPlayingPlaybackInfo() }
        }
        durationObservation = player.observe(\.currentItem?.duration, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.updateNowPlayingPlaybackInfo() }
        }
    }

    func detachNowPlayingObservers() {
        rateObservation = nil
        statusObservation = nil
        durationObservation = nil
    }

    func updateNowPlayingMetadata(for item: BaseItemDto) async {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = item.nowPlayingTitle
        if let subtitle = item.nowPlayingSubtitle {
            info[MPMediaItemPropertyArtist] = subtitle
        }
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue

        if let image = await item.loadNowPlayingArtwork() {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        // Don't clobber playback fields written by updateNowPlayingPlaybackInfo
        guard self.item.id == item.id else { return }
        for (key, value) in info {
            nowPlayingInfo[key] = value
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = .playing
    }

    func updateNowPlayingPlaybackInfo() {
        guard let player else { return }

        let elapsed = player.currentTime().seconds
        if elapsed.isFinite {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        }

        let duration = durationSeconds
        if duration.isFinite, duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = (player.rate > 0) ? .playing : .paused
    }

    func clearNowPlayingInfo() {
        nowPlayingInfo = [:]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
}

private extension BaseItemDto {
    var nowPlayingTitle: String {
        if type == .movie {
            return name ?? "Unknown"
        } else {
            return seriesName ?? name ?? "Unknown"
        }
    }

    var nowPlayingSubtitle: String? {
        guard type != .movie else { return nil }
        if let seasonEpisodeString {
            return "\(seasonEpisodeString) • \(name ?? "")"
        }
        return name
    }

    func loadNowPlayingArtwork() async -> PlatformImage? {
        guard let url = ImageURLProvider.imageURL(for: self, type: .primary) else {
            return nil
        }
        do {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            let (data, _) = try await URLSession.shared.data(for: request)
            return PlatformImage(data: data)
        } catch {
            return nil
        }
    }
}
