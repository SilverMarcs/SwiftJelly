//
//  ContinueWatchingManager.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import Foundation
import Combine

@MainActor
class ContinueWatchingManager: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let dataManager: DataManager = .shared
    
    func loadContinueWatching() async {
        guard let currentUser = dataManager.currentUser,
              let server = dataManager.servers.first(where: { $0.id == currentUser.serverID }) else {
            error = "No user or server found"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let resumeItems = try await fetchResumeItems(for: currentUser, on: server)
            items = resumeItems
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fetchResumeItems(for user: User, on server: Server) async throws -> [MediaItem] {
        guard let accessToken = user.accessToken else {
            throw APIError.invalidURL
        }
        
        var components = URLComponents(url: server.url, resolvingAgainstBaseURL: false)
        components?.path = "/Users/\(user.id)/Items/Resume"
        
        let queryItems = [
            URLQueryItem(name: "EnableUserData", value: "true"),
            URLQueryItem(name: "Fields", value: "BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear,Status,EndDate"),
            URLQueryItem(name: "IncludeItemTypes", value: "Movie,Episode"),
            URLQueryItem(name: "Limit", value: "20"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "SortBy", value: "DatePlayed"),
            URLQueryItem(name: "SortOrder", value: "Descending")
        ]
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("MediaBrowser Token=\"\(accessToken)\"", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let resumeResponse = try decoder.decode(ResumeItemsResponse.self, from: data)
        return resumeResponse.items
    }
    
    func markAsPlayed(_ item: MediaItem) async {
        guard let currentUser = dataManager.currentUser,
              let server = dataManager.servers.first(where: { $0.id == currentUser.serverID }),
              let accessToken = currentUser.accessToken else {
            return
        }
        
        var components = URLComponents(url: server.url, resolvingAgainstBaseURL: false)
        components?.path = "/Users/\(currentUser.id)/PlayedItems/\(item.id)"
        
        guard let url = components?.url else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("MediaBrowser Token=\"\(accessToken)\"", forHTTPHeaderField: "Authorization")
        
        do {
            _ = try await URLSession.shared.data(for: request)
            // Refresh the continue watching list
            await loadContinueWatching()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ResumeItemsResponse: Codable {
    let items: [MediaItem]
    let totalRecordCount: Int
    let startIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
        case startIndex = "StartIndex"
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        }
    }
}
