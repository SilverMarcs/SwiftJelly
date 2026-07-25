//
//  OptionalFocusedModifier.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

#if os(tvOS)
import SwiftUI

extension View {
    /// Applies `.focused` only when a binding is supplied, so a view can accept an
    /// optional externally-owned `FocusState` (e.g. a hero Play button whose focus
    /// a parent needs to drive) without requiring one.
    @ViewBuilder
    func focused(optional binding: FocusState<Bool>.Binding?) -> some View {
        if let binding {
            self.focused(binding)
        } else {
            self
        }
    }
}
#endif
