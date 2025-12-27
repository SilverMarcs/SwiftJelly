//
//  SkeletonCards.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 15/12/2025.
//

import SwiftUI

// MARK: - Portrait skeleton (for MediaShelf)
struct SkeletonMediaCard: View {
    var body: some View {
        LabelStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.background.secondary)
                .aspectRatio(250/375, contentMode: .fill)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(.background.secondary)
                .frame(height: 12)
                .shimmer()
        }
    }
}

// MARK: - Landscape skeleton (for ContinueWatchingView)  
struct SkeletonPlayableCard: View {
    var body: some View {
        LabelStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.background.secondary)
                .aspectRatio(16/9, contentMode: .fit)
                .frame(width: cardWidth)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(.background.secondary)
                .frame(width: cardWidth * 0.7, height: 14)
                .shimmer()
        }
    }
    
    private var cardWidth: CGFloat {
        #if os(tvOS)
        480
        #else
        280
        #endif
    }
}

// MARK: - Genre skeleton (for GenreCarouselView)
struct SkeletonGenreCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.background.secondary)
            .frame(width: itemWidth * 1.5, height: itemWidth * 0.5)
            .shimmer()
    }
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        225
        #else
        100
        #endif
    }
}

// MARK: - Trending hero skeleton (for TrendingInLibraryView)
struct SkeletonTrendingHero: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.background.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.background.tertiary)
                    .frame(width: 200, height: 40)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(.background.tertiary)
                    .frame(width: 120, height: 20)
            }
            .padding(24)
        }
        .aspectRatio(16/9, contentMode: .fit)
        .shimmer()
    }
}

// MARK: - Shimmer effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
