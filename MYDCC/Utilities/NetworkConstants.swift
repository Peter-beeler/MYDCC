//
//  NetworkConstants.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//


import Foundation

// Constants related to network operations for DCC-EX.
enum NetworkConstants {
    // The Bonjour service type advertised by WiThrottle servers (like DCC-EX).
    static let dccExServiceType = "_withrottle._tcp"
    // The domain for Bonjour service discovery (typically local).
    static let dccExServiceDomain = "local."
    // The default port for DCC-EX WiThrottle server.
    static let dccExPort: UInt16 = 2560
}