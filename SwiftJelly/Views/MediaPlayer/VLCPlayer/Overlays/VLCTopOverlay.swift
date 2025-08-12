//
//  VLCPlayerMobileOverlay.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 26/07/2025.
//


import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerTopOverlay: View {
    @Environment(\.dismiss) var dismiss
    let proxy: VLCVideoPlayer.Proxy
    
    @Binding var isAspectFillMode: Bool
    
    var body: some View {
        HStack {
            Button {
                isAspectFillMode.toggle()
                if isAspectFillMode {
                    proxy.aspectFill(1.0)
                } else {
                    proxy.aspectFill(0.0)
                }
            } label: {
                Image(systemName: isAspectFillMode ? "rectangle.arrowtriangle.2.inward" : "rectangle.arrowtriangle.2.outward")
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .padding(2)
            }
        }
        .buttonBorderShape(.circle)
        .buttonStyle(.glass)
    }
}
