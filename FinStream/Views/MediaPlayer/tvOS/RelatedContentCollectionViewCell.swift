import SwiftUI
import UIKit
import JellyfinAPI

final class RelatedContentCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "RelatedContentCollectionViewCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
        transform = .identity
    }

    func configure(with item: BaseItemDto) {
        contentConfiguration = UIHostingConfiguration {
            RelatedContentCardView(item: item)
        }
        .margins(.all, 0)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        let focused = context.nextFocusedView === self
        coordinator.addCoordinatedAnimations { [weak self] in
            self?.transform = focused ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
        }
    }
}
