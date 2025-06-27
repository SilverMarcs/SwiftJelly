//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import VLCUI

struct ContinueWatchingView: View {
    @StateObject private var continueWatchingManager = ContinueWatchingManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Continue Watching")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if continueWatchingManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            if let error = continueWatchingManager.error {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            if continueWatchingManager.items.isEmpty && !continueWatchingManager.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No items to continue watching")
                        .foregroundStyle(.secondary)
                        .font(.headline)
                    
                    Text("Start watching something to see it here")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(continueWatchingManager.items) { item in
                            ContinueWatchingCard(item: item)
                                .contextMenu {
                                    Button {
                                        Task {
                                            await continueWatchingManager.markAsPlayed(item)
                                        }
                                    } label: {
                                        Label("Mark as Played", systemImage: "checkmark.circle")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
            }
        }
        .task {
            await continueWatchingManager.loadContinueWatching()
        }
        .refreshable {
            await continueWatchingManager.loadContinueWatching()
        }
    }
}
