//
//  String++.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 30/06/2025.
//

import Foundation

extension String {
    /// Converts a string in format "number/number" (like "16/9") to CGFloat
    func toCGFloatRatio() -> CGFloat? {
        let components = self.components(separatedBy: "/")
        guard components.count == 2,
              let numerator = Float(components[0]),
              let denominator = Float(components[1]),
              denominator != 0 else {
            return nil
        }
        return CGFloat(numerator / denominator)
    }
}
