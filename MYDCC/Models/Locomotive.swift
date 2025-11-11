//
//  Locomotive.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import Foundation
import SwiftUI

// Represents a locomotive in the user's roster
struct Locomotive: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var address: Int // DCC address
    var imageName: String? // Stored image filename
    var notes: String = ""
    var maxSpeed: Int = 128 // Speed steps (28, 128, etc.)
    var isFavorite: Bool = false
    var lastUsed: Date = Date()

    // Function labels (customize for each loco)
    var functionLabels: [String] = [
        "Lights", "Bell", "Horn", "Coupler",
        "Smoke", "Mute", "Dim", "Aux"
    ]

    static func == (lhs: Locomotive, rhs: Locomotive) -> Bool {
        lhs.id == rhs.id
    }
}

// Manager for locomotive roster with persistence
class LocomotiveRoster: ObservableObject {
    @Published var locomotives: [Locomotive] = []

    private let saveKey = "SavedLocomotives"

    init() {
        loadLocomotives()
    }

    func addLocomotive(_ loco: Locomotive) {
        var newLoco = loco
        newLoco.lastUsed = Date()
        locomotives.append(newLoco)
        locomotives.sort { $0.lastUsed > $1.lastUsed }
        saveLocomotives()
    }

    func updateLocomotive(_ loco: Locomotive) {
        if let index = locomotives.firstIndex(where: { $0.id == loco.id }) {
            var updated = loco
            updated.lastUsed = Date()
            locomotives[index] = updated
            locomotives.sort { $0.lastUsed > $1.lastUsed }
            saveLocomotives()
        }
    }

    func deleteLocomotive(_ loco: Locomotive) {
        locomotives.removeAll { $0.id == loco.id }
        saveLocomotives()
    }

    func deleteLocomotives(at offsets: IndexSet) {
        locomotives.remove(atOffsets: offsets)
        saveLocomotives()
    }

    func markAsUsed(_ loco: Locomotive) {
        if let index = locomotives.firstIndex(where: { $0.id == loco.id }) {
            locomotives[index].lastUsed = Date()
            locomotives.sort { $0.lastUsed > $1.lastUsed }
            saveLocomotives()
        }
    }

    private func saveLocomotives() {
        if let encoded = try? JSONEncoder().encode(locomotives) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadLocomotives() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Locomotive].self, from: data) {
            locomotives = decoded.sorted { $0.lastUsed > $1.lastUsed }
        } else {
            // Add sample locomotives for first launch
            locomotives = [
                Locomotive(name: "Big Boy 4014", address: 4014, maxSpeed: 128, isFavorite: true),
                Locomotive(name: "GP38-2 #3", address: 3, maxSpeed: 128),
                Locomotive(name: "SD40-2 #40", address: 40, maxSpeed: 128)
            ]
            saveLocomotives()
        }
    }
}
