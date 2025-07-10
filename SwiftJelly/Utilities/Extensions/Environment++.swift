//
//  Environment++.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var refresh: (() async -> Void) = {
        print("No refresh passed")
    }
}
