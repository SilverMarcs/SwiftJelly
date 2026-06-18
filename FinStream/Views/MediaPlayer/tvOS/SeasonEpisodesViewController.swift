import UIKit
import JellyfinAPI

@MainActor
final class SeasonEpisodesViewController: UIViewController {
    private let item: BaseItemDto
    private var items: [BaseItemDto] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 40
        layout.sectionInset = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
#if os(tvOS)
        view.remembersLastFocusedIndexPath = true
#endif
        view.register(SeasonEpisodeCollectionViewCell.self, forCellWithReuseIdentifier: SeasonEpisodeCollectionViewCell.reuseIdentifier)
        return view
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No episodes available."
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.isHidden = true
        return label
    }()

    init(item: BaseItemDto) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
        title = "Episodes"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        Task { await loadItems() }
    }

    private func loadItems() async {
        loadingIndicator.startAnimating()
        defer { loadingIndicator.stopAnimating() }

        guard let seriesID = item.seriesID, let seasonID = item.seasonID else {
            items = []
            collectionView.reloadData()
            updateEmptyState()
            return
        }

        var show = BaseItemDto()
        show.id = seriesID

        do {
            let episodes = try await JFAPI.loadEpisodes(for: show, seasonID: seasonID)
            items = episodes.sorted { ($0.indexNumber ?? Int.max) < ($1.indexNumber ?? Int.max) }
            collectionView.reloadData()
            scrollToCurrentEpisode()
        } catch {
            items = []
            collectionView.reloadData()
        }
        updateEmptyState()
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !items.isEmpty
        collectionView.isHidden = items.isEmpty
    }

    private func scrollToCurrentEpisode() {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }

    private func showDetails(for item: BaseItemDto) {
        // Pause current playback when navigating to another episode.
        PlaybackManager.shared.pausePlayback()

        let destination = MediaNavigationDestinationBuilder.viewController(for: item)
        destination.modalPresentationStyle = .fullScreen
        present(destination, animated: true)
    }
}

extension SeasonEpisodesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SeasonEpisodeCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? SeasonEpisodeCollectionViewCell else {
            return UICollectionViewCell()
        }
        let episode = items[indexPath.item]
        cell.configure(with: episode, isCurrent: episode.id == item.id)
        return cell
    }
}

extension SeasonEpisodesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showDetails(for: items[indexPath.item])
    }
}

extension SeasonEpisodesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableHeight = max(0, collectionView.bounds.height - 24)
        let width = availableHeight * 16 / 9
        return CGSize(width: width, height: availableHeight)
    }
}
