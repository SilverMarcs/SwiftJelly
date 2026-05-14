//
//  SeerrLoginWebView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 04/04/2026.
//

#if !os(tvOS)
import SwiftUI
import WebKit

struct SeerrLoginWebView: View {
    let serverURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var page: WebPage
    @State private var dataStore: WKWebsiteDataStore
    @State private var observer = SeerrCookieObserver()
    @State private var isCheckingAuth = false

    init(serverURL: URL) {
        self.serverURL = serverURL
        let store = WKWebsiteDataStore.default()
        var config = WebPage.Configuration()
        config.websiteDataStore = store
        _dataStore = State(initialValue: store)
        _page = State(initialValue: WebPage(configuration: config))
    }

    var body: some View {
        WebView(page)
            .navigationTitle("Sign in to Seerr")
            .platformNavigationToolbar(titleDisplayMode: .inline)
            .overlay {
                if isCheckingAuth {
                    ProgressView("Authenticating...")
                        .padding()
                        .background(.regularMaterial, in: .rect(cornerRadius: 12))
                }
            }
            .task {
                page.load(URLRequest(url: serverURL.appending(path: "/login")))
                observer.start(cookieStore: dataStore.httpCookieStore) { cookie in
                    Task { await handleCookie(cookie) }
                }
            }
    }

    private func handleCookie(_ cookie: HTTPCookie) async {
        guard !isCheckingAuth else { return }
        isCheckingAuth = true

        SeerrAPI.session.configuration.httpCookieStorage?.setCookie(cookie)

        do {
            _ = try await SeerrAPI.validateConnection(serverURL: serverURL)
            SeerrAuth.shared.persistCookie(cookie)
            SeerrAuth.shared.setAuthenticated(true)
            dismiss()
        } catch {
            isCheckingAuth = false
        }
    }
}

// MARK: - Cookie observer

final class SeerrCookieObserver: NSObject, WKHTTPCookieStoreObserver {
    private weak var cookieStore: WKHTTPCookieStore?
    private var onCookie: ((HTTPCookie) -> Void)?
    private var lastSeenValue: String?

    func start(cookieStore: WKHTTPCookieStore, onCookie: @escaping (HTTPCookie) -> Void) {
        guard self.cookieStore == nil else { return }
        self.cookieStore = cookieStore
        self.onCookie = onCookie
        cookieStore.add(self)
        check()
    }

    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        check()
    }

    private func check() {
        cookieStore?.getAllCookies { [weak self] cookies in
            guard let self else { return }
            guard let session = cookies.first(where: { $0.name == "connect.sid" }) else { return }
            guard session.value != self.lastSeenValue else { return }
            self.lastSeenValue = session.value
            self.onCookie?(session)
        }
    }

    deinit {
        cookieStore?.remove(self)
    }
}
#endif
