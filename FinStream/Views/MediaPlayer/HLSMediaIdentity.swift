import Foundation

/// HLS characteristics are carried through to AVMediaSelectionOption. Labels
/// remain user-facing; these identifiers link selections to Jellyfin streams.
enum HLSMediaIdentity {
    static func audio(_ index: Int) -> String { "com.silvermarcs.finstream.audio.\(index)" }
    static func subtitle(_ index: Int) -> String { "com.silvermarcs.finstream.subtitle.\(index)" }
}
