//
//  NextEpisodeProposalViewController.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 12/01/2026.
//

import SwiftUI
import AVKit

final class NextEpisodeProposalViewController: AVContentProposalViewController {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 38)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 29)
        label.textColor = .lightGray
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let playButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Next Episode"
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.cornerStyle = .large
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cancelButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Cancel"
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithProposal()
    }

    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(playButton)
        view.addSubview(cancelButton)

        playButton.addTarget(self, action: #selector(playTapped), for: .primaryActionTriggered)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .primaryActionTriggered)

        NSLayoutConstraint.activate([
            // Image view - below the scaled player (player is 540px tall + 60px top offset = 600px, add 60px gap)
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 90),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 660),
            imageView.widthAnchor.constraint(equalToConstant: 320),
            imageView.heightAnchor.constraint(equalToConstant: 180),

            // Title - to the right of image
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 40),
            titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -90),

            // Description - below title
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Play button - below description
            playButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            playButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            playButton.widthAnchor.constraint(equalToConstant: 300),

            // Cancel button - to the right of play button
            cancelButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 30),
            cancelButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor)
        ])
    }

    private func configureWithProposal() {
        guard let proposal = contentProposal else { return }

        titleLabel.text = proposal.title
        imageView.image = proposal.previewImage

        // Extract description from metadata
        let metadata = proposal.metadata
        for item in metadata where item.identifier == .commonIdentifierDescription {
            if let description = item.value as? String {
                descriptionLabel.text = description
            }
        }
        
    }

    override var preferredPlayerViewFrame: CGRect {
        guard let frame = playerViewController?.view.frame else { return .zero }
        // Present the current video in a smaller window at the top
        let width: CGFloat = 960
        let height: CGFloat = 540
        return CGRect(x: (frame.width - width) / 2, y: 60, width: width, height: height)
    }

    @objc private func playTapped() {
        dismissContentProposal(for: .accept, animated: true)
    }

    @objc private func cancelTapped() {
        dismissContentProposal(for: .reject, animated: true)
    }
}
