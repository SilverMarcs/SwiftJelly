//
//  SeerDetailHeroView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct SeerDetailHeroView: View {
    let vm: SeerDetailViewModel

    var body: some View {
        HeroBackdropView(item: vm.item) {
            SeerHeroActions(model: vm.requestModel)
                .redacted(reason: vm.item.name == nil ? .placeholder : [])
        }
    }
}
