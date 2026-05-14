//
//  PlaybackManager+RemoteCommands.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 11/01/2026.
//

import AVFoundation
import MediaPlayer

extension PlaybackManager {
    /// Registers MPRemoteCommandCenter handlers exactly once. Targets are persistent for the
    /// app's lifetime; commands route to whatever player the active view model currently owns.
    func registerRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            guard let player = self?.viewModel?.player else { return .commandFailed }
            player.play()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            guard let player = self?.viewModel?.player else { return .commandFailed }
            player.pause()
            return .success
        }

        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let player = self?.viewModel?.player else { return .commandFailed }
            if player.timeControlStatus == .playing {
                player.pause()
            } else {
                player.play()
            }
            return .success
        }

        center.skipForwardCommand.preferredIntervals = [10]
        center.skipForwardCommand.addTarget { [weak self] event in
            guard let player = self?.viewModel?.player else { return .commandFailed }
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 10
            let target = player.currentTime() + CMTime(seconds: interval, preferredTimescale: 600)
            player.seek(to: target) { _ in
                self?.viewModel?.updateNowPlayingPlaybackInfo()
            }
            return .success
        }

        center.skipBackwardCommand.preferredIntervals = [10]
        center.skipBackwardCommand.addTarget { [weak self] event in
            guard let player = self?.viewModel?.player else { return .commandFailed }
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 10
            let target = player.currentTime() - CMTime(seconds: interval, preferredTimescale: 600)
            player.seek(to: target) { _ in
                self?.viewModel?.updateNowPlayingPlaybackInfo()
            }
            return .success
        }

        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let player = self?.viewModel?.player,
                  let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let target = CMTime(seconds: event.positionTime, preferredTimescale: 600)
            player.seek(to: target) { _ in
                self?.viewModel?.updateNowPlayingPlaybackInfo()
            }
            return .success
        }
    }
}
