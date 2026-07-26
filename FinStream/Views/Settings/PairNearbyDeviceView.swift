//
//  PairNearbyDeviceView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 26.07.26.
//

#if os(tvOS)
import SwiftUI
import Network
import DeviceDiscoveryUI

/// tvOS screen that connects to a nearby iPhone or iPad running FinStream — using the system device
/// picker — and lets it sign this Apple TV into its Jellyfin servers. Signing in happens securely via
/// Quick Connect; no tokens are shared, and only devices on the same iCloud account appear.
struct PairNearbyDeviceView: View {
    @State private var coordinator = TVPairingCoordinator()
    @State private var selectedIDs: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                header
                content
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
        }
        .onDisappear { coordinator.stop() }
        .onChange(of: coordinator.availableServers) { _, _ in selectedIDs = [] }
        .animation(.snappy, value: coordinator.phase)
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 70))
                .foregroundStyle(.tint)

            Text("Pair a Nearby Device")
                .font(.largeTitle)
                .bold()

            Text("Sign in instantly using FinStream on your iPhone or iPad — signed in to the same iCloud account and on the same Wi-Fi network.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 700)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.phase {
        case .idle:
            // `DevicePicker` renders as the button that opens the system discovery sheet — one tap.
            DevicePicker(.applicationService(name: PairingService.applicationServiceName)) { endpoint in
                coordinator.connect(to: endpoint)
            } label: {
                Label("Find My iPhone or iPad", systemImage: "magnifyingglass")
                    .frame(maxWidth: 500)
            } fallback: {
                ContentUnavailableView(
                    "Not Supported",
                    systemImage: "iphone.slash",
                    description: Text("This Apple TV can't discover nearby devices.")
                )
            } parameters: {
                .applicationService
            }

        case .connecting:
            progress("Connecting…")

        case .waitingForServers:
            progress("Getting your servers…")

        case .selecting:
            selecting

        case .pairing:
            progress("Signing in…")

        case .finished(let names):
            finished(names)

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

                Button("Try Again") { coordinator.restart() }
            }
        }
    }

    private func progress(_ title: LocalizedStringKey) -> some View {
        VStack(spacing: 20) {
            ProgressView()
            Text(title)
                .foregroundStyle(.secondary)
        }
    }

    private var selecting: some View {
        VStack(spacing: 24) {
            Text("Choose Servers to Add")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                ForEach(coordinator.availableServers) { offer in
                    Button {
                        toggle(offer.requestID)
                    } label: {
                        HStack {
                            Label(offer.name, systemImage: "server.rack")
                            Spacer()
                            if selectedIDs.contains(offer.requestID) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .frame(maxWidth: 700)
                    }
                }
            }

            Button {
                coordinator.addSelected(selectedIDs)
            } label: {
                Text("Add \(selectedIDs.count) Server\(selectedIDs.count == 1 ? "" : "s")")
                    .frame(maxWidth: 500)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedIDs.isEmpty)
        }
    }

    private func finished(_ names: [String]) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: names)
                .transition(.scale.combined(with: .opacity))

            if names.isEmpty {
                Text("No servers were added.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Text(names.count == 1 ? "Signed in successfully." : "Signed in to \(names.count) servers.")
                    .font(.headline)

                ForEach(names, id: \.self) { name in
                    Label(name, systemImage: "server.rack")
                        .foregroundStyle(.secondary)
                }
            }

            Button("Pair Another Device") {
                selectedIDs = []
                coordinator.restart()
            }
            .padding(.top, 8)
        }
    }

    private func toggle(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}
#endif
