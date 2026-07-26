//
//  PairingService.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 26.07.26.
//

import Foundation
import Network
import os

/// Log channel for the nearby-pairing flow. Filter Console/`log stream` on subsystem `FinStream`,
/// category `Pairing` to trace discovery, connection and message events.
let pairingLog = Logger(subsystem: "FinStream", category: "Pairing")

/// Transport layer for nearby pairing, built on the Network framework and DeviceDiscoveryUI.
///
/// - `PairingConnection` wraps a single `NWConnection` and exchanges length-framed
///   ``PairingMessage`` values. Both the Apple TV (which opens the connection from the device
///   picker) and the iPhone/iPad (which accepts it from its listener) use it once connected.
/// - `PairingListener` (iOS/iPadOS only) wraps an `NWListener` that advertises the application
///   service so the Apple TV's device picker can connect. The system launches the app and shows a
///   trust prompt, so there's no background advertising or local-network permission prompt.
enum PairingService {
    /// Application service identifier. Must match the `NSApplicationServices` entry in Info.plist on
    /// every platform.
    static let applicationServiceName = "FinStream-Pairing"
}

/// A single encrypted connection carrying ``PairingMessage`` values. Callbacks are delivered on the
/// main actor.
@MainActor
final class PairingConnection {
    private let connection: NWConnection
    /// The queue on which Network framework delivers events.
    private let queue = DispatchQueue(label: "com.finstream.pairing.connection")
    private var didClose = false

    /// Called once the connection is ready to send and receive.
    var onReady: (() -> Void)?
    /// Called for each decoded message received, in order.
    var onMessage: ((PairingMessage) -> Void)?
    /// Called once when the connection fails or is cancelled.
    var onClosed: (() -> Void)?

    init(connection: NWConnection) {
        self.connection = connection
    }

    /// A human-readable name for the remote device, if the endpoint exposes one.
    var remoteName: String? {
        if case let .service(name, _, _, _) = connection.endpoint {
            return name
        }
        return nil
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in self?.handleState(state) }
        }
        connection.start(queue: queue)
    }

    func cancel() {
        connection.cancel()
    }

    func send(_ message: PairingMessage) {
        guard let payload = try? JSONEncoder().encode(message) else { return }
        var framed = Data(count: 4)
        let length = UInt32(payload.count)
        framed[0] = UInt8((length >> 24) & 0xFF)
        framed[1] = UInt8((length >> 16) & 0xFF)
        framed[2] = UInt8((length >> 8) & 0xFF)
        framed[3] = UInt8(length & 0xFF)
        framed.append(payload)
        connection.send(content: framed, completion: .contentProcessed { _ in })
    }

    private func handleState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            pairingLog.notice("Connection ready")
            onReady?()
            receiveNextMessage()
        case .failed(let error):
            pairingLog.error("Connection failed: \(error.localizedDescription, privacy: .public)")
            notifyClosed()
        case .cancelled:
            pairingLog.info("Connection cancelled")
            notifyClosed()
        case .waiting(let error):
            pairingLog.error("Connection waiting: \(error.localizedDescription, privacy: .public)")
        default:
            break
        }
    }

    /// Reads one length-prefixed message, then schedules the next read only after delivering it, so
    /// messages are always delivered in order. Captures the connection locally (rather than touching
    /// the main-actor `self.connection` from the network queue) and copies the header into a plain
    /// byte array (a received `Data` may be a non-zero-based slice, so integer subscripting it can
    /// trap).
    private func receiveNextMessage() {
        let connection = self.connection
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] header, _, _, error in
            guard let header, header.count == 4, error == nil else {
                Task { @MainActor in self?.notifyClosed() }
                return
            }
            let bytes = [UInt8](header)
            let length = (UInt32(bytes[0]) << 24)
                | (UInt32(bytes[1]) << 16)
                | (UInt32(bytes[2]) << 8)
                | UInt32(bytes[3])
            guard length > 0 else {
                Task { @MainActor in self?.receiveNextMessage() }
                return
            }
            connection.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { [weak self] body, _, _, error in
                guard let body, body.count == Int(length), error == nil else {
                    Task { @MainActor in self?.notifyClosed() }
                    return
                }
                let message = try? JSONDecoder().decode(PairingMessage.self, from: body)
                Task { @MainActor in
                    if let message { self?.onMessage?(message) }
                    self?.receiveNextMessage()
                }
            }
        }
    }

    private func notifyClosed() {
        guard !didClose else { return }
        didClose = true
        onClosed?()
    }
}

#if os(iOS)
/// Advertises the application service (iOS/iPadOS) so a nearby Apple TV's device picker can connect.
@MainActor
final class PairingListener {
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.finstream.pairing.listener")

    /// Called on the main actor with each new incoming connection. The handler must set the
    /// connection's callbacks and then call `start()` on it.
    var onConnection: ((PairingConnection) -> Void)?

    func start() {
        guard listener == nil else { return }
        do {
            let listener = try NWListener(using: .applicationService)
            listener.service = NWListener.Service(applicationService: PairingService.applicationServiceName)
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    pairingLog.notice("Listener ready — advertising \(PairingService.applicationServiceName, privacy: .public)")
                case .failed(let error):
                    pairingLog.error("Listener failed: \(error.localizedDescription, privacy: .public)")
                case .waiting(let error):
                    pairingLog.error("Listener waiting: \(error.localizedDescription, privacy: .public)")
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                pairingLog.info("Incoming connection")
                Task { @MainActor in
                    guard let self, let onConnection = self.onConnection else {
                        connection.cancel()
                        return
                    }
                    onConnection(PairingConnection(connection: connection))
                }
            }
            listener.start(queue: queue)
            self.listener = listener
            pairingLog.notice("Listener started")
        } catch {
            pairingLog.error("Listener could not start: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }
}
#endif
