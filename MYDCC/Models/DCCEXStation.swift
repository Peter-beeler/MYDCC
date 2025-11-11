//
//  DCCEXStation.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//


import Foundation

// Represents a discovered DCC-EX Command Station.
// Identifiable: So it can be used in SwiftUI lists.
// Hashable: If you need to store it in sets or use it as dictionary keys.
struct DCCEXStation: Identifiable, Hashable {
    let id = UUID() // Unique identifier for list rendering
    let name: String // Bonjour service name or a user-friendly name
    let hostName: String // Resolved hostname (e.g., "dcc-ex.local")
    var ipAddress: String // Resolved IP address (mutable for async resolution)
    let port: Int // Port number (should be 2560)
    var isOnline: Bool = true // Online/Offline status

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(hostName)
        hasher.combine(ipAddress)
        hasher.combine(port)
    }

    // Conformance to Equatable (required for Hashable)
    static func == (lhs: DCCEXStation, rhs: DCCEXStation) -> Bool {
        return lhs.name == rhs.name &&
               lhs.hostName == rhs.hostName &&
               lhs.ipAddress == rhs.ipAddress &&
               lhs.port == rhs.port
    }
}

// Programming response from DCC-EX
struct ProgrammingResponse: Equatable {
    let type: String
    let value: Int
}
