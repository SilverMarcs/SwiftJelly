import SwiftUI
import SwiftMediaViewer
import JellyfinAPI
#if os(tvOS)
import TVUIKit

struct TVDetailView<Content: View, ItemDetailContent: View>: UIViewControllerRepresentable {
    let item: BaseItemDto
    let action: () async -> Void
    let content: Content
    let itemDetailContent: ItemDetailContent

    init(
        item: BaseItemDto,
        action: @escaping () async -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder itemDetailContent: () -> ItemDetailContent
    ) {
        self.item = item
        self.action = action
        self.content = content()
        self.itemDetailContent = itemDetailContent()
    }

    func makeUIViewController(context: Context) -> TVDetailViewController<Content, ItemDetailContent> {
        TVDetailViewController(
            item: item,
            action: action,
            content: content,
            itemDetailContent: itemDetailContent
        )
    }

    func updateUIViewController(_ uiViewController: TVDetailViewController<Content, ItemDetailContent>, context: Context) {
        uiViewController.update(item: item, content: content, itemDetailContent: itemDetailContent)
    }
}

class TVDetailViewController<Content: View, ItemDetailContent: View>: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private var item: BaseItemDto
    private var action: () async -> Void
    private var content: Content
    private var itemDetailContent: ItemDetailContent

    private lazy var collectionView: UICollectionView = {
        let layout = TVCollectionViewFullScreenLayout()
        layout.interitemSpacing = 0
        layout.maskAmount = 0.4
        layout.parallaxFactor = 0.2
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(TVDetailCell.self, forCellWithReuseIdentifier: TVDetailCell.reuseID)
        cv.contentInsetAdjustmentBehavior = .never
        cv.isScrollEnabled = false 
        return cv
    }()

    init(
        item: BaseItemDto,
        action: @escaping () async -> Void,
        content: Content,
        itemDetailContent: ItemDetailContent
    ) {
        self.item = item
        self.action = action
        self.content = content
        self.itemDetailContent = itemDetailContent
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func update(item: BaseItemDto, content: Content, itemDetailContent: ItemDetailContent) {
        self.item = item
        self.content = content
        self.itemDetailContent = itemDetailContent
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TVDetailCell.reuseID, for: indexPath) as? TVDetailCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(
            item: item,
            content: content,
            itemDetailContent: itemDetailContent,
            parentVC: self
        )
        return cell
    }
}

class TVDetailCell: TVCollectionViewFullScreenCell {
    static let reuseID = "TVDetailCell"
    private var backgroundHostingController: UIViewController?
    private var contentHostingController: UIViewController?

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundHostingController?.view.removeFromSuperview()
        backgroundHostingController = nil
        contentHostingController?.view.removeFromSuperview()
        contentHostingController = nil
    }

    func configure<Content: View, ItemDetailContent: View>(
        item: BaseItemDto,
        content: Content,
        itemDetailContent: ItemDetailContent,
        parentVC: UIViewController
    ) {
        // Background
        let backgroundView = CachedAsyncImage(
            url: ImageURLProvider.imageURL(for: item, type: .backdrop) ?? ImageURLProvider.imageURL(for: item, type: .primary),
            targetSize: 2880
        )
        .aspectRatio(contentMode: .fill)
        .ignoresSafeArea()
        
        let bgHC = UIHostingController(rootView: backgroundView)
        bgHC.view.backgroundColor = .clear
        bgHC.view.translatesAutoresizingMaskIntoConstraints = false
        
        parentVC.addChild(bgHC)
        maskedBackgroundView.addSubview(bgHC.view)
        NSLayoutConstraint.activate([
            bgHC.view.topAnchor.constraint(equalTo: maskedBackgroundView.topAnchor),
            bgHC.view.leadingAnchor.constraint(equalTo: maskedBackgroundView.leadingAnchor),
            bgHC.view.trailingAnchor.constraint(equalTo: maskedBackgroundView.trailingAnchor),
            bgHC.view.bottomAnchor.constraint(equalTo: maskedBackgroundView.bottomAnchor)
        ])
        bgHC.didMove(toParent: parentVC)
        backgroundHostingController = bgHC

        // Content
        let contentViewRoot = ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 5) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 12) {
                        if let url = ImageURLProvider.imageURL(for: item, type: .logo) {
                            CachedAsyncImage(url: url, targetSize: 450, opaque: false)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 600, maxHeight: 300)
                        } else {
                            Text(item.name ?? "")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        
                        itemDetailContent
                            .padding(.top, 10)
                    }
                    .padding(.bottom, 20)
                    
                    if let overview = item.overview {
                        Text(overview)
                            .font(.callout)
                            .opacity(0.7)
                            .lineLimit(4)
                    }
                    
                    AttributesView(item: item)
                }
                .padding(50)
                .frame(minHeight: UIScreen.main.bounds.height)
                
                content
                    .padding(.horizontal, 50)
                    .padding(.bottom, 50)
            }
        }
        .scrollClipDisabled()

        let contentHC = UIHostingController(rootView: contentViewRoot)
        contentHC.view.backgroundColor = .clear
        contentHC.view.translatesAutoresizingMaskIntoConstraints = false
        
        parentVC.addChild(contentHC)
        self.contentView.addSubview(contentHC.view)
        NSLayoutConstraint.activate([
            contentHC.view.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            contentHC.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            contentHC.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            contentHC.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        contentHC.didMove(toParent: parentVC)
        contentHostingController = contentHC
    }
}
#endif
