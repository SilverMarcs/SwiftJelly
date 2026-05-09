//
//  KeepScreenAwake.swift
//  SwiftJelly
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Reference-counts callers that want the device awake. The idle timer is
/// disabled while at least one holder is active and re-enabled when the last
/// one releases — so nested screens (e.g. Downloads → a season-specific
/// downloads page) compose without one accidentally re-enabling sleep while
/// the other still wants it disabled.
@MainActor
final class IdleTimerCoordinator {
    static let shared = IdleTimerCoordinator()
    private var holders = 0

    func acquire() {
        holders += 1
        sync()
    }

    func release() {
        holders = max(0, holders - 1)
        sync()
    }

    private func sync() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = holders > 0
        #endif
    }
}

private struct KeepScreenAwakeModifier: ViewModifier {
    let active: Bool
    @State private var isHolding = false

    func body(content: Content) -> some View {
        content
            .onAppear { syncHolding(shouldHold: active) }
            .onDisappear { syncHolding(shouldHold: false) }
            .onChange(of: active) { _, newValue in
                syncHolding(shouldHold: newValue)
            }
    }

    private func syncHolding(shouldHold: Bool) {
        if shouldHold, !isHolding {
            IdleTimerCoordinator.shared.acquire()
            isHolding = true
        } else if !shouldHold, isHolding {
            IdleTimerCoordinator.shared.release()
            isHolding = false
        }
    }
}

extension View {
    /// Keeps the screen awake while this view is on-screen *and* `active` is
    /// true. Composes safely across nested views via reference-counting.
    func keepScreenAwakeWhile(_ active: Bool) -> some View {
        modifier(KeepScreenAwakeModifier(active: active))
    }
}
