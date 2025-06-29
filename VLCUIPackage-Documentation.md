# VLCUIPackage Documentation

A comprehensive SwiftUI wrapper for VLCKit that provides a modern, declarative interface for video playback across iOS, macOS, and tvOS platforms.

## Overview

VLCUIPackage is a SwiftUI-based video player built on top of VLCKit, offering powerful video playback capabilities with a clean, modern API. It supports a wide range of video formats and provides extensive customization options for subtitles, audio tracks, playback controls, and more.

## Core Components

### VLCVideoPlayer

The main SwiftUI view that displays video content. It's a platform-agnostic representable view that works across iOS, macOS, and tvOS.

#### Basic Usage

```swift
import SwiftUI
import VLCUIPackage

struct VideoPlayerView: View {
    let videoURL = URL(string: "https://example.com/video.mp4")!
    
    var body: some View {
        VLCVideoPlayer(url: videoURL)
    }
}
```

#### Advanced Configuration

```swift
struct AdvancedVideoPlayerView: View {
    @StateObject private var proxy = VLCVideoPlayer.Proxy()
    
    var body: some View {
        VLCVideoPlayer { 
            VLCVideoPlayer.Configuration(
                url: videoURL,
                autoPlay: true,
                startSeconds: .seconds(30),
                aspectFill: false,
                replay: true,
                rate: .absolute(1.0),
                subtitleIndex: .auto,
                audioIndex: .auto
            )
        }
        .proxy(proxy)
        .onStateUpdated { state, info in
            print("Player state changed to: \(state)")
        }
        .onSecondsUpdated { duration, info in
            print("Current time: \(duration)")
        }
    }
}
```

## Configuration

### VLCVideoPlayer.Configuration

Comprehensive configuration options for video playback behavior.

#### Properties

- **url**: `URL` - The media URL to play
- **autoPlay**: `Bool` - Whether to start playback automatically (default: `true`)
- **startSeconds**: `Duration` - Starting position in the media (iOS 16.0+, macOS 13.0+, tvOS 16.0+)
- **aspectFill**: `Bool` - Whether to use aspect fill scaling (default: `false`)
- **replay**: `Bool` - Whether to replay the media when it ends (default: `false`)
- **rate**: `ValueSelector<Float>` - Playback rate (default: `.auto`)
- **subtitleIndex**: `ValueSelector<Int>` - Initial subtitle track (default: `.auto`)
- **audioIndex**: `ValueSelector<Int>` - Initial audio track (default: `.auto`)
- **subtitleSize**: `ValueSelector<Int>` - Subtitle font size (default: `.auto`)
- **subtitleFont**: `ValueSelector<PlatformFont>` - Subtitle font (default: `.auto`)
- **subtitleColor**: `ValueSelector<PlatformColor>` - Subtitle color (default: `.auto`)
- **playbackChildren**: `[PlaybackChild]` - Additional subtitle/audio files (default: `[]`)
- **options**: `[String: Any]` - VLC-specific options (default: `[:]`)

#### Value Selectors

The `ValueSelector<T>` enum allows for automatic or manual value selection:

- `.auto` - Let VLC automatically determine the best value
- `.absolute(value)` - Use a specific value

## Playback Control

### VLCVideoPlayer.Proxy

The proxy object provides programmatic control over video playback.

#### Basic Controls

```swift
@StateObject private var proxy = VLCVideoPlayer.Proxy()

// Basic playback controls
proxy.play()
proxy.pause()
proxy.stop()

// Seeking
proxy.jumpForward(10)  // Jump forward 10 seconds
proxy.jumpBackward(5)  // Jump backward 5 seconds
proxy.gotoNextFrame()  // Go to next frame (pauses video)

// Time control (iOS 16.0+, macOS 13.0+, tvOS 16.0+)
proxy.setSeconds(.seconds(120))  // Jump to 2 minutes
```

#### Track Management

```swift
// Audio and subtitle track selection
proxy.setAudioTrack(.absolute(1))
proxy.setSubtitleTrack(.absolute(0))

// Delay adjustments (iOS 16.0+, macOS 13.0+, tvOS 16.0+)
proxy.setAudioDelay(.milliseconds(500))
proxy.setSubtitleDelay(.milliseconds(-200))
```

#### Advanced Controls

```swift
// Playback rate
proxy.setRate(.absolute(1.5))  // 1.5x speed

// Aspect ratio
proxy.setAspectRatio(.widescreen16x9)

// Subtitle customization (iOS/tvOS only)
proxy.setSubtitleSize(.absolute(20))
proxy.setSubtitleFont(.absolute(UIFont.systemFont(ofSize: 18)))
proxy.setSubtitleColor(.absolute(.white))

// Aspect fill with percentage (iOS/tvOS only)
proxy.aspectFill(0.8)  // 80% aspect fill
```

## Media Information

### VLCVideoPlayer.PlaybackInformation

Comprehensive information about the current playback state and media properties.

#### Properties

- **startConfiguration**: `Configuration` - The initial configuration used
- **position**: `Float` - Current playback position (0.0 to 1.0)
- **length**: `Int` - Total media length in milliseconds
- **isSeekable**: `Bool` - Whether the media supports seeking
- **playbackRate**: `Float` - Current playback rate

#### Track Information

- **currentSubtitleTrack**: `MediaTrack` - Currently selected subtitle track
- **currentAudioTrack**: `MediaTrack` - Currently selected audio track
- **subtitleTracks**: `[MediaTrack]` - Available subtitle tracks
- **audioTracks**: `[MediaTrack]` - Available audio tracks

#### Statistics

