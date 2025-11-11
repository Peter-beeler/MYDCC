//
//  Train.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//


import Foundation

// Represents the state of a train being controlled.
// This would be expanded to include functions, etc.
struct Train {
    let address: Int // DCC address of the locomotive
    var speed: Int = 0 // Speed value (e.g., 0-127 or 0-1023, depends on DCC-EX interpretation)
    var isForward: Bool = true // Direction

    // You might add more properties like:
    // var functions: [Bool] = Array(repeating: false, count: 29) // F0-F28
}
