//
//  LocalMediaRow.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import SwiftUI

struct LocalMediaRow: View {
    let file: LocalMediaFile
    
    @Environment(LocalMediaManager.self) var localMediaManager
    @Environment(\.refresh) private var refresh
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    // Calculate progress as a value between 0 and 1
    private var progress: Double {
        guard let duration = file.durationSeconds, duration > 0 else { return 0 }
        return min(Double(file.savedPosition) / Double(duration), 1.0)
    }
    
    var body: some View {
        PlayMediaButton(item: file) {
            HStack(spacing: 5) {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.accent)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if file.savedPosition > 0 {
                        Gauge(value: progress) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        } minimumValueLabel: {
                            EmptyView()
                        } maximumValueLabel: {
                            EmptyView()
                        }
                        .controlSize(.mini)
                        .gaugeStyle(.accessoryLinearCapacity)
                        .tint(file.isCompleted ? .green : .accent)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Remove from Recent", systemImage: "trash", role: .destructive) {
                localMediaManager.removeRecentFile(file)
            }
        }
    }

    private var subtitleText: String {
        var components: [String] = []
        
        if let durationSeconds = file.durationSeconds {
            components.append(durationSeconds.timeString())
        }
        
        if file.savedPosition > 0 {
            if file.isCompleted {
                components.append("Watched")
            } else {
                components.append("Resume at \(file.savedPosition.timeString())")
            }
        }
        
        return components.joined(separator: " • ")
    }
}
