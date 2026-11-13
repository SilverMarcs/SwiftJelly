//
//  SeerRequestPresentationModifier.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerRequestPresentationModifier: ViewModifier {
    @Bindable var model: SeerRequestViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $model.isSelectingSeasons) {
                SeerSeasonRequestView(model: model)
            }
            .alert("Request Failed", isPresented: errorBinding) {
                Button("OK", role: .cancel) { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "")
            }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }
}

extension View {
    func seerRequestPresentation(_ model: SeerRequestViewModel) -> some View {
        modifier(SeerRequestPresentationModifier(model: model))
    }
}
