//
//  Environment++.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var refresh: (() async -> Void) = {
        print("No refresh passed")
    }
    
    @Entry var isInSeasonView: Bool = false

    #if os(iOS)
    /// Namespace used to zoom media cards into their detail views.
    @Entry var detailZoomNamespace: Namespace.ID? = nil

    /// Namespace used to zoom play buttons into the full screen player.
    @Entry var playerZoomNamespace: Namespace.ID? = nil
    #endif
}

#if os(iOS)
extension View {
    /// Marks this view as the source of a zoom navigation transition.
    ///
    /// Applies `matchedTransitionSource(id:in:)` only when a namespace is
    /// available in the environment, otherwise it is a no-op. The zoom
    /// transition is only supported on iOS.
    @ViewBuilder
    func zoomTransitionSource(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Applies a zoom navigation transition to a pushed or presented view,
    /// zooming from the matching `matchedTransitionSource`.
    ///
    /// No-op when the namespace is unavailable. The zoom transition is only
    /// supported on iOS.
    @ViewBuilder
    func zoomTransitionDestination(sourceID: some Hashable, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
    }
}
#endif
