//
//  LoggedInView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct LoggedInView: View {
    let user: User
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
            VStack(spacing: 20) {
                Text("Welcome!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("User: \(user.username)")
                        .font(.headline)
                    
                    if let server = dataManager.getServer(for: user) {
                        Text("Server: \(server.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("URL: \(server.url.absoluteString)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.secondary.opacity(0.1))
                .cornerRadius(8)
                
                Button("Sign Out") {
                    dataManager.signOut()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Dashboard")
    }
}
