//
//  RefreshHandlerContainer.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 25/08/2025.
//

import Foundation

final class RefreshHandlerContainer {
    static let shared = RefreshHandlerContainer()
    private init() {}
    
    var refresh: (() async -> Void)?
}
