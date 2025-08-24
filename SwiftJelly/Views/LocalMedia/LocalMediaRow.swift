//
//  LocalMediaRow.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import SwiftUI

struct LocalMediaRow: View {
    let file: LocalMediaFile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let duration = file.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(file.url.lastPathComponent)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
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
