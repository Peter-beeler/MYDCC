//
//  SettingsView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: ThrottleViewModel
    @AppStorage("isHapticFeedbackOn") private var isHapticFeedbackOn = true
    @State private var defaultSpeedSteps = 128

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDark.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Connection Status Section
                        Section(header: SectionHeader(title: "Connection Status")) {
                            CardView {
                                ConnectionStatusCard()
                            }
                        }

                        // Discovered Stations Section
                        if !viewModel.discoveredStations.isEmpty {
                            Section(header: SectionHeader(title: "Discovered Stations")) {
                                CardView {
                                    VStack(spacing: 0) {
                                        ForEach(Array(viewModel.discoveredStations.enumerated()), id: \.element.id) { index, station in
                                            VStack(spacing: 0) {
                                                SettingsRow(
                                                    title: station.name,
                                                    value: station.ipAddress,
                                                    icon: "train.side.front.car",
                                                    badge: station.isOnline ? "Online" : "Offline",
                                                    badgeColor: station.isOnline ? .successGreen : .dangerRed
                                                )

                                                if index < viewModel.discoveredStations.count - 1 {
                                                    Divider()
                                                        .background(Color.borderDark)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // General Settings Section
                        Section(header: SectionHeader(title: "General")) {
                            CardView {
                                VStack(spacing: 0) {
                                    Picker("Default Speed Steps", selection: $defaultSpeedSteps) {
                                        Text("28").tag(28)
                                        Text("128").tag(128)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .padding()

                                    Divider().background(Color.borderDark)

                                    Toggle("Haptic Feedback", isOn: $isHapticFeedbackOn)
                                        .padding()
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }

                        // About Section
                        Section(header: SectionHeader(title: "About")) {
                            CardView {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Version")
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                        Text("1.0.0")
                                            .foregroundColor(.textPrimary)
                                    }

                                    Divider().background(Color.borderDark)

                                    HStack {
                                        Text("DCC-EX Protocol")
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                        Text("WiThrottle")
                                            .foregroundColor(.textPrimary)
                                    }

                                    Divider().background(Color.borderDark)

                                    HStack {
                                        Text("Port")
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                        Text("2560")
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                                .padding()
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.textSecondary)
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.cardDark)
            .cornerRadius(16)
            .padding(.horizontal)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let value: String
    var icon: String? = nil
    var badge: String? = nil
    var badgeColor: Color = .accentBlue

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.accentBlue)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.15))
                    .cornerRadius(8)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
                    .font(.caption)
            }
        }
        .padding()
    }
}

// MARK: - Connection Status Card
struct ConnectionStatusCard: View {
    @EnvironmentObject var viewModel: ThrottleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(viewModel.isConnected ? Color.successGreen : Color.dangerRed)
                    .frame(width: 12, height: 12)
                Text(viewModel.isConnected ? "Connected" : "Disconnected")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }

            if viewModel.isConnected, let station = viewModel.selectedStation {
                // Connection details
                VStack(spacing: 10) {
                    HStack {
                        Text("Station")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(station.name)
                            .foregroundColor(.textPrimary)
                    }

                    Divider().background(Color.borderDark)

                    HStack {
                        Text("Address")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(station.ipAddress)
                            .foregroundColor(.textPrimary)
                    }

                    Divider().background(Color.borderDark)

                    HStack {
                        Text("Port")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("\(station.port)")
                            .foregroundColor(.textPrimary)
                    }

                    if !viewModel.lastServerMessage.isEmpty {
                        Divider().background(Color.borderDark)

                        HStack {
                            Text("Last Message")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(viewModel.lastServerMessage)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        viewModel.disconnect()
                    } label: {
                        Text("Disconnect")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.dangerRed.opacity(0.2))
                            .foregroundColor(.dangerRed)
                            .cornerRadius(10)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 8)
            } else {
                Text("Not connected to any station")
                    .foregroundColor(.textSecondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
    }
}

// MARK: - Previews
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThrottleViewModel())
    }
}
