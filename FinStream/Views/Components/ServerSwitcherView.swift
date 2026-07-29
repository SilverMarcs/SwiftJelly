//
//  ServerSwitcherView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import SwiftUI
import SwiftMediaViewer

/// Profile switcher used to change the active profile (and thereby the
/// signed-in user). Profiles are shown as large circular avatars grouped under
/// the server they belong to. Reused as a sheet (`ServerSwitcherView`) on
/// macOS/iPadOS and as a sidebar page on tvOS.
struct ServerSwitcherList: View {
    private var dataManager = DataManager.shared

    /// Called after a profile is selected, e.g. to dismiss a presenting sheet.
    var onSelect: (() -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: sectionSpacing) {
                ForEach(dataManager.serverGroups) { group in
                    serverSection(group)
                }

                addCard(title: "Add Server", systemImage: "plus", route: .addServer)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.vertical, 24)
        }
        .navigationDestination(for: ServerSwitcherRoute.self) { route in
            switch route {
            case .addServer:
                AddServerView()
            case .addAccount(let name, let url):
                AddServerView(existingServerName: name, existingServerURL: url)
            }
        }
    }

    private func serverSection(_ group: ServerGroup) -> some View {
        VStack(spacing: 20) {
            Text(group.name)
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            CenteredFlowLayout(spacing: cardSpacing) {
                ForEach(group.profiles) { profile in
                    ProfileCard(
                        server: profile,
                        isSelected: profile.id == dataManager.activeServerID,
                        avatarSize: avatarSize,
                        cardWidth: cardWidth
                    ) {
                        dataManager.selectServer(profile)
                        onSelect?()
                    }
                }

                addCard(
                    title: "Add Account",
                    systemImage: "person.badge.plus",
                    route: .addAccount(serverName: group.name, url: group.url)
                )
            }
            .frame(maxWidth: .infinity)
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }

    private func addCard(title: LocalizedStringKey, systemImage: String, route: ServerSwitcherRoute) -> some View {
        NavigationLink(value: route) {
            LabelStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.background.secondary)
                    Image(systemName: systemImage)
                        .font(.system(size: avatarSize * 0.32, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: avatarSize, height: avatarSize)
                #if !os(macOS)
                .hoverEffect(.highlight)
                #endif

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: cardWidth)
            .contentShape(.rect)
        }
        .buttonBorderShape(.circle)
        .adaptiveButtonStyle()
    }

    private var avatarSize: CGFloat {
        #if os(tvOS)
        240
        #else
        80
        #endif
    }

    private var cardWidth: CGFloat {
        #if os(tvOS)
        320
        #else
        118
        #endif
    }

    private var cardSpacing: CGFloat {
        #if os(tvOS)
        40
        #else
        20
        #endif
    }

    private var sectionSpacing: CGFloat {
        #if os(tvOS)
        70
        #else
        32
        #endif
    }
}

/// A single profile presented as a big circular avatar with the username below.
/// The active profile is marked with a checkmark badge rather than a coloured
/// ring, which reads cleanly against the tvOS focus highlight.
private struct ProfileCard: View {
    let server: Server
    let isSelected: Bool
    let avatarSize: CGFloat
    let cardWidth: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LabelStack(spacing: 10) {
                avatar

                Text(server.username ?? server.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: cardWidth)
            .contentShape(.rect)
        }
        .buttonBorderShape(.circle)
        .adaptiveButtonStyle()
    }

    // Mirrors `PersonView`'s avatar: on tvOS the image is left unclipped so the
    // borderless button's circular border shape drives the focus highlight. A
    // clipped/self-ringed avatar (like `UserAvatarView`) fights that effect.
    private var avatar: some View {
        Group {
            if let url = ImageURLProvider.userImageURL(for: server) {
                CachedAsyncImage(url: url, targetSize: Int(avatarSize * 2)) {
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .background(.background.secondary)
        .overlay {
            // A ring stays inside the circular focus mask, unlike a corner badge.
            Circle().strokeBorder(
                isSelected ? AnyShapeStyle(.green) : AnyShapeStyle(.tertiary),
                lineWidth: isSelected ? max(4, avatarSize * 0.04) : 0.5
            )
        }
        #if !os(macOS)
        .hoverEffect(.highlight)
        #endif
        #if !os(tvOS)
        .clipShape(.circle)
        .clipped()
        #endif
    }
}

/// A wrapping flow layout that centres each row horizontally, so a small number
/// of profiles sit in the middle of the switcher rather than packed to the edge.
/// Rows wrap when they exceed the available width.
private struct CenteredFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)

        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Group subviews into rows that fit the available width.
        var rows: [[LayoutSubviews.Element]] = [[]]
        var rowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > bounds.width, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            rowWidth += size.width + spacing
        }

        // Place each row centred within the bounds.
        var y = bounds.minY
        for row in rows {
            let sizes = row.map { $0.sizeThatFits(.unspecified) }
            let rowContentWidth = sizes.reduce(0) { $0 + $1.width } + CGFloat(max(0, row.count - 1)) * spacing
            let rowHeight = sizes.map(\.height).max() ?? 0
            var x = bounds.minX + max(0, (bounds.width - rowContentWidth) / 2)

            for (index, subview) in row.enumerated() {
                subview.place(
                    at: CGPoint(x: x, y: y + (rowHeight - sizes[index].height) / 2),
                    proposal: .unspecified
                )
                x += sizes[index].width + spacing
            }
            y += rowHeight + spacing
        }
    }
}

/// Navigation values for the profile switcher: adding a whole new server, or
/// adding another account to an existing one.
enum ServerSwitcherRoute: Hashable {
    case addServer
    case addAccount(serverName: String, url: URL)
}

/// Sheet presentation of the profile switcher for macOS and iPadOS.
struct ServerSwitcherView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ServerSwitcherList(onSelect: { dismiss() })
                .navigationTitle("Switch Profile")
                .platformNavigationToolbar(titleDisplayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        #if os(tvOS)
        // The full-screen cover has no backing surface of its own, so give the
        // page an opaque frosted background instead of showing through.
        .background(.regularMaterial, ignoresSafeAreaEdges: .all)
        #endif
    }
}

#Preview {
    ServerSwitcherView()
}
