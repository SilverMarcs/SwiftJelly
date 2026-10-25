import Foundation
import Network

/// Serves playlists and corrects small WebVTT headers on loopback.
/// Video and audio continue directly from Jellyfin.
@MainActor
final class LocalHLSAdapter {
    private let subtitleTimestamp: Int64?
    private var listener: NWListener
    private var listeningPort: NWEndpoint.Port?
    private let directory = "/\(UUID().uuidString)/"
    private var documents: [String: Data]
    private let subtitlePlaylists: [String: URL]
    private var subtitleSegments: [String: URL] = [:]
    private var startContinuation: CheckedContinuation<URL, Error>?
    private var cancellationContinuation: CheckedContinuation<Void, Never>?
    private var timeout: Task<Void, Never>?
    private var connections: [UUID: NWConnection] = [:]

    init(manifest: String, subtitlePlaylists: [String: URL] = [:], subtitleTimestamp: Int64? = nil) throws {
        self.subtitleTimestamp = subtitleTimestamp
        documents = ["master.m3u8": Data(manifest.utf8)]
        self.subtitlePlaylists = subtitlePlaylists
        listener = try Self.makeListener(port: .any)
    }

    private static func makeListener(port: NWEndpoint.Port) throws -> NWListener {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: port)
        return try NWListener(using: parameters)
    }

    func start() async throws -> URL {
        let activeListener = listener
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                startContinuation = continuation
                activeListener.stateUpdateHandler = { [weak self, weak activeListener] state in
                    Task { @MainActor [weak self] in
                        guard let self, let activeListener, self.listener === activeListener else { return }
                        self.stateChanged(state)
                    }
                }
                activeListener.newConnectionHandler = { [weak self, weak activeListener] connection in
                    Task { @MainActor [weak self] in
                        guard let self, let activeListener, self.listener === activeListener else { connection.cancel(); return }
                        self.accept(connection)
                    }
                }
                timeout = Task { [weak self, weak activeListener] in
                    do { try await Task.sleep(for: .seconds(5)) } catch { return }
                    guard let self, let activeListener, self.listener === activeListener else { return }
                    self.stop()
                }
                activeListener.start(queue: .main)
            }
        } onCancel: {
            Task { @MainActor [weak self, weak activeListener] in
                guard let self, let activeListener, self.listener === activeListener else { return }
                self.stop()
            }
        }
    }

    /// Keep the URL already loaded by AVPlayer valid after suspension. Only the
    /// listener and its connections are replaced; playlists and selections stay.
    func restart() async throws {
        try Task.checkCancellation()
        guard let listeningPort else { throw URLError(.cannotConnectToHost) }
        stop()
        let previousListener = listener
        await withCheckedContinuation { continuation in
            cancellationContinuation = continuation
            previousListener.stateUpdateHandler = { [weak self, weak previousListener] state in
                guard case .cancelled = state else { return }
                Task { @MainActor [weak self] in
                    guard let previousListener else { return }
                    self?.listenerDidCancel(previousListener)
                }
            }
            // Cancellation may have completed before the handler was installed.
            if case .cancelled = previousListener.state { listenerDidCancel(previousListener) }
        }
        previousListener.stateUpdateHandler = nil
        try Task.checkCancellation()
        listener = try Self.makeListener(port: listeningPort)
        _ = try await start()
    }

    private func listenerDidCancel(_ cancelledListener: NWListener) {
        guard listener === cancelledListener else { return }
        cancellationContinuation?.resume()
        cancellationContinuation = nil
    }

    func stop() {
        timeout?.cancel()
        timeout = nil
        startContinuation?.resume(throwing: URLError(.cancelled))
        startContinuation = nil
        listener.newConnectionHandler = nil
        listener.cancel()
        for connection in connections.values { connection.cancel() }
        connections.removeAll()
    }

    private func stateChanged(_ state: NWListener.State) {
        switch state {
        case .ready:
            guard let port = listener.port,
                  let url = URL(string: "http://127.0.0.1:\(port.rawValue)\(directory)master.m3u8") else {
                stop()
                return
            }
            timeout?.cancel()
            timeout = nil
            listeningPort = port
            startContinuation?.resume(returning: url)
            startContinuation = nil
        case .failed(let error):
            startContinuation?.resume(throwing: error)
            startContinuation = nil
            stop()
        default:
            break
        }
    }

    private func accept(_ connection: NWConnection) {
        guard connections.count < 8 else { connection.cancel(); return }
        let id = UUID()
        connections[id] = connection
        connection.start(queue: .main)
        receive(connection, id: id, request: Data())
        Task { [weak self, weak connection] in
            try? await Task.sleep(for: .seconds(20))
            connection?.cancel()
            self?.connections[id] = nil
        }
    }

    private func receive(_ connection: NWConnection, id: UUID, request: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, complete, error in
            Task { @MainActor [weak self] in
                guard let self else { connection.cancel(); return }
                var received = request
                received.append(data ?? Data())
                guard received.count <= 8192, error == nil else {
                    connection.cancel()
                    self.connections[id] = nil
                    return
                }
                guard let header = String(data: received, encoding: .utf8), header.contains("\r\n\r\n") else {
                    if complete { connection.cancel(); self.connections[id] = nil }
                    else { self.receive(connection, id: id, request: received) }
                    return
                }
                let words = (header.components(separatedBy: "\r\n").first ?? "").split(separator: " ")
                let valid = words.count == 3 && (words[0] == "GET" || words[0] == "HEAD") && words[1].hasPrefix(self.directory)
                let name = valid ? String(words[1].dropFirst(self.directory.count)) : ""
                let body: Data?
                let status: String
                do {
                    body = valid ? try await self.document(named: name) : nil
                    status = body == nil ? "404 Not Found" : "200 OK"
                } catch {
                    body = nil
                    status = "502 Bad Gateway"
                }
                let contentType = name.hasSuffix(".vtt") ? "text/vtt; charset=utf-8" : "application/vnd.apple.mpegurl"
                var response = Data("HTTP/1.1 \(status)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body?.count ?? 0)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n".utf8)
                if words.first != "HEAD", let body { response.append(body) }
                connection.send(content: response, completion: .contentProcessed { _ in
                    connection.cancel()
                    Task { @MainActor in self.connections[id] = nil }
                })
            }
        }
    }

    private func document(named name: String) async throws -> Data? {
        if let cached = documents[name] { return cached }
        if let sourceURL = subtitleSegments[name] {
            let (text, _) = try await Self.fetchText(from: sourceURL)
            return Data(try HLSSubtitleCompatibility.normalizeWebVTT(text, mpegTimestamp: subtitleTimestamp).utf8)
        }
        guard let sourceURL = subtitlePlaylists[name] else { return nil }
        let (playlist, resolvedURL) = try await Self.fetchText(from: sourceURL)
        let segments = try HLSSubtitleCompatibility.segments(in: playlist, sourceURL: resolvedURL)
        var paths: [URL: String] = [:]
        for (index, url) in segments.enumerated() {
            let path = "\(name)-\(index).vtt"
            subtitleSegments[path] = url
            paths[url] = path
        }
        let corrected = try HLSSubtitleCompatibility.make(playlist: playlist, sourceURL: resolvedURL, segmentPaths: paths)
        let document = Data(corrected.utf8)
        documents[name] = document
        return document
    }

    static func fetchText(from sourceURL: URL) async throws -> (String, URL) {
        var request = URLRequest(url: sourceURL)
        request.timeoutInterval = 15
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        var data = Data()
        for try await byte in bytes {
            guard data.count < 524_288 else { throw URLError(.dataLengthExceedsMaximum) }
            data.append(byte)
        }
        guard let text = String(data: data, encoding: .utf8) else { throw URLError(.cannotDecodeContentData) }
        return (text, response.url ?? sourceURL)
    }

    deinit { listener.cancel() }
}
