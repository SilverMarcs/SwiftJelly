//
//  LocalMediaView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import SwiftUI

struct LocalMediaView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var localMediaManager = LocalMediaManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // File picker button
                LocalMediaFilePicker()
                
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
                                dismissWindow(id: "media-player")
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
