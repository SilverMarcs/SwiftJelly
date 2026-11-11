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
    @Entry var detailZoomNamespace: Namespace.ID? = nil
    @Entry var playerZoomNamespace: Namespace.ID? = nil
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
