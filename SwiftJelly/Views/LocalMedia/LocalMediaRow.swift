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
                        if let duration = file.duration {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if file.savedPosition > 0 {
                            if file.isCompleted {
                                Text("Watched")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Resume at \(formatDuration(TimeInterval(file.savedPosition)))")
                                    .font(.caption)
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                    
                    // Progress bar
                    if let progress = file.progress, progress > 0.05 {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: file.isCompleted ? .green : .blue))
                            .scaleEffect(y: 0.5)
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
    
    // TODO: search for formatDuration
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
