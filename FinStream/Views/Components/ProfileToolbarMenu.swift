//
//  ProfileToolbarMenu.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

#if os(iOS)
import SwiftUI
import UIKit

struct ProfileToolbarMenu: View {
    @Binding var showingSettings: Bool

    private var dataManager = DataManager.shared

    /// `UIMenu` only renders synchronously available images, so avatars are prefetched.
    @State private var avatarImages: [String: UIImage] = [:]

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
                        // UIKit renders the trailing `Text` as a subtitle only when it's a direct child of the label.
                        Label {
                            Text(server.username ?? "User")
                        } icon: {
                            let avatar = avatarImages[server.id] ?? Self.fallbackAvatar
                            Image(uiImage: server.id == dataManager.activeServerID ? Self.addingGreenBorder(to: avatar) : avatar)
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

    private func loadAvatars() async {
        for server in dataManager.servers where avatarImages[server.id] == nil {
            guard let url = ImageURLProvider.userImageURL(for: server) else { continue }
            if let image = await Self.loadCircularImage(from: url) {
                avatarImages[server.id] = image
            }
        }
    }

    private static func loadCircularImage(from url: URL) async -> UIImage? {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return nil }
        let diameter = avatarDiameter
        return renderAvatar { size in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            let scale = max(diameter / image.size.width, diameter / image.size.height)
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: (diameter - scaledSize.width) / 2, y: (diameter - scaledSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }

    private static let fallbackAvatar = renderAvatar { size in
        UIImage(systemName: "person.crop.circle.fill")?
            .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
            .draw(in: CGRect(origin: .zero, size: size))
    }

    /// `UIMenu` ignores SwiftUI overlays on icons, so the ring is drawn into the image.
    private static func addingGreenBorder(to image: UIImage) -> UIImage {
        let lineWidth: CGFloat = 2.5
        return renderAvatar { size in
            image.draw(in: CGRect(origin: .zero, size: size))
            let ring = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size).insetBy(dx: lineWidth / 2, dy: lineWidth / 2))
            ring.lineWidth = lineWidth
            UIColor.systemGreen.withAlphaComponent(0.7).setStroke()
            ring.stroke()
        }
    }

    private static func renderAvatar(_ draw: (CGSize) -> Void) -> UIImage {
        let size = CGSize(width: avatarDiameter, height: avatarDiameter)
        return UIGraphicsImageRenderer(size: size)
            .image { _ in draw(size) }
            .withRenderingMode(.alwaysOriginal)
    }
}
#endif
