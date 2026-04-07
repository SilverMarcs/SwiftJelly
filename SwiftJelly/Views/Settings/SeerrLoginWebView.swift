//
//  SeerrLoginWebView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 04/04/2026.
//

import SwiftUI
import WebKit

struct SeerrLoginWebView: View {
    let serverURL: URL
    let onAuthenticated: (SeerrUser) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isCheckingAuth = false

    var body: some View {
        NavigationStack {
            SeerrWebViewRepresentable(
                url: serverURL.appending(path: "/login"),
                serverURL: serverURL,
                onCookieObtained: { cookie in
                    Task { await handleCookie(cookie) }
                }
            )
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Sign in to Seerr")
            .platformNavigationToolbar(titleDisplayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isCheckingAuth {
                    ProgressView("Authenticating...")
                        .padding()
                        .background(.regularMaterial, in: .rect(cornerRadius: 12))
                }
            }
        }
    }

    private func handleCookie(_ cookie: HTTPCookie) async {
        guard !isCheckingAuth else { return }
        isCheckingAuth = true

        SeerrAPI.session.configuration.httpCookieStorage?.setCookie(cookie)

        do {
            let user = try await SeerrAPI.validateConnection(serverURL: serverURL)
            UserDefaults.standard.set(true, forKey: "seerrAuthenticated")
            await onAuthenticated(user)
            dismiss()
        } catch {
            isCheckingAuth = false
            print("Seerr auth validation failed after cookie: \(error)")
        }
    }
}

// MARK: - Platform-specific WKWebView wrapper

#if os(macOS)
struct SeerrWebViewRepresentable: NSViewRepresentable {
    let url: URL
    let serverURL: URL
    let onCookieObtained: (HTTPCookie) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let webView = makeWebView(context: context)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> SeerrWebViewCoordinator {
        SeerrWebViewCoordinator(serverURL: serverURL, onCookieObtained: onCookieObtained)
    }

    private func makeWebView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.startObserving(cookieStore: config.websiteDataStore.httpCookieStore)
        return webView
    }
}
#else
struct SeerrWebViewRepresentable: UIViewRepresentable {
    let url: URL
    let serverURL: URL
    let onCookieObtained: (HTTPCookie) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = makeWebView(context: context)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> SeerrWebViewCoordinator {
        SeerrWebViewCoordinator(serverURL: serverURL, onCookieObtained: onCookieObtained)
    }

    private func makeWebView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.startObserving(cookieStore: config.websiteDataStore.httpCookieStore)
        return webView
    }
}
#endif

// MARK: - Coordinator that observes cookie changes

class SeerrWebViewCoordinator: NSObject, WKNavigationDelegate, WKHTTPCookieStoreObserver {
    let serverURL: URL
    let onCookieObtained: (HTTPCookie) -> Void
    private var hasFiredCallback = false
    private weak var cookieStore: WKHTTPCookieStore?

    init(serverURL: URL, onCookieObtained: @escaping (HTTPCookie) -> Void) {
        self.serverURL = serverURL
        self.onCookieObtained = onCookieObtained
    }

    func startObserving(cookieStore: WKHTTPCookieStore) {
        self.cookieStore = cookieStore
        cookieStore.add(self)
    }

    // Called by WebKit whenever any cookie changes (add/remove/modify)
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        checkForSessionCookie()
    }

    // Also check on page loads as a fallback
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        checkForSessionCookie()
    }

    private func checkForSessionCookie() {
        guard !hasFiredCallback else { return }

        cookieStore?.getAllCookies { [weak self] cookies in
            guard let self, !self.hasFiredCallback else { return }

            if let sessionCookie = cookies.first(where: { $0.name == "connect.sid" }) {
                self.hasFiredCallback = true
                self.cookieStore?.remove(self)
                self.onCookieObtained(sessionCookie)
            }
        }
    }

    deinit {
        cookieStore?.remove(self)
    }
}
