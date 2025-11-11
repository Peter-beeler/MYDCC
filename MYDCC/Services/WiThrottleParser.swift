//
//  WiThrottleParser.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import Foundation

/// Represents different types of WiThrottle messages
enum WiThrottleMessage {
    case speed(throttle: String, cab: Int, speed: Int)
    case direction(throttle: String, cab: Int, forward: Bool)
    case function(throttle: String, cab: Int, functionNum: Int, state: Bool)
    case heartbeat
    case unknown(String)
}

/// Parser for WiThrottle protocol messages
class WiThrottleParser {

    /// Parse a WiThrottle message string
    /// - Parameter message: The raw message string from the station
    /// - Returns: Parsed WiThrottleMessage or nil if not parseable
    static func parse(_ message: String) -> WiThrottleMessage? {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty or too short
        guard !trimmed.isEmpty else { return nil }

        // Heartbeat message
        if trimmed == "*" {
            return .heartbeat
        }

        // Multi-throttle message format: M<throttle>A<action>...
        if trimmed.hasPrefix("M") {
            return parseMultiThrottle(trimmed)
        }

        // Unknown message type
        return .unknown(trimmed)
    }

    /// Parse multi-throttle (MT) messages
    /// Format: MTA<L/S><cab><;><command><value>
    /// Example: MTA0L3<;>V50
    private static func parseMultiThrottle(_ message: String) -> WiThrottleMessage? {
        // Minimum: M T A L 1 < ; > V 0 = 10 chars
        guard message.count >= 10 else { return .unknown(message) }

        let chars = Array(message)

        // Extract throttle character (position 1)
        let throttleChar = String(chars[1])

        // Extract action indicator (position 2) - should be 'A'
        guard chars[2] == "A" else { return .unknown(message) }

        // Find the separator <;>
        guard let separatorRange = message.range(of: "<;>") else {
            return .unknown(message)
        }

        // Extract loco info (between A and <;>)
        let locoStartIndex = message.index(message.startIndex, offsetBy: 3)
        let locoInfo = String(message[locoStartIndex..<separatorRange.lowerBound])

        // Parse loco address
        // Format: <L/S><address>
        guard locoInfo.count >= 2 else { return .unknown(message) }
        // First character is address type (L=long, S=short) - not used currently
        let addressString = String(locoInfo.dropFirst())
        guard let cabNumber = Int(addressString) else { return .unknown(message) }

        // Extract command after <;>
        let commandStart = message.index(separatorRange.upperBound, offsetBy: 0)
        let command = String(message[commandStart...])

        // Parse command type
        guard command.count >= 2 else { return .unknown(message) }
        let commandType = command.first!
        let commandValue = String(command.dropFirst())

        switch commandType {
        case "V": // Velocity (speed)
            if let speed = Int(commandValue) {
                return .speed(throttle: throttleChar, cab: cabNumber, speed: speed)
            }

        case "R": // Reverse/Direction
            if let dirValue = Int(commandValue) {
                return .direction(throttle: throttleChar, cab: cabNumber, forward: dirValue != 0)
            }

        case "F": // Function
            // Format: F<state><number>
            // Example: F15 = function 5 on, F05 = function 5 off
            if commandValue.count >= 2 {
                let state = commandValue.first! == "1"
                let fnNumString = String(commandValue.dropFirst())
                if let fnNum = Int(fnNumString) {
                    return .function(throttle: throttleChar, cab: cabNumber, functionNum: fnNum, state: state)
                }
            }

        default:
            break
        }

        return .unknown(message)
    }

    /// Convert WiThrottle speed (-1 to 126) to DCC speed (0-127)
    /// -1 = emergency stop
    /// 0 = stop
    /// 1-126 = speed steps
    static func wiThrottleToDCCSpeed(_ witSpeed: Int) -> Int {
        if witSpeed < 0 {
            return 0 // E-stop maps to 0
        }
        return witSpeed
    }

    /// Convert DCC speed (0-127) to WiThrottle speed (-1 to 126)
    static func dccToWiThrottleSpeed(_ dccSpeed: Int) -> Int {
        if dccSpeed == 0 {
            return 0
        }
        return min(dccSpeed, 126)
    }
}

// MARK: - Message Description Extension
extension WiThrottleMessage: CustomStringConvertible {
    var description: String {
        switch self {
        case .speed(let throttle, let cab, let speed):
            return "Speed: Loco \(cab) → \(speed) (Throttle \(throttle))"
        case .direction(let throttle, let cab, let forward):
            return "Direction: Loco \(cab) → \(forward ? "Forward" : "Reverse") (Throttle \(throttle))"
        case .function(let throttle, let cab, let fnNum, let state):
            return "Function: Loco \(cab) F\(fnNum) → \(state ? "ON" : "OFF") (Throttle \(throttle))"
        case .heartbeat:
            return "Heartbeat"
        case .unknown(let msg):
            return "Unknown: \(msg)"
        }
    }
}
