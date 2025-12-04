//
//  ViewFirstAppearModifier.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 04.12.25.
//
import SwiftUI

public extension View {
//    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
//        onFirstAppearAsync {
//            action()
//        }
//    }
    
    func onFirstAppear(perform action: @escaping @Sendable () async -> Void) -> some View {
        modifier(ViewFirstAppearAsyncModifier(perform: action))
    }
}

struct ViewFirstAppearAsyncModifier: ViewModifier {
    @State private var didAppearBefore = false
    private let action: @Sendable () async -> Void

    init(perform action: @escaping @Sendable () async -> Void) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content.onAppear {
            if didAppearBefore == false {
                didAppearBefore = true
                Task {
                    await action()
                }
            }
        }
    }
}
