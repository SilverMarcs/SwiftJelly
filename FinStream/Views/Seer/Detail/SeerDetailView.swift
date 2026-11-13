//
//  SeerDetailView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct SeerDetailView: View {
    #if os(iOS)
    @Environment(\.detailZoomNamespace) private var detailZoomNamespace
    #endif

    @State private var vm: SeerDetailViewModel

    init(reference: SeerMediaReference) {
        self._vm = State(initialValue: SeerDetailViewModel(reference: reference))
    }

    var body: some View {
        if let libraryItem = vm.libraryItem {
            SeerLibraryDestinationView(item: libraryItem)
        } else {
            seerDetail
        }
    }

    private var seerDetail: some View {
        DetailView(item: vm.item) {
            VStack(spacing: spacing) {
                if vm.reference.mediaType == .tv {
                    SeerSeasonsView(vm: vm)
                }

                SeerCastView(cast: vm.cast)
            }
        } heroView: {
            SeerDetailHeroView(vm: vm)
        }
        .overlay {
            if let errorMessage = vm.errorMessage, vm.item.name == nil {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
                .focusable(true)
            }
        }
        .task {
            await vm.refresh()
        }
        .task(id: vm.isProcessing) {
            await vm.pollWhileProcessing()
        }
        .refreshToolbar {
            await vm.refresh()
        }
        #if os(iOS)
        .zoomTransitionDestination(sourceID: vm.reference.itemID, in: detailZoomNamespace)
        #endif
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        150
        #else
        30
        #endif
    }
}
