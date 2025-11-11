//
//  Track.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import Foundation

// Track mode: Main (operations) or Program (programming CVs)
enum TrackMode: String, CaseIterable {
    case main = "Main"
    case program = "Program"
}

// Track state: power on/off
enum TrackPowerState {
    case on
    case off
}

// Represents a DCC track (A or B)
struct Track: Identifiable, Equatable {
    let id: String
    let name: String
    var powerState: TrackPowerState
    var mode: TrackMode

    static let trackA = Track(id: "A", name: "Track A", powerState: .off, mode: .main)
    static let trackB = Track(id: "B", name: "Track B", powerState: .off, mode: .main)
}
