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

    /// Incremented each time the Search tab is selected or reselected, so `SearchView` can focus its field.
    @Entry var searchFocusRequest: Int = 0

    #if os(iOS)
    @Entry var detailZoomNamespace: Namespace.ID? = nil
    @Entry var playerZoomNamespace: Namespace.ID? = nil
    /// Opens Settings from the profile toolbar menu; `nil` when the profile menu shouldn't be shown.
    @Entry var profileToolbarSettingsAction: (() -> Void)? = nil
    #endif
}

#if os(iOS)
extension View {
    @ViewBuilder
    func zoomTransitionSource(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

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
