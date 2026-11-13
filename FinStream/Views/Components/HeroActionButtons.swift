import SwiftUI
import JellyfinAPI

/// Play, mark-played and favorite row shared by the Home hero carousel and the detail heroes.
struct HeroActionButtons<Play: View>: View {
    enum Context {
        case carousel
        case detail
    }

    let context: Context
    let usesGlassContainer: Bool
    /// Shown as an info button after Play in the tvOS carousel.
    let infoItem: BaseItemDto?
    let markPlayedItem: BaseItemDto?
    var markPlayedDisabled = false
    var markAllEpisodesWatched: (() async -> Void)? = nil
    var canMarkAllEpisodesWatched = true
    let favoriteItem: BaseItemDto?
    /// Redacts the row while this item has no name yet.
    var redactWhenEmpty: BaseItemDto? = nil
    var externalFocusNamespace: Namespace.ID? = nil
    var playFocus: FocusState<Bool>.Binding? = nil
    @ViewBuilder let play: Play

    @Namespace private var actionButtonsNamespace

    #if os(tvOS)
    private var focusNamespace: Namespace.ID { externalFocusNamespace ?? actionButtonsNamespace }
    #endif

    var body: some View {
        #if os(tvOS)
        if context == .carousel {
            row.focusScope(focusNamespace)
        } else {
            row
        }
        #else
        row
        #endif
    }

    private var row: some View {
        container {
            HStack(spacing: spacing) {
                playButton

                #if os(tvOS)
                if context == .carousel, let infoItem {
                    HeroInfoButton(item: infoItem)
                }
                #endif

                MarkPlayedButton(
                    item: markPlayedItem,
                    markAllEpisodesWatched: markAllEpisodesWatched,
                    canMarkAllEpisodesWatched: canMarkAllEpisodesWatched
                )
                .adaptiveDisabled(markPlayedDisabled)

                if let favoriteItem {
                    FavoriteButton(item: favoriteItem)
                }
            }
        }
        .redacted(reason: redactionReason)
    }

    @ViewBuilder
    private var playButton: some View {
        #if os(tvOS)
        if context == .carousel {
            play
                .prefersDefaultFocus(in: focusNamespace)
                .focused(optional: playFocus)
        } else {
            play
        }
        #else
        play
        #endif
    }

    @ViewBuilder
    private func container<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if usesGlassContainer {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }

    private var redactionReason: RedactionReasons {
        guard let redactWhenEmpty else { return [] }
        return redactWhenEmpty.name?.isEmpty == false ? [] : .placeholder
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        15
        #elseif os(macOS)
        8
        #else
        usesGlassContainer ? 6 : 10
        #endif
    }
}
