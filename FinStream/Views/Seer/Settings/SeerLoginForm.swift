//
//  SeerLoginForm.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerLoginForm: View {
    @State private var model: SeerLoginViewModel
    let onConnected: () -> Void

    init(model: SeerLoginViewModel, onConnected: @escaping () -> Void) {
        self._model = State(initialValue: model)
        self.onConnected = onConnected
    }

    var body: some View {
        fields
            .alert("Error", isPresented: errorBinding) {
                Button("OK") { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "")
            }
    }

    #if os(tvOS)
    private var fields: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                fieldSection("Server") {
                    urlField
                }

                fieldSection("Sign In") {
                    Button {
                        model.authMethod = model.authMethod.next()
                    } label: {
                        LabeledContent("Method", value: model.authMethod.title)
                    }

                    credentialFields

                    Button {
                        connect()
                    } label: {
                        connectLabel
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canConnect)
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private func fieldSection<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
        }
    }
    #else
    private var fields: some View {
        Form {
            Section {
                urlField
            } header: {
                Text("Server")
            } footer: {
                Text("Linked to the Jellyfin profile \(model.profile.username ?? "User"). Switching profiles switches the Seer account automatically.")
            }

            Section("Sign In") {
                Picker("Method", selection: $model.authMethod) {
                    ForEach(SeerAuthMethod.allCases) { method in
                        Text(method.title).tag(method)
                    }
                }

                credentialFields
            }

            Section {
                Button(role: .confirm) {
                    connect()
                } label: {
                    connectLabel
                        .contentShape(.rect)
                }
                .buttonSizing(.flexible)
                .buttonStyle(.plain)
                .disabled(!model.canConnect)
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .contentMargins(.top, 10)
        #endif
    }
    #endif

    private var urlField: some View {
        TextField("Seer URL", text: $model.urlString)
            .textContentType(.URL)
            .autocorrectionDisabled()
            #if !os(macOS)
            .textInputAutocapitalization(.never)
            #endif
    }

    @ViewBuilder
    private var credentialFields: some View {
        TextField(model.authMethod.usernamePrompt, text: $model.username)
            .textContentType(.username)
            .autocorrectionDisabled()
            #if !os(macOS)
            .textInputAutocapitalization(.never)
            #endif

        SecureField("Password", text: $model.password)
            .textContentType(.password)
    }

    private var connectLabel: some View {
        HStack {
            Spacer()
            if model.isConnecting {
                ProgressView()
                #if os(macOS)
                .controlSize(.small)
                #endif
            } else {
                Text("Connect")
                    .fontWeight(.semibold)
            }
            Spacer()
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }

    private func connect() {
        Task {
            if await model.connect() {
                onConnected()
            }
        }
    }
}
