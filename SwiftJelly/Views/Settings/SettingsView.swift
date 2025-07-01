//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        NavigationStack {
            ServerListView()
            
//            if let currentUser = dataManager.currentUser {
//                LoggedInView(user: currentUser)
//            }
        }
    }
}
