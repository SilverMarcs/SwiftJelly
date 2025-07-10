//
//  ProgressBarOverlay.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ProgressBarOverlay: View {
    let item: BaseItemDto

    var body: some View {
        HStack(spacing: 12) {
            if item.userData?.isPlayed == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.accent)
                if let progress = item.playbackProgress, progress > 0, progress < 1 {
                    ProgressView(value: progress)
                        .controlSize(.small)
                        .frame(width: 60)
                }
                Text(item.totalDurationString ?? "--")
                    .font(.subheadline)
                
            } else {
                Image(systemName: "play.fill")
                    .font(.subheadline)
                
                if let progress = item.playbackProgress, progress > 0, progress < 1 {
                    ProgressView(value: progress)
                        .controlSize(.small)
                        .frame(width: 60)
                }
                
                Text(item.totalDurationString ?? "--")
                    .font(.subheadline)
            }
            
            Spacer()
            
//            Button(action: {}) {
//                Image(systemName: "ellipsis")
//                    .font(.title3)
//                    .foregroundStyle(.primary)
//                    .contentShape(.rect)
//            }
//            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
    }
}
