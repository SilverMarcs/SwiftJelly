//
//  SeerHeroActions.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct SeerHeroActions: View {
    let model: SeerRequestViewModel
    var infoItem: BaseItemDto? = nil
    var usesGlassContainer = false
    var externalFocusNamespace: Namespace.ID? = nil
    var playFocus: FocusState<Bool>.Binding? = nil

    @Namespace private var actionButtonsNamespace

    var body: some View {
        container {
            HStack(spacing: spacing) {
                requestButton

                #if os(tvOS)
                if let infoItem {
                    HeroInfoButton(item: infoItem)
                }
                #endif

                if let libraryItem = model.libraryItem {
                    SeerLibraryButton(item: libraryItem)
                }
            }
        }
        .seerRequestPresentation(model)
        #if os(tvOS)
        .focusScope(focusNamespace)
        #endif
    }

    @ViewBuilder
    private var requestButton: some View {
        #if os(tvOS)
        SeerRequestButton(model: model)
            .prefersDefaultFocus(in: focusNamespace)
            .focused(optional: playFocus)
        #else
        SeerRequestButton(model: model)
        #endif
    }

    #if os(tvOS)
    private var focusNamespace: Namespace.ID {
        externalFocusNamespace ?? actionButtonsNamespace
    }
    #endif

    @ViewBuilder
    private func container<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if usesGlassContainer {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        15
        #elseif os(macOS)
        8
        #else
        usesGlassContainer ? 6 : 10
        #endif
    }
}
