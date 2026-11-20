//
//  QuickConnectView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import SwiftUI

struct QuickConnectView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: QuickConnectViewModel

    private let onAuthenticated: (Server) -> Void

    init(server: Server, onAuthenticated: @escaping (Server) -> Void) {
        _viewModel = State(initialValue: QuickConnectViewModel(server: server))
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)

                Text("Quick Connect")
                    .font(.largeTitle)
                    .bold()
            }

            content
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.start(onSuccess: onAuthenticated)
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .connecting:
            VStack(spacing: 20) {
                ProgressView()
                Text("Requesting a code…")
                    .foregroundStyle(.secondary)
            }

        case .awaitingApproval(let code):
            VStack(spacing: 24) {
                Text("Enter this code in the Quick Connect section of Jellyfin on another device that is already signed in.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 700)

                Text(code)
                    .font(.system(size: 90, weight: .bold, design: .rounded))
                    .monospacedDigit()

                HStack(spacing: 12) {
                    ProgressView()
                    Text("Waiting for approval…")
                        .foregroundStyle(.secondary)
                }
            }

        case .authenticating:
            VStack(spacing: 20) {
                ProgressView()
                Text("Signing in…")
                    .foregroundStyle(.secondary)
            }

        case .failed(let message):
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)

                Text(message)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 700)

                Button("Try Again") {
                    viewModel.start(onSuccess: onAuthenticated)
                }
            }
        }

        Button("Cancel", role: .cancel) {
            dismiss()
        }
        .padding(.top, 20)
    }
}
