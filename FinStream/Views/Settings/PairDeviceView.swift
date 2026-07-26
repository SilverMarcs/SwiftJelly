//
//  PairDeviceView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 26.07.26.
//

import SwiftUI

/// Lets a signed-in user pair a new device by authorizing the Quick Connect code that device
/// is displaying. This is the counterpart to `QuickConnectView`, which is used when *this* device
/// is the one being signed in.
struct PairDeviceView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var phase: Phase = .idle

    private enum Phase: Equatable {
        case idle
        case submitting
        case success
        case failed(String)
    }

    var body: some View {
        SettingsSplitView {
            formContent
                .navigationTitle("Quick Connect")
                .platformNavigationToolbar(titleDisplayMode: .inline)
        } infoPanel: {
            VStack(spacing: 20) {
                Image(systemName: "bolt.horizontal.circle")
                    .font(.system(size: 200))
                    .foregroundStyle(.secondary)

                Text("Pair a Device")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var formContent: some View {
        Form {
            Section {
                TextField("Quick Connect Code", text: $code)
                    .autocorrectionDisabled()
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.numberPad)
                    #endif
                    .disabled(phase == .submitting || phase == .success)
            } header: {
                Text("Enter Code")
            } footer: {
                Text("On the new device, open Quick Connect to display a code, then enter it here to sign that device in to your account.")
            }

            switch phase {
            case .success:
                Section {
                    Label("Device paired successfully.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            case .failed(let message):
                Section {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            case .idle, .submitting:
                EmptyView()
            }

            Section {
                Button(role: .confirm) {
                    authorize()
                } label: {
                    pairLabel
                        .contentShape(.rect)
                }
                .buttonSizing(.flexible)
                .buttonStyle(.plain)
                .disabled(trimmedCode.isEmpty || phase == .submitting || phase == .success)
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .contentMargins(.top, 10)
        #endif
    }

    private var pairLabel: some View {
        HStack {
            Spacer()
            if phase == .submitting {
                ProgressView()
                #if os(macOS)
                .controlSize(.small)
                #endif
            } else {
                Text("Pair Device")
                    .fontWeight(.semibold)
            }
            Spacer()
        }
    }

    private var trimmedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func authorize() {
        phase = .submitting
        Task {
            do {
                let authorized = try await JFAPI.authorizeQuickConnect(code: trimmedCode)
                phase = authorized
                    ? .success
                    : .failed("The code was not accepted. Check it and try again.")
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}

#Preview {
    PairDeviceView()
}
