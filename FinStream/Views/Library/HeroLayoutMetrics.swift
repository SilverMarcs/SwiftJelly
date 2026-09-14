import SwiftUI

enum HeroLayoutMetrics {
    static let reflectionHeight: CGFloat = 200

    static func height(isCompact: Bool = false) -> CGFloat {
        #if os(tvOS)
        880
        #elseif os(iOS)
        isCompact ? 672 : 525
        #elseif os(macOS)
        550
        #else
        500
        #endif
    }
}
