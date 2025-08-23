//
//  LocalMediaView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import SwiftUI

struct LocalMediaView: View {
    @State private var localMediaManager = LocalMediaManager.shared
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // File picker button
                LocalMediaFilePicker { file in
                    Task {
                        let enhancedFile = await localMediaManager.getEnhancedMetadata(for: file)
                        localMediaManager.addRecentFile(enhancedFile)
                        let mediaItem = MediaItem.local(enhancedFile)
                        #if os(macOS)
                        openWindow(id: "media-player", value: mediaItem)
                        #endif
                    }
                }
                
                // Recent files list
                if !localMediaManager.recentFiles.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Recent Files")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        List(localMediaManager.recentFiles, id: \.url) { file in
                            LocalMediaRow(file: file) {
                                let mediaItem = MediaItem.local(file)
                                #if os(macOS)
                                openWindow(id: "media-player", value: mediaItem)
                                #endif
                            }
                        }
                    }
                } else {
                    Spacer()
                    
                    ContentUnavailableView(
                        "No Recent Media",
                        systemImage: "play.rectangle",
                        description: Text("Use the button above to open local media files")
                    )
                    
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Local Media")
        }
    }
}


#Preview {
    LocalMediaView()
}
