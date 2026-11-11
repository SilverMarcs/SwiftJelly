//
//  OptionalFocusedModifier.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

#if os(tvOS)
import SwiftUI

extension View {
    @ViewBuilder
    func focused(optional binding: FocusState<Bool>.Binding?) -> some View {
        if let binding {
            focused(binding)
        } else {
            self
        }
    }
}
#endif
