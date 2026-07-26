//
//  ShareServersSheet.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 26.07.26.
//

#if os(iOS)
import SwiftUI

/// Status sheet shown on iPhone/iPad while a nearby Apple TV signs itself into this device's servers.
/// The TV drives which servers to add; this sheet just reports progress. Presented automatically when
/// a connection arrives (after the system's trust prompt), so it never appears unprompted.
struct ShareServersSheet: View {
    @Bindable var coordinator: HostPairingCoordinator

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Signing In Your Apple TV")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        }
        .presentationDetents([.medium])
        #if !os(macOS)
        .presentationBackground(Color(.systemBackground))
        #endif
        .animation(.snappy, value: coordinator.phase)
        .animation(.snappy, value: coordinator.sharedServers.map(\.status))
    }

    private var content: some View {
        let finished = coordinator.phase == .finished

        return VStack(spacing: 24) {
            Spacer()

            Group {
                if finished {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: coordinator.phase)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "appletv")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                        .symbolEffect(.pulse)
                }
            }

            VStack(spacing: 8) {
                Text(finished ? "All Set" : "Signing In…")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                Text(finished
                     ? "“\(coordinator.peerName)” is signed in and ready to go."
                     : "“\(coordinator.peerName)” is signing in to your servers securely via Quick Connect.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if coordinator.sharedServers.isEmpty && !finished {
                ProgressView()
                    #if os(macOS)
                    .controlSize(.small)
                    #endif
            } else {
                GlassEffectContainer(spacing: 12) {
                    VStack(spacing: 12) {
                        ForEach(coordinator.sharedServers) { shared in
                            HStack(spacing: 12) {
                                Image(systemName: "server.rack")
                                    .font(.title3)
                                    .foregroundStyle(.tint)
                                    .frame(width: 28)

                                Text(shared.server.name)
                                    .fontWeight(.medium)

                                Spacer()

                                statusView(for: shared.status)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                        }
                    }
                }
            }

            Spacer()

            if finished {
                Button {
                    coordinator.endSession()
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private func statusView(for status: HostPairingCoordinator.ShareStatus) -> some View {
        switch status {
        case .sharing:
            ProgressView()
                #if os(macOS)
                .controlSize(.small)
                #endif
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: status)
        case .failed(let message):
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
                .help(message)
        }
    }
}
#endif
