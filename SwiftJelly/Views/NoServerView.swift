//
//  NoServerView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 12/12/2025.
//

import SwiftUI

struct NoServerView: View {
    @State private var showAddServerSheet = false
    
    var body: some View {
        ContentUnavailableView {
            Label("No Server Found", systemImage: "server.rack")
        } description: {
            Text("Please connect to a Jellyfin server to continue.")
        } actions: {
            Button("Add Server") {
                showAddServerSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showAddServerSheet) {
            NavigationStack {
                AddServerView()
            }
        }
    }
}
