//
//  MatchedTransitionSourceModifier.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 06.12.25.
//
import SwiftUI

struct OptionalMatchedTransitionSourceViewModifier<ID: Hashable>: ViewModifier {
    var id: ID
    var animation: Namespace.ID?
    
    func body(content: Content) -> some View {
#if !os(iOS)
        content
#else
        if let animation = animation {
            content
                .matchedTransitionSource(id: id, in: animation)
        }
#endif
    }
}

extension View {
    public func optionalMatchedTransitionSource(id: some Hashable, in animation: Namespace.ID?) -> some View {
        modifier(OptionalMatchedTransitionSourceViewModifier(id: id, animation: animation))
    }
}
