//
//  AppState.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 04.12.25.
//

import Foundation

@Observable
class AppState {
    var selectedTab: TabSelection = .home
    var navigationResetKey = UUID()
}
