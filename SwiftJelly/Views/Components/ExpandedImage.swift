//
//  ExpandedImage.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 06.12.25.
//

import SwiftUI
import SwiftMediaViewer

struct ExpandedImage<Image: View>: View {
    let image: Image
    let imageHeight: CGFloat
    let reflectionHeight: CGFloat

    init(
        image: Image,
        imageHeight: CGFloat = 300,
        reflectionHeight: CGFloat = 200,
    ) {
        self.image = image
        self.imageHeight = imageHeight
        self.reflectionHeight = reflectionHeight
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                image
                    .scaledToFill()
                    .frame(width: geo.size.width, height: imageHeight, alignment: .top)
                    .clipped()

                image
                    .scaledToFill()
                    .frame(width: geo.size.width, height: imageHeight, alignment: .top)
                    .scaleEffect(x: 1, y: -1, anchor: .center)
                    .frame(
                        width: geo.size.width,
                        height: reflectionHeight,
                        alignment: .top
                    )
                    .clipped()
            }
            #if !os(tvOS)
            .backgroundExtensionEffect()
            #endif
        }
        .frame(height: imageHeight + reflectionHeight)
    }
}
