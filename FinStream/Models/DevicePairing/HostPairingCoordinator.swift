//
//  HostPairingCoordinator.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 26.07.26.
//

#if os(iOS)
import Foundation
import os

/// Drives the iPhone/iPad (sharer) side of nearby pairing. It keeps a listener running while the app
/// is active so a nearby Apple TV's device picker can connect (the system shows a trust prompt and
/// launches the app — there's no background advertising). When a connection arrives it offers this
/// device's servers and authorizes each Quick Connect request the TV makes.
@MainActor
@Observable
final class HostPairingCoordinator {
    enum Phase: Equatable {
        /// Listening; no active session.
        case idle
        /// A device connected and is signing in to the offered servers.
        case sharing
        /// The session finished.
        case finished
    }

    /// Status of a single server the TV chose to sign in to.
    enum ShareStatus: Equatable {
        case sharing
        case success
        case failed(String)
    }

    struct SharedServer: Identifiable {
        let requestID: String
        let server: Server
        var status: ShareStatus
        var id: String { requestID }
    }

    private(set) var phase: Phase = .idle
    private(set) var peerName: String = ""
    private(set) var sharedServers: [SharedServer] = []

    /// True while a pairing session should be presented to the user.
    var isSessionActive: Bool { phase != .idle }

    /// Servers that can be shared (authenticated only).
    var shareableServers: [Server] {
        dataManager.servers.filter { $0.isAuthenticated }
    }

    private let listener = PairingListener()
    private let dataManager = DataManager.shared

    private var connection: PairingConnection?
    /// Maps request id → the offered server, so we can authorize with the right session.
    private var requestServers: [String: Server] = [:]

    init() {
        listener.onConnection = { [weak self] connection in
            self?.accept(connection)
        }
    }

    // MARK: - Lifecycle

    /// Begins listening for a nearby Apple TV. Safe to call repeatedly.
    func startListening() {
        pairingLog.notice("Host startListening (shareable servers: \(self.shareableServers.count))")
        listener.start()
    }

    func stopListening() {
        listener.stop()
    }

    /// Ends the current session (e.g. the user tapped Done or dismissed the sheet).
    func endSession() {
        connection?.send(.done)
        let connection = self.connection
        Task {
            // Let the final message flush before tearing down.
            try? await Task.sleep(nanoseconds: 300_000_000)
            connection?.cancel()
        }
        self.connection = nil
        requestServers = [:]
        sharedServers = []
        peerName = ""
        phase = .idle
    }

    // MARK: - Networking

    private func accept(_ connection: PairingConnection) {
        // Only one session at a time.
        guard self.connection == nil else {
            connection.cancel()
            return
        }
        self.connection = connection
        peerName = connection.remoteName ?? "Apple TV"
        sharedServers = []
        requestServers = [:]

        connection.onReady = { [weak self] in
            self?.sendServerList()
        }
        connection.onMessage = { [weak self] message in
            self?.handle(message)
        }
        connection.onClosed = { [weak self] in
            self?.handleClosed()
        }
        connection.start()
    }

    private func sendServerList() {
        var offers: [PairingMessage.ServerOffer] = []
        requestServers = [:]
        for server in shareableServers {
            let requestID = UUID().uuidString
            requestServers[requestID] = server
            offers.append(.init(requestID: requestID, name: server.name, url: server.url))
        }
        connection?.send(.serverList(offers))
        phase = .sharing
    }

    private func handle(_ message: PairingMessage) {
        switch message {
        case .quickConnectCode(let requestID, let code):
            authorize(requestID: requestID, code: code)
        case .pairResult(let requestID, let success, let message):
            updateStatus(requestID: requestID, status: success ? .success : .failed(message ?? "Pairing failed."))
        case .done:
            phase = .finished
        case .serverList:
            break // receiver-directed message, ignored on the sharer
        }
    }

    private func authorize(requestID: String, code: String) {
        guard let server = requestServers[requestID] else { return }
        // Show this server as in-progress as soon as the TV starts signing in to it.
        if !sharedServers.contains(where: { $0.requestID == requestID }) {
            sharedServers.append(SharedServer(requestID: requestID, server: server, status: .sharing))
        }
        Task {
            do {
                let accepted = try await JFAPI.authorizeQuickConnect(code: code, server: server)
                if !accepted {
                    updateStatus(requestID: requestID, status: .failed("The server rejected the request."))
                }
                // On success we leave the status as `.sharing` until the TV confirms it received its
                // token via `.pairResult`.
            } catch {
                updateStatus(requestID: requestID, status: .failed(error.localizedDescription))
            }
        }
    }

    private func updateStatus(requestID: String, status: ShareStatus) {
        guard let index = sharedServers.firstIndex(where: { $0.requestID == requestID }) else { return }
        sharedServers[index].status = status
    }

    private func handleClosed() {
        connection = nil
        requestServers = [:]
        // If the session ended before finishing, drop back to idle so the sheet dismisses.
        if phase != .finished {
            sharedServers = []
            peerName = ""
            phase = .idle
        }
    }
}
#endif
