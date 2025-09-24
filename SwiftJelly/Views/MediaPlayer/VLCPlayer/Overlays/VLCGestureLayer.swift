import SwiftUI
import VLCUI

#if os(iOS)
import UIKit
import MediaPlayer
import AVFoundation
import Combine

// Internal helper to control system volume via MPVolumeView
final class VolumeManager: ObservableObject {
    weak var slider: UISlider?
    func setVolume(_ value: Float) {
        let clamped = max(0, min(1, value))
        slider?.setValue(clamped, animated: false)
        slider?.sendActions(for: .valueChanged)
    }
}

struct SystemVolumeView: UIViewRepresentable {
    @ObservedObject var manager: VolumeManager
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsRouteButton = false
        view.isHidden = true
        // Grab the internal slider
        if let slider = view.subviews.compactMap({ $0 as? UISlider }).first {
            manager.slider = slider
        } else {
            // Fallback: search asynchronously after layout
            DispatchQueue.main.async {
                if let slider = view.subviews.compactMap({ $0 as? UISlider }).first {
                    manager.slider = slider
                }
            }
        }
        return view
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

struct VLCGestureLayer: View {
    let proxy: VLCVideoPlayer.Proxy
    // Notify parent to suppress single-tap overlay toggle
    var onDoubleTap: (() -> Void)?

    @StateObject private var volumeManager = VolumeManager()
    @State private var leftStartBrightness: CGFloat = UIScreen.main.brightness
    @State private var rightStartVolume: Float = AVAudioSession.sharedInstance().outputVolume

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Hidden MPVolumeView to allow programmatic volume change
                SystemVolumeView(manager: volumeManager)
                    .frame(width: 0, height: 0)
                    .opacity(0.01)

                HStack(spacing: 0) {
                    // Left half: double-tap backward 10s, vertical swipe -> brightness
                    Color.clear
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            TapGesture(count: 2)
                                .onEnded { 
                                    onDoubleTap?()
                                    proxy.jumpBackward(.seconds(10))
                                }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                                .onChanged { value in
                                    // track start values when drag begins
                                    if value.startLocation == value.location { return }
                                    let height = max(1, geo.size.height)
                                    // Negative translation.height = swipe up => increase
                                    let delta = -value.translation.height / height
                                    let newBrightness = leftStartBrightness + (delta * 1.2) // slightly faster ramp
                                    UIScreen.main.brightness = max(0, min(1, newBrightness))
                                }
                                .onEnded { _ in
                                    // persist the new baseline
                                    leftStartBrightness = UIScreen.main.brightness
                                }
                        )

                    // Right half: double-tap forward 10s, vertical swipe -> volume
                    Color.clear
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            TapGesture(count: 2)
                                .onEnded { 
                                    onDoubleTap?()
                                    proxy.jumpForward(.seconds(10))
                                }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                                .onChanged { value in
                                    if value.startLocation == value.location { return }
                                    let height = max(1, geo.size.height)
                                    let delta = -Float(value.translation.height / height)
                                    let newVolume = rightStartVolume + (delta * 1.2)
                                    volumeManager.setVolume(newVolume)
                                }
                                .onEnded { _ in
                                    rightStartVolume = AVAudioSession.sharedInstance().outputVolume
                                }
                        )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
    }
}
#endif
