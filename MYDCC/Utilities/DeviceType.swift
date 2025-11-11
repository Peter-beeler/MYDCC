//
//  DeviceType.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

/// Utility for detecting device type and size classes
struct DeviceType {
    /// Check if running on iPad
    static var isiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Check if running on iPhone
    static var isiPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    /// Check if current horizontal size class is regular (typically iPad in landscape)
    static func isRegularWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }

    /// Check if current vertical size class is regular (typically iPad)
    static func isRegularHeight(_ verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
        verticalSizeClass == .regular
    }

    /// Check if device has compact size (iPhone or iPad in certain orientations)
    static func isCompact(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .compact
    }
}

/// Environment value for device type awareness
struct DeviceTypeKey: EnvironmentKey {
    static let defaultValue: Bool = DeviceType.isiPad
}

extension EnvironmentValues {
    var isiPad: Bool {
        get { self[DeviceTypeKey.self] }
        set { self[DeviceTypeKey.self] = newValue }
    }
}

/// View extension for adaptive layouts
extension View {
    /// Apply different modifiers based on device type
    @ViewBuilder
    func adaptiveLayout<iPadContent: View, iPhoneContent: View>(
        iPad: () -> iPadContent,
        iPhone: () -> iPhoneContent
    ) -> some View {
        if DeviceType.isiPad {
            iPad()
        } else {
            iPhone()
        }
    }

    /// Apply modifier only on iPad
    @ViewBuilder
    func iPadOnly<Content: View>(_ modifier: () -> Content) -> some View {
        if DeviceType.isiPad {
            modifier()
        } else {
            self
        }
    }

    /// Apply modifier only on iPhone
    @ViewBuilder
    func iPhoneOnly<Content: View>(_ modifier: () -> Content) -> some View {
        if DeviceType.isiPhone {
            modifier()
        } else {
            self
        }
    }

    /// Adaptive padding based on device
    func adaptivePadding(_ edges: Edge.Set = .all) -> some View {
        self.padding(edges, DeviceType.isiPad ? 24 : 16)
    }

    /// Adaptive frame based on device
    func adaptiveFrame(
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        let iPadMaxWidth = maxWidth.map { $0 * 1.5 }
        let iPadMaxHeight = maxHeight.map { $0 * 1.5 }

        return self.frame(
            maxWidth: DeviceType.isiPad ? iPadMaxWidth : maxWidth,
            maxHeight: DeviceType.isiPad ? iPadMaxHeight : maxHeight,
            alignment: alignment
        )
    }
}
