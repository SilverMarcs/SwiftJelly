import SwiftUI

struct PlaybackFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Unable to Play Video", systemImage: "play.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", systemImage: "arrow.clockwise", action: retry)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
