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
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let serverURLKey = "seerrServerURL"
    @ObservationIgnored private let authenticatedKey = "seerrAuthenticated"
    @ObservationIgnored private let cookieKey = "seerrPersistedCookie"
    @ObservationIgnored private let migrationKey = "SeerrAuth.iCloudMigrated"

    private init() {
        migrateFromICloudIfNeeded()
        load()
        restoreCookie()
    }

    func setServerURL(_ url: String) {
        serverURL = url
        defaults.set(url, forKey: serverURLKey)
    }

    func setAuthenticated(_ flag: Bool) {
        isAuthenticated = flag
        defaults.set(flag, forKey: authenticatedKey)
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
        defaults.set(dict, forKey: cookieKey)

        SeerrAPI.session.configuration.httpCookieStorage?.setCookie(cookie)
    }

    func clearCookie() {
        defaults.removeObject(forKey: cookieKey)
    }

    func restoreCookie() {
        guard let dict = defaults.dictionary(forKey: cookieKey) as? [String: String],
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
        serverURL = defaults.string(forKey: serverURLKey) ?? ""
        isAuthenticated = defaults.bool(forKey: authenticatedKey)
    }

    private func migrateFromICloudIfNeeded() {
        guard !defaults.bool(forKey: migrationKey) else { return }
        let kvs = NSUbiquitousKeyValueStore.default
        kvs.synchronize()
        if defaults.string(forKey: serverURLKey) == nil, let url = kvs.string(forKey: serverURLKey) {
            defaults.set(url, forKey: serverURLKey)
        }
        if defaults.object(forKey: authenticatedKey) == nil {
            defaults.set(kvs.bool(forKey: authenticatedKey), forKey: authenticatedKey)
        }
        if defaults.dictionary(forKey: cookieKey) == nil,
           let dict = kvs.dictionary(forKey: cookieKey) {
            defaults.set(dict, forKey: cookieKey)
        }
        defaults.set(true, forKey: migrationKey)
    }
}
