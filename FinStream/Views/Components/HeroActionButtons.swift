import SwiftUI
import JellyfinAPI

/// Shared play / mark-played / favorite action row used by both the Home hero
/// carousel and the media detail views. The two contexts differ along fixed
/// axes (Liquid-Glass container, tvOS info button + focus wiring, redaction and
/// spacing), all captured here so the row is defined in a single place.
struct HeroActionButtons<Play: View>: View {
    enum Context {
        /// Home hero carousel: glass container, tvOS focus scope + default focus,
        /// tighter iOS spacing.
        case carousel
        /// Media detail view: no focus wiring, wider iOS spacing.
        case detail
    }

    let context: Context
    /// Whether to wrap the row in a `GlassEffectContainer`. Carousel always does;
    /// in detail only the episode hero does.
    let usesGlassContainer: Bool
    /// When non-nil and running on tvOS in the carousel, an info button linking to
    /// the item's detail view is inserted after the play button.
    let infoItem: BaseItemDto?
    let markPlayedItem: BaseItemDto?
    var markPlayedDisabled: Bool = false
    /// When nil, no favorite button is shown (episodes).
    let favoriteItem: BaseItemDto?
    /// When non-nil, the row is redacted with a placeholder while this item's
    /// `name` is empty (movie carousel skeleton).
    var redactWhenEmpty: BaseItemDto? = nil
    /// When provided, the hero's focus scope uses this namespace so a parent can
    /// bias default focus onto the play button.
    var externalFocusNamespace: Namespace.ID? = nil
    /// When provided, lets a parent programmatically move focus onto the play
    /// button (e.g. when the hero scrolls back into view).
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

                MarkPlayedButton(item: markPlayedItem)
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
        // The glass container merges the buttons so they sit tighter; a plain
        // row (movie/show detail) needs more breathing room.
        usesGlassContainer ? 6 : 10
        #endif
    }
}
