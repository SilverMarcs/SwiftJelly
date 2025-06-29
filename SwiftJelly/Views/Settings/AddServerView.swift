//
//  AddServerView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared
    
    @State private var serverName = ""
    @State private var serverURL = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Server Name", text: $serverName)
                    TextField("Server URL", text: $serverURL)
                        .textContentType(.URL)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Server")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addServer()
                    }
                    .disabled(serverName.isEmpty || serverURL.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addServer() {
        guard let url = URL(string: serverURL) else {
            alertMessage = "Invalid URL"
            showingAlert = true
            return
        }
        
        let server = Server(name: serverName, url: url)
        dataManager.addServer(server)
        dismiss()
    }
}
