//
//  EditServerView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 29.07.26.
//

import SwiftUI

/// Edits a server's stored data — its display name and URL — applying the change
/// to every account signed in on that server. Credentials aren't editable here;
/// add or remove accounts instead.
struct EditServerView: View {
    @Environment(\.dismiss) private var dismiss

    private var dataManager = DataManager.shared

    private let profiles: [Server]

    @State private var name: String
    @State private var urlString: String
    @State private var alertMessage = ""
    @State private var showingAlert = false

    init(group: ServerGroup) {
        self.profiles = group.profiles
        _name = State(initialValue: group.name)
        _urlString = State(initialValue: group.url.absoluteString)
    }

    private var canSave: Bool {
        !name.isEmpty && !urlString.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Server Name", text: $name)
                    TextField("Server URL", text: $urlString)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Server")
            .platformNavigationToolbar(titleDisplayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func save() {
        guard let url = URL(string: urlString) else {
            alertMessage = "Invalid URL"
            showingAlert = true
            return
        }

        for profile in profiles {
            var updated = profile
            updated.name = name
            updated.url = url
            dataManager.updateServer(updated)
        }
        dismiss()
    }
}
