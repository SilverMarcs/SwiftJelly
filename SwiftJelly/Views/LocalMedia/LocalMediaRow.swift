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
            VStack(spacing: 8) {
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
                            
                            if file.savedPosition > 0 {
                                Text("•")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
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
                
                // Progress gauge - only show if there's saved progress
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
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Remove from Recent", systemImage: "trash", role: .destructive) {
                localMediaManager.removeRecentFile(file)
            }
        }
    }
}
