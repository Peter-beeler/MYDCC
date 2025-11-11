//
//  iPadThrottleView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

/// iPad-optimized throttle view with side-by-side layout
struct iPadThrottleView: View {
    @EnvironmentObject var viewModel: ThrottleViewModel
    @AppStorage("isHapticFeedbackOn") private var isHapticFeedbackOn = true
    @State private var showingEmergencyStop = false
    @State private var showingTrackManagement = false
    @State private var functionStates: [Bool] = Array(repeating: false, count: 8)
    @FocusState private var isAddressFocused: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()

            if horizontalSizeClass == .regular {
                // iPad landscape: side-by-side layout
                HStack(spacing: 0) {
                    // Left side: Connection and Locomotive info
                    leftPanel
                        .frame(maxWidth: .infinity)

                    Divider()
                        .background(Color.borderDark)

                    // Right side: Throttle controls
                    rightPanel
                        .frame(maxWidth: .infinity)
                }
            } else {
                // iPad portrait: stacked layout (same as iPhone but with more spacing)
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.isConnected, let station = viewModel.selectedStation {
                            connectedView(station: station)
                        } else {
                            connectionView
                        }

                        if viewModel.isConnected {
                            throttleControlsCompact
                        }
                    }
                    .adaptivePadding()
                }
            }
        }
        .navigationTitle("Throttle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundDark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingTrackManagement = true
                } label: {
                    Image(systemName: "powerplug.fill")
                        .font(.title3)
                        .foregroundColor(.accentBlue)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.refreshScan()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showingTrackManagement) {
            TrackManagementView()
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.scanForStations()
        }
    }

    // MARK: - Left Panel (iPad Landscape)
    private var leftPanel: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isConnected, let station = viewModel.selectedStation {
                    connectedView(station: station)
                } else {
                    connectionView
                }

                if viewModel.isConnected {
                    locomotiveInfoSection
                    functionControlSection
                }

                Spacer(minLength: 20)
            }
            .adaptivePadding()
        }
    }

    // MARK: - Right Panel (iPad Landscape)
    private var rightPanel: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isConnected {
                    throttleControlsExpanded
                }
            }
            .adaptivePadding()
        }
    }

    // MARK: - Connected View
    private func connectedView(station: DCCEXStation) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.successGreen)
                .frame(width: 10, height: 10)
            Text("Connected: \(station.name)")
                .font(.headline)
                .foregroundColor(.textPrimary)
            Spacer()
            Button {
                viewModel.disconnect()
            } label: {
                Text("Disconnect")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dangerRed)
            }
        }
        .padding()
        .background(Color.cardDark)
        .cornerRadius(12)
    }

    // MARK: - Connection View
    private var connectionView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Connect to a Station")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            if viewModel.discoveredStations.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentBlue))
                        .scaleEffect(1.5)
                    Text("Scanning for DCC-EX stations...")
                        .font(.headline)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.discoveredStations) { station in
                        StationRow(station: station)
                            .onTapGesture {
                                if station.isOnline {
                                    viewModel.connect(to: station)
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: - Locomotive Info Section
    private var locomotiveInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Locomotive")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            if let loco = viewModel.selectedLocomotive {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(loco.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            HStack(spacing: 12) {
                                Label("\(loco.address)", systemImage: "number.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                if loco.isFavorite {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.cautionYellow)
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color.cardDark)
                .cornerRadius(12)
            } else {
                Text("No locomotive selected")
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cardDark)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Function Control Section
    private var functionControlSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Functions")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(0..<8) { fnNum in
                    iPadFunctionButton(
                        number: fnNum,
                        isOn: functionStates[fnNum],
                        action: {
                            toggleFunction(fnNum)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Throttle Controls (Expanded for iPad)
    private var throttleControlsExpanded: some View {
        VStack(spacing: 32) {
            // Speed Control
            VStack(spacing: 20) {
                HStack {
                    Text("Speed")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(Int(viewModel.currentSpeed * 126))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentBlue)
                }

                // Large slider
                Slider(value: $viewModel.currentSpeed, in: 0...1, step: 0.01)
                    .accentColor(.accentBlue)
                    .frame(height: 60)
                    .onChange(of: viewModel.currentSpeed) { _, _ in
                        viewModel.setSpeed(viewModel.currentSpeed)
                        if isHapticFeedbackOn {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
            }
            .padding(24)
            .background(Color.cardDark)
            .cornerRadius(16)

            // Direction Control
            HStack(spacing: 20) {
                iPadDirectionButton(
                    title: "Reverse",
                    icon: "arrow.backward",
                    isSelected: !viewModel.currentDirectionIsForward,
                    action: {
                        viewModel.setDirection(isForward: false)
                        if isHapticFeedbackOn {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                )

                iPadDirectionButton(
                    title: "Forward",
                    icon: "arrow.forward",
                    isSelected: viewModel.currentDirectionIsForward,
                    action: {
                        viewModel.setDirection(isForward: true)
                        if isHapticFeedbackOn {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                )
            }

            // Emergency Stop
            iPadEmergencyStopButton {
                showingEmergencyStop = true
            }
            .alert("Emergency Stop", isPresented: $showingEmergencyStop) {
                Button("Cancel", role: .cancel) { }
                Button("STOP ALL", role: .destructive) {
                    viewModel.emergencyStop()
                }
            } message: {
                Text("This will immediately stop ALL locomotives on the layout.")
            }
        }
    }

    // MARK: - Throttle Controls (Compact)
    private var throttleControlsCompact: some View {
        VStack(spacing: 20) {
            locomotiveInfoSection
            functionControlSection
            throttleControlsExpanded
        }
    }

    // MARK: - Helper Functions
    private func toggleFunction(_ fnNum: Int) {
        functionStates[fnNum].toggle()
        viewModel.setFunction(fnNum, state: functionStates[fnNum])
        if isHapticFeedbackOn {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Function Button
private struct iPadFunctionButton: View {
    let number: Int
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("F\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isOn ? Color.accentBlue : Color.cardDark)
            .foregroundColor(isOn ? .white : .textSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isOn ? Color.accentBlue : Color.borderDark, lineWidth: 2)
            )
        }
    }
}

// MARK: - Direction Button
private struct iPadDirectionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? Color.accentBlue : Color.cardDark)
            .foregroundColor(isSelected ? .white : .textSecondary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentBlue : Color.borderDark, lineWidth: 2)
            )
        }
    }
}

// MARK: - Emergency Stop Button
private struct iPadEmergencyStopButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.title)
                Text("EMERGENCY STOP")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.dangerRed)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
    }
}
