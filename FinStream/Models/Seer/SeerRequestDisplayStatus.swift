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

    init(requestStatus: SeerRequestStatus, mediaStatus: SeerMediaStatus?) {
        switch (requestStatus, mediaStatus) {
        case (.pending, _): self = .pendingApproval
        case (.declined, _): self = .declined
        case (.failed, _): self = .failed
        case (_, .available): self = .available
        case (_, .partiallyAvailable): self = .partiallyAvailable
        case (.completed, _): self = .available
        default: self = .processing
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
        }
    }

    var tint: Color {
        switch self {
        case .pendingApproval: .orange
        case .declined, .failed: .red
        case .processing: .blue
        case .partiallyAvailable: .teal
        case .available: .green
        }
    }
}
