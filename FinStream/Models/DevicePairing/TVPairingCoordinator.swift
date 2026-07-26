//
//  TVPairingCoordinator.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 26.07.26.
//

#if os(tvOS)
import Foundation
import Network
import os

/// Drives the tvOS (receiver) side of nearby pairing. The Apple TV uses a DeviceDiscoveryUI device
/// picker to connect to a nearby signed-in iPhone/iPad, receives the list of servers that device can
/// share, lets the user pick which to add, and runs a Quick Connect flow for each so the TV signs in
/// with its own server-minted token.
@MainActor
@Observable
final class TVPairingCoordinator {
    enum Phase: Equatable {
        /// Waiting for the user to pick a device in the system picker.
        case idle
        /// A device was selected; establishing the connection.
        case connecting
        /// Connected; waiting for the other device's list of shareable servers.
        case waitingForServers
        /// Choosing which of the offered servers to sign in to.
        case selecting
        /// Signing in to the chosen servers.
        case pairing
        /// All chosen servers have been processed. `pairedServerNames` lists what was added.
        case finished(pairedServerNames: [String])
        /// Something went wrong.
        case failed(String)
    }

    private(set) var phase: Phase = .idle

    /// The servers the connected device offered, once received.
    private(set) var availableServers: [PairingMessage.ServerOffer] = []

    private(set) var pairedServerNames: [String] = []
    private(set) var failedServerNames: [String] = []

    private let dataManager = DataManager.shared

    private var connection: PairingConnection?
    /// Quick Connect flows kept alive for the duration of pairing, keyed by request id.
    private var activeViewModels: [String: QuickConnectViewModel] = [:]
    private var selectedCount = 0
    private var resolvedCount = 0

    // MARK: - Lifecycle

    /// Opens a connection to the device the user selected in the picker.
    func connect(to endpoint: NWEndpoint) {
        pairingLog.info("TV connecting to selected endpoint")
        reset()
        phase = .connecting

        let connection = PairingConnection(connection: NWConnection(to: endpoint, using: .applicationService))
        self.connection = connection
        connection.onReady = { [weak self] in
            guard let self else { return }
            if case .connecting = self.phase {
                self.phase = .waitingForServers
            }
        }
        connection.onMessage = { [weak self] message in
            self?.handle(message)
        }
        connection.onClosed = { [weak self] in
            self?.handleClosed()
        }
        connection.start()
    }

    func stop() {
        for viewModel in activeViewModels.values {
            viewModel.cancel()
        }
        activeViewModels.removeAll()
        connection?.cancel()
        connection = nil
    }

    /// Restarts the whole flow after a failure or completion.
    func restart() {
        stop()
        phase = .idle
    }

    private func reset() {
        for viewModel in activeViewModels.values {
            viewModel.cancel()
        }
        activeViewModels.removeAll()
        connection?.cancel()
        connection = nil
        availableServers = []
        pairedServerNames = []
        failedServerNames = []
        selectedCount = 0
        resolvedCount = 0
    }

    // MARK: - User actions

    /// Signs in to the offers the user selected on the TV.
    func addSelected(_ requestIDs: Set<String>) {
        let offers = availableServers.filter { requestIDs.contains($0.requestID) }
        guard !offers.isEmpty else { return }

        selectedCount = offers.count
        resolvedCount = 0
        pairedServerNames = []
        failedServerNames = []
        phase = .pairing

        for offer in offers {
            pairServer(offer)
        }
    }

    // MARK: - Networking

    private func handle(_ message: PairingMessage) {
        switch message {
        case .serverList(let offers):
            availableServers = offers
            if offers.isEmpty {
                phase = .finished(pairedServerNames: [])
            } else {
                phase = .selecting
            }
        case .done:
            switch phase {
            case .finished, .failed:
                break
            default:
                phase = .finished(pairedServerNames: pairedServerNames)
            }
        case .quickConnectCode, .pairResult:
            break // sharer-directed messages, ignored on the receiver
        }
    }

    private func pairServer(_ offer: PairingMessage.ServerOffer) {
        let server = Server(name: offer.name, url: offer.url)
        let viewModel = QuickConnectViewModel(server: server)
        activeViewModels[offer.requestID] = viewModel

        viewModel.start(
            onCode: { [weak self] code in
                self?.connection?.send(.quickConnectCode(requestID: offer.requestID, code: code))
            },
            onFailure: { [weak self] message in
                guard let self else { return }
                self.activeViewModels[offer.requestID] = nil
                self.connection?.send(.pairResult(requestID: offer.requestID, success: false, message: message))
                self.recordResult(name: offer.name, success: false)
            },
            onSuccess: { [weak self] authenticatedServer in
                guard let self else { return }
                self.dataManager.addServer(authenticatedServer)
                self.dataManager.selectServer(authenticatedServer)
                self.activeViewModels[offer.requestID] = nil
                self.connection?.send(.pairResult(requestID: offer.requestID, success: true, message: nil))
                self.recordResult(name: authenticatedServer.name, success: true)
            }
        )
    }

    /// Records the outcome of one server and, once all chosen servers have resolved, finishes.
    private func recordResult(name: String, success: Bool) {
        resolvedCount += 1
        if success {
            pairedServerNames.append(name)
        } else {
            failedServerNames.append(name)
        }
        if resolvedCount >= selectedCount {
            connection?.send(.done)
            phase = .finished(pairedServerNames: pairedServerNames)
        }
    }

    private func handleClosed() {
        switch phase {
        case .finished, .failed, .idle:
            break // Benign: we're done or never connected.
        default:
            phase = .failed("The connection to the other device was lost.")
        }
    }
}
#endif
