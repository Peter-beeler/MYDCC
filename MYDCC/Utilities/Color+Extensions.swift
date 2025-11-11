//
//  Color+Extensions.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

extension Color {
    // MARK: - Hex Initializer

    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    // MARK: - Adaptive Light/Dark Mode Initializer

    /// Creates a color that adapts between light and dark appearance
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light:
                return UIColor(light)
            case .dark:
                return UIColor(dark)
            case .unspecified:
                return UIColor(dark)
            @unknown default:
                return UIColor(dark)
            }
        })
    }

    // MARK: - Theme Colors (Adaptive Light/Dark Mode)

    // Background colors - adapt to light/dark mode
    static let backgroundDark = Color(
        light: Color(hex: "#F5F5F7"),  // Light gray for light mode
        dark: Color(hex: "#101922")     // Dark blue-gray for dark mode
    )

    static let cardDark = Color(
        light: Color(hex: "#FFFFFF"),   // White cards in light mode
        dark: Color(hex: "#1c2127")     // Dark cards in dark mode
    )

    // Text colors - adapt to light/dark mode
    static let textPrimary = Color(
        light: Color(hex: "#1C1C1E"),   // Almost black for light mode
        dark: Color(hex: "#FFFFFF")     // White for dark mode
    )

    static let textSecondary = Color(
        light: Color(hex: "#6E6E73"),   // Gray for light mode
        dark: Color(hex: "#9dabb9")     // Light gray for dark mode
    )

    // Border colors - adapt to light/dark mode
    static let borderDark = Color(
        light: Color(hex: "#D1D1D6"),   // Light gray border
        dark: Color(hex: "#374151")     // Dark gray border
    )

    // Accent colors - same in both modes (iOS standard)
    static let accentBlue = Color(hex: "#007AFF")
    static let successGreen = Color(hex: "#34C759")
    static let cautionYellow = Color(hex: "#FFCC00")
    static let dangerRed = Color(hex: "#FF3B30")

    // DCC-specific colors
    static let dccBlue = Color(hex: "#137fec")

    // MARK: - Adaptive Color Helper

    /// Creates a color that adapts between light and dark mode
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(light: light, dark: dark)
    }
}
