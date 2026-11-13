//
//  SeerLibraryProcessingChip.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import SwiftUI
import JellyfinAPI

/// Shows the Seer processing chip for a Jellyfin library item while Seer reports active downloads for it.
struct SeerLibraryProcessingChip: View {
    let item: BaseItemDto

    @State private var vm = SeerLibraryProgressViewModel()

    var body: some View {
        Group {
            if let progress = vm.downloadProgress {
                SeerProcessingChip(progress: progress)
            }
        }
        .task(id: item.id) {
            await vm.load(for: item)
        }
        .task(id: vm.downloadProgress != nil) {
            await vm.pollWhileDownloading()
        }
    }
}
