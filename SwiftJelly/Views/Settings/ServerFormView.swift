//
//  ServerFormView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 01/07/2025.
//

import SwiftUI

struct ServerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    var serverToEdit: Server?
    var onSave: ((Server) -> Void)?
    
    @State private var serverName: String = ""
    @State private var serverURL: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Server Details") {
                TextField("Server Name", text: $serverName)
                TextField("Server URL", text: $serverURL)
                    .textContentType(.URL)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(serverToEdit == nil ? "Add Server" : "Edit Server")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(serverToEdit == nil ? "Add" : "Save") {
                    saveServer()
                }
                .disabled(serverName.isEmpty || serverURL.isEmpty)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if let server = serverToEdit {
                serverName = server.name
                serverURL = server.url.absoluteString
            }
        }
    }
    
    private func saveServer() {
        guard let url = URL(string: serverURL) else {
            alertMessage = "Invalid URL"
            showingAlert = true
            return
        }
        if var editing = serverToEdit {
            editing.name = serverName
            editing.url = url
            dataManager.updateServer(editing)
            onSave?(editing)
        } else {
            let server = Server(name: serverName, url: url)
            dataManager.addServer(server)
            onSave?(server)
        }
        dismiss()
    }
}