- **numberOfReadBytesOnInput**: `Int` - Input bytes read
- **inputBitrate**: `Float` - Input bitrate
- **numberOfDecodedVideoBlocks**: `Int` - Decoded video blocks
- **numberOfDecodedAudioBlocks**: `Int` - Decoded audio blocks
- **numberOfDisplayedPictures**: `Int` - Displayed pictures
- **numberOfLostPictures**: `Int` - Lost pictures
- And more detailed playback statistics...

## Player States

### VLCVideoPlayer.State

Represents the current state of the video player:

- `.stopped` - Player is stopped
- `.opening` - Media is being opened
- `.buffering` - Media is buffering
- `.playing` - Media is playing
- `.paused` - Media is paused
- `.ended` - Media has ended
- `.error` - An error occurred
- `.esAdded` - Elementary stream added

## Event Handling

### State Updates

```swift
VLCVideoPlayer(url: videoURL)
    .onStateUpdated { state, playbackInfo in
        switch state {
        case .playing:
            print("Video started playing")
        case .paused:
            print("Video paused")
        case .ended:
            print("Video ended")
        case .error:
            print("Playback error occurred")
        default:
            break
        }
    }
```

### Time Updates

```swift
// Modern Duration-based API (iOS 16.0+, macOS 13.0+, tvOS 16.0+)
VLCVideoPlayer(url: videoURL)
    .onSecondsUpdated { duration, playbackInfo in
        let currentSeconds = duration.components.seconds
        let totalSeconds = playbackInfo.length / 1000
        print("Progress: \(currentSeconds)/\(totalSeconds) seconds")
    }
```

## Advanced Features

### Recording and Snapshots

```swift
@StateObject private var proxy = VLCVideoPlayer.Proxy()

// Save a snapshot
proxy.saveSnapshot(atPath: "/path/to/snapshots/")

// Start/stop recording
proxy.startRecording(atPath: "/path/to/recordings/")
proxy.stopRecording()
```

### Thumbnail Generation

```swift
@StateObject private var proxy = VLCVideoPlayer.Proxy()

Task {
    do {
        let thumbnail = try await proxy.fetchThumbnail(
            position: 0.5,  // 50% through the video
            size: CGSize(width: 320, height: 180)
        )
        // Use the thumbnail image
    } catch {
        print("Failed to generate thumbnail: \(error)")
    }
}
```

### External Subtitle and Audio Files

```swift
let subtitleChild = VLCVideoPlayer.PlaybackChild(
    url: URL(string: "https://example.com/subtitles.srt")!,
    type: .subtitle,
    enforce: true
)

let audioChild = VLCVideoPlayer.PlaybackChild(
    url: URL(string: "https://example.com/audio.mp3")!,
    type: .audio,
    enforce: false
)

VLCVideoPlayer {
    VLCVideoPlayer.Configuration(
        url: videoURL,
        playbackChildren: [subtitleChild, audioChild]
    )
}
```

## Aspect Ratios

### VLCVideoPlayer.AspectRatio

Predefined aspect ratios for video display:

- `.default` - Use original aspect ratio
- `.widescreen16x9` - 16:9 widescreen
- `.standard4x3` - 4:3 standard
- `.widescreen16x10` - 16:10 widescreen
- `.square1x1` - 1:1 square
- `.cinema221x1` - 2.21:1 cinema
- `.cinema235x1` - 2.35:1 cinema
- `.cinema239x1` - 2.39:1 cinema
- `.computer5x4` - 5:4 computer
- `.super16mm5x3` - 5:3 super 16mm
- `.cinema185x1` - 1.85:1 cinema
- `.cinema220x1` - 2.20:1 cinema

## Logging

### VLCVideoPlayerLogger Protocol

Implement custom logging for VLC events:

```swift
class CustomLogger: VLCVideoPlayerLogger {
    func vlcVideoPlayer(didLog message: String, at level: VLCVideoPlayer.LoggingLevel) {
        switch level {
        case .error:
            print("VLC Error: \(message)")
        case .warning:
            print("VLC Warning: \(message)")
        case .info:
            print("VLC Info: \(message)")
        case .debug:
            print("VLC Debug: \(message)")
        }
    }
}

// Usage
let logger = CustomLogger()
VLCVideoPlayer(url: videoURL)
    .logger(logger, level: .info)
```

## Platform Support

- **iOS**: 13.0+
- **macOS**: 10.15+
- **tvOS**: 13.0+

Some features require newer OS versions:
- Duration-based APIs require iOS 16.0+, macOS 13.0+, tvOS 16.0+
- Certain subtitle and aspect fill features are iOS/tvOS only

## Error Handling

### VLCVideoPlayer.ThumbnailError

Errors that can occur during thumbnail generation:

- `.noMedia` - No media is currently loaded
- `.timeout` - Thumbnail generation timed out

## Best Practices

1. **Use StateObject for Proxy**: Always use `@StateObject` for the proxy to ensure proper lifecycle management
2. **Handle State Changes**: Implement state change handlers to provide user feedback
3. **Modern APIs**: Use Duration-based APIs when targeting iOS 16.0+, macOS 13.0+, tvOS 16.0+
4. **Error Handling**: Always handle potential errors, especially for thumbnail generation and media loading
5. **Resource Management**: Properly manage video player instances to avoid memory leaks
6. **Testing**: Test with various media formats and network conditions

## Migration Notes

- Time-based APIs using `TimeSelector` are deprecated in favor of `Duration`-based APIs
- Use `onSecondsUpdated` instead of `onTicksUpdated` for modern applications
- Prefer `startSeconds` over `startTime` in configuration
