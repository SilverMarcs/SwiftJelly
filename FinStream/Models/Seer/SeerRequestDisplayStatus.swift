//
//  SeerRequestDisplayStatus.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

enum SeerRequestDisplayStatus: Hashable {
    case pendingApproval
    case declined
    case failed
    case processing
    case partiallyAvailable
    case available
    case deleted
    case blocklisted

    /// Mirrors the Seer website: the request status only wins while it is pending, declined or failed;
    /// otherwise the media's own status is shown.
    init(requestStatus: SeerRequestStatus, mediaStatus: SeerMediaStatus?) {
        switch (requestStatus, mediaStatus) {
        case (.pending, _): self = .pendingApproval
        case (.declined, _): self = .declined
        case (.failed, _): self = .failed
        case (_, .available): self = .available
        case (_, .partiallyAvailable): self = .partiallyAvailable
        case (_, .deleted): self = .deleted
        case (_, .blocklisted): self = .blocklisted
        case (_, .pending), (_, .processing), (_, .unknown), (_, nil): self = .processing
        }
    }

    var title: String {
        switch self {
        case .pendingApproval: "Pending Approval"
        case .declined: "Declined"
        case .failed: "Failed"
        case .processing: "Processing"
        case .partiallyAvailable: "Partially Available"
        case .available: "Available"
        case .deleted: "Deleted"
        case .blocklisted: "Blocklisted"
        }
    }

    var systemImage: String {
        switch self {
        case .pendingApproval: "clock"
        case .declined: "xmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .processing: "arrow.down.circle"
        case .partiallyAvailable: "circle.lefthalf.filled"
        case .available: "checkmark.circle.fill"
        case .deleted: "trash.fill"
        case .blocklisted: "nosign"
        }
    }

    var tint: Color {
        switch self {
        case .pendingApproval: .orange
        case .declined, .failed: .red
        case .processing: .blue
        case .partiallyAvailable: .teal
        case .available: .green
        case .deleted, .blocklisted: .red
        }
    }
}
