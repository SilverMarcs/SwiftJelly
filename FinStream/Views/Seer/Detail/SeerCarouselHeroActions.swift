//
//  SeerCarouselHeroActions.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct SeerCarouselHeroActions: View {
    let item: BaseItemDto
    let reference: SeerMediaReference
    var externalFocusNamespace: Namespace.ID? = nil
    var playFocus: FocusState<Bool>.Binding? = nil

    @State private var model: SeerRequestViewModel

    init(
        item: BaseItemDto,
        reference: SeerMediaReference,
        externalFocusNamespace: Namespace.ID? = nil,
        playFocus: FocusState<Bool>.Binding? = nil
    ) {
        self.item = item
        self.reference = reference
        self.externalFocusNamespace = externalFocusNamespace
        self.playFocus = playFocus
        self._model = State(initialValue: SeerRequestViewModel(reference: reference))
    }

    var body: some View {
        SeerHeroActions(
            model: model,
            infoItem: item,
            usesGlassContainer: true,
            externalFocusNamespace: externalFocusNamespace,
            playFocus: playFocus
        )
        .task(id: reference) {
            if model.reference != reference {
                model = SeerRequestViewModel(reference: reference)
            }
            await model.load()
        }
    }
}
