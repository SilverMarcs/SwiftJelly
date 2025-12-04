//
//  EnvironmentKeys.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 04.12.25.
//

import SwiftUI

struct NavigationZoomNamespaceKey: EnvironmentKey {
    static var defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var zoomNamespace: Namespace.ID? {
        get { self[NavigationZoomNamespaceKey.self] }
        set { self[NavigationZoomNamespaceKey.self] = newValue }
    }
}
