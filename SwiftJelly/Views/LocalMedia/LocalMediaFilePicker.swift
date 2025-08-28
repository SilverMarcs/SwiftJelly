//
//  LocalMediaFilePicker.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct LocalMediaFilePicker: View {
    @State private var isPickerPresented = false
    
    @Environment(LocalMediaManager.self) var localMediaManager
    @Environment(\.refresh) private var refresh
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        Button("Open", role: .confirm) {
            isPickerPresented = true
        }
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [
                .movie,
                .video,
                .audio,
                UTType("public.audiovisual-content") ?? .data
            ],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let localFile = LocalMediaFile(url: url)

                    Task {
                        let enhancedFile = await localMediaManager.getEnhancedMetadata(for: localFile)
                        localMediaManager.addRecentFile(enhancedFile)
                        let mediaItem = MediaItem.local(enhancedFile)
                        RefreshHandlerContainer.shared.refresh = refresh
                        #if os(macOS)
                        dismissWindow(id: "media-player")
                        openWindow(id: "media-player", value: mediaItem)
                        #endif
                    }
                }
            case .failure(let error):
                print("Error selecting file: \(error)")
            }
        }
    }
}
