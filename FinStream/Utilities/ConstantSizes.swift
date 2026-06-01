//
//  ConstantSizes.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 09.02.26.
//

import CoreFoundation


public var posterWidth: CGFloat {
    #if os(tvOS)
    260
    #else
    Device.isMacOrPad ? 165 : 110
    #endif
}

public var posterHeight: CGFloat {
    posterWidth * 1.5
}
