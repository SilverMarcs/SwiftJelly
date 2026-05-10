#if !os(tvOS)
import SwiftUI
import WebKit

struct TrailerSheetView: View {
    let trailer: Trailer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WebView(url: trailer.watchURL)
                #if os(iOS)
                .padding(.top, 1)
                #endif
                .webViewMagnificationGestures(.disabled)
                .webViewElementFullscreenBehavior(.enabled)
                .webViewBackForwardNavigationGestures(.disabled)
                .navigationTitle(trailer.name ?? "Trailer")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) { dismiss() }
                    }
                }
        }
        #if os(macOS)
        .frame(width: 1000, height: 700)
        #endif
    }
}
#endif
