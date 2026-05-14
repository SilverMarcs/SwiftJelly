import Foundation
import JellyfinAPI
import SwiftUI

@Observable
class MovieDetailViewModel {
    private(set) var movie: BaseItemDto

    var isLoading: Bool = false

    init(item: BaseItemDto) {
        self.movie = item
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let id = movie.id ?? ""
            guard !id.isEmpty else { return }
            movie = try await JFAPI.loadItem(by: id)
        } catch {
            print("Reload movie failed: \(error)")
        }
    }
}
