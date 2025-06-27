import Foundation
import JellyfinAPI
import Combine
import Get

@MainActor
class HomeViewModel: ObservableObject {
    @Published var resumeItems: [BaseItemDto] = []
    @Published var isLoading = false
    @Published var error: String?

    private let dataManager: DataManager = .shared

    func loadResumeItems() async {
        guard let currentUser = dataManager.currentUser,
              let server = dataManager.servers.first(where: { $0.id == currentUser.serverID }),
              let client = dataManager.jellyfinClient(for: currentUser, server: server) else {
            error = "No user, server, or client found"
            return
        }

        isLoading = true
        error = nil

        do {
            var parameters = Paths.GetResumeItemsParameters()
            parameters.userID = currentUser.id
            parameters.enableUserData = true
            parameters.fields = .MinimumFields
            parameters.includeItemTypes = [.movie, .episode]
            parameters.limit = 20

            let request = Paths.getResumeItems(parameters: parameters)
            let response = try await client.send(request)
            resumeItems = response.value.items ?? []
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
