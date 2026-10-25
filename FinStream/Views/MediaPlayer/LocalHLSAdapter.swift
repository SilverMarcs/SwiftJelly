import Foundation
import Network

/// Serves playlists and corrects small WebVTT headers on loopback.
/// Video and audio continue directly from Jellyfin.
@MainActor
final class LocalHLSAdapter {
    private let subtitleTimestamp: Int64?
    private let listener: NWListener
    private let directory = "/\(UUID().uuidString)/"
    private var documents: [String: Data]
    private let subtitlePlaylists: [String: URL]
    private var subtitleSegments: [String: URL] = [:]
    private var startContinuation: CheckedContinuation<URL, Error>?
    private var timeout: Task<Void, Never>?
    private var connections: [UUID: NWConnection] = [:]

    init(manifest: String, subtitlePlaylists: [String: URL] = [:], subtitleTimestamp: Int64? = nil) throws {
        self.subtitleTimestamp = subtitleTimestamp
        documents = ["master.m3u8": Data(manifest.utf8)]
        self.subtitlePlaylists = subtitlePlaylists
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        listener = try NWListener(using: parameters)
    }

    func start() async throws -> URL {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                startContinuation = continuation
                listener.stateUpdateHandler = { [weak self] state in
                    Task { @MainActor [weak self] in self?.stateChanged(state) }
                }
                listener.newConnectionHandler = { [weak self] connection in
                    Task { @MainActor [weak self] in self?.accept(connection) }
                }
                timeout = Task { [weak self] in
                    do { try await Task.sleep(for: .seconds(5)) } catch { return }
                    self?.stop()
                }
                listener.start(queue: .main)
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.stop() }
        }
    }

    func stop() {
        timeout?.cancel()
        timeout = nil
        startContinuation?.resume(throwing: URLError(.cancelled))
        startContinuation = nil
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
