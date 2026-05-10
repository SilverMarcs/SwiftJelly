//
//  SeerrAuth.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 06/05/2026.
//

import Foundation
import Observation

@Observable
final class SeerrAuth {
    var serverURL: String = ""
    var isAuthenticated: Bool = false

    @ObservationIgnored static let shared = SeerrAuth()
    @ObservationIgnored private let kvs = NSUbiquitousKeyValueStore.default
    @ObservationIgnored private let serverURLKey = "seerrServerURL"
    @ObservationIgnored private let authenticatedKey = "seerrAuthenticated"
    @ObservationIgnored private let cookieKey = "seerrPersistedCookie"

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(externalChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs
        )
        kvs.synchronize()
        load()
        restoreCookie()
    }

    func setServerURL(_ url: String) {
        serverURL = url
        kvs.set(url, forKey: serverURLKey)
    }

    func setAuthenticated(_ flag: Bool) {
        isAuthenticated = flag
        kvs.set(flag, forKey: authenticatedKey)
    }

    func persistCookie(_ cookie: HTTPCookie) {
        var dict: [String: String] = [
            "name": cookie.name,
            "value": cookie.value,
            "domain": cookie.domain,
            "path": cookie.path
        ]
        if let expires = cookie.expiresDate {
            dict["expires"] = String(expires.timeIntervalSince1970)
        }
        if cookie.isSecure { dict["secure"] = "1" }
        kvs.set(dict, forKey: cookieKey)

        SeerrAPI.session.configuration.httpCookieStorage?.setCookie(cookie)
    }

    func clearCookie() {
        kvs.removeObject(forKey: cookieKey)
    }

    func restoreCookie() {
        guard let dict = kvs.dictionary(forKey: cookieKey) as? [String: String],
              let name = dict["name"],
              let value = dict["value"],
              let domain = dict["domain"],
              let path = dict["path"] else { return }

        var props: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path
        ]
        if let expiresString = dict["expires"], let interval = TimeInterval(expiresString) {
            props[.expires] = Date(timeIntervalSince1970: interval)
        }
        if dict["secure"] == "1" { props[.secure] = "TRUE" }

        if let cookie = HTTPCookie(properties: props) {
            SeerrAPI.session.configuration.httpCookieStorage?.setCookie(cookie)
        }
    }

    private func load() {
        serverURL = kvs.string(forKey: serverURLKey) ?? ""
        isAuthenticated = kvs.bool(forKey: authenticatedKey)
    }

    @objc private func externalChange(_ note: Notification) {
        Task { @MainActor in
            load()
            restoreCookie()
        }
    }
}
