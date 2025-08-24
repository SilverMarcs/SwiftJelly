//
//  LocalMediaRow.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import SwiftUI

struct LocalMediaRow: View {
    let file: LocalMediaFile
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        Button {
            let mediaItem = MediaItem.local(file)
            #if os(macOS)
            dismissWindow(id: "media-player")
            openWindow(id: "media-player", value: mediaItem)
            #endif
        } label: {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.accent)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        if let durationSeconds = file.durationSeconds {
                            Text(durationSeconds.timeString())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if file.savedPosition > 0 {
                            if file.isCompleted {
                                Text("Watched")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Resume at \(file.savedPosition.timeString())")
                                    .font(.caption)
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if file.savedPosition > 0 {
                Button("Clear Progress", systemImage: "arrow.counterclockwise") {
                    LocalMediaManager.shared.clearPlaybackData(for: file)
                }
            }
            
            Button("Remove from Recent", systemImage: "trash", role: .destructive) {
                LocalMediaManager.shared.removeRecentFile(file)
            }
        }
    }
}
