//
//  FlowLayout.swift
//  LynkChat
//
//  Created by Zabir Raihan on 01/01/2025.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var height: CGFloat = 0
        var width: CGFloat = 0
        var currentX: CGFloat = 0
        var currentRow: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > (proposal.width ?? .infinity) {
                currentX = 0
                currentRow += size.height + spacing
            }
            currentX += size.width + spacing
            width = max(width, currentX)
            height = currentRow + size.height
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += size.height + spacing
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
        }
    }
}

//centered flowlayout
//struct FlowLayout: Layout {
//    var spacing: CGFloat = 8
//    
//    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
//        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
//        var height: CGFloat = 0
//        var width: CGFloat = 0
//        var currentX: CGFloat = 0
//        var currentRowHeight: CGFloat = 0
//        
//        for size in sizes {
//            if currentX + size.width > (proposal.width ?? .infinity) {
//                currentX = 0
//                height += currentRowHeight + spacing
//                currentRowHeight = 0
//            }
//            currentX += size.width + spacing
//            currentRowHeight = max(currentRowHeight, size.height)
//            width = max(width, currentX)
//        }
//        height += currentRowHeight
//        
//        return CGSize(width: width, height: height)
//    }
//    
//    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
//        // Step 1: Group subviews into rows
//        var rows: [[LayoutSubviews.Element]] = [[]]
//        var currentRowWidth: CGFloat = 0
//        
//        for subview in subviews {
//            let size = subview.sizeThatFits(.unspecified)
//            
//            if currentRowWidth + size.width > bounds.width && !rows[rows.count - 1].isEmpty {
//                rows.append([])
//                currentRowWidth = 0
//            }
//            
//            rows[rows.count - 1].append(subview)
//            currentRowWidth += size.width + spacing
//        }
//        
//        // Step 2: Place each row centered
//        var currentY: CGFloat = bounds.minY
//        
//        for row in rows {
//            let rowSizes = row.map { $0.sizeThatFits(.unspecified) }
//            let totalRowWidth = rowSizes.reduce(0) { $0 + $1.width } + CGFloat(row.count - 1) * spacing
//            let rowHeight = rowSizes.map { $0.height }.max() ?? 0
//            
//            // Calculate centered starting X position
//            var currentX = bounds.minX + (bounds.width - totalRowWidth) / 2
//            
//            for (index, subview) in row.enumerated() {
//                subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
//                currentX += rowSizes[index].width + spacing
//            }
//            
//            currentY += rowHeight + spacing
//        }
//    }
//}
