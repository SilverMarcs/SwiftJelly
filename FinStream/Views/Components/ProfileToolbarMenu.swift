//
//  ProfileToolbarMenu.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

#if os(iOS)
import SwiftUI
import UIKit

/// Toolbar profile control shown on every page in compact (iOS) layouts.
/// Tapping the avatar opens a menu to switch servers or open Settings.
struct ProfileToolbarMenu: View {
    @Binding var showingSettings: Bool

    private var dataManager = DataManager.shared

    /// Server avatars prefetched as circular images. A `Menu` is backed by
    /// UIKit's `UIMenu`, which only renders synchronously-available images, so
    /// the async `CachedAsyncImage` used elsewhere can't be shown here.
    @State private var avatarImages: [String: UIImage] = [:]

    /// Diameter, in points, the avatars are rendered at before UIKit scales
    /// them to the menu row.
    private static let avatarDiameter: CGFloat = 40

    init(showingSettings: Binding<Bool>) {
        _showingSettings = showingSettings
    }

    var body: some View {
        Menu {
            Section {
                ForEach(dataManager.servers) { server in
                    Button {
                        dataManager.selectServer(server)
                    } label: {
                        // The `Label` (title + avatar) and the server-name `Text`
                        // must be direct children of the button's label for UIKit
                        // to render the name as a menu subtitle, so keep them
                        // inline here rather than in a helper.
                        Label {
                            Text(server.username ?? "User")
                        } icon: {
                            let avatar = avatarImages[server.id] ?? Self.fallbackAvatar
                            Image(uiImage: isSelectedServer(server: server) ? Self.addingGreenBorder(to: avatar) : avatar)
                        }

                        Text(server.name)
                    }
                }
            }

            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
        } label: {
            if let server = dataManager.server {
                UserAvatarView(server: server, size: 42)
                    .padding(-14)
            } else {
                Image(systemName: "person.crop.circle")
            }
        }
        .task { await loadAvatars() }
    }

    private func isSelectedServer(server: Server) -> Bool {
        return server.id == dataManager.activeServerID
    }

    private func loadAvatars() async {
        for server in dataManager.servers where avatarImages[server.id] == nil {
            guard let url = ImageURLProvider.userImageURL(for: server) else { continue }
            if let image = await Self.loadCircularImage(from: url) {
                avatarImages[server.id] = image
            }
        }
    }

    /// Downloads an avatar and renders it into a circular image suitable for a
    /// menu icon. Returns `nil` when the user has no profile image so callers
    /// can fall back to a symbol.
    private static func loadCircularImage(from url: URL) async -> UIImage? {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let uiImage = UIImage(data: data) else { return nil }
        return circularImage(uiImage, diameter: avatarDiameter)
    }

    /// Placeholder avatar for users without a profile image, rendered at the
    /// same diameter as real photos so both look identical in size.
    private static let fallbackAvatar: UIImage = {
        let diameter = avatarDiameter
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let symbol = UIImage(systemName: "person.crop.circle.fill")?
                .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
            symbol?.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysOriginal)
    }()

    private static func circularImage(_ image: UIImage, diameter: CGFloat) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            // Aspect-fill the circle so non-square avatars aren't distorted.
            let scale = max(diameter / image.size.width, diameter / image.size.height)
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: (diameter - scaledSize.width) / 2, y: (diameter - scaledSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }.withRenderingMode(.alwaysOriginal)
    }

    /// Bakes a green selection ring into the avatar. UIKit's menu ignores
    /// SwiftUI overlay modifiers on icons, so the border must be drawn into the
    /// image itself.
    private static func addingGreenBorder(to image: UIImage, lineWidth: CGFloat = 2.5) -> UIImage {
        let diameter = avatarDiameter
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
            let inset = lineWidth / 2
            let ring = UIBezierPath(ovalIn: CGRect(x: inset, y: inset, width: diameter - lineWidth, height: diameter - lineWidth))
            ring.lineWidth = lineWidth
            // Softened green so the selection ring reads as a gentle highlight
            // rather than a harsh neon outline.
            UIColor.systemGreen.withAlphaComponent(0.7).setStroke()
            ring.stroke()
        }.withRenderingMode(.alwaysOriginal)
    }
}
#endif
