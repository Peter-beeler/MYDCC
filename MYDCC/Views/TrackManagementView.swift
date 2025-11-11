//
//  TrackManagementView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

struct TrackManagementView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ThrottleViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Track A
                        TrackCard(
                            track: viewModel.trackA,
                            onPowerToggle: {
                                viewModel.toggleTrackPower(trackId: "A")
                            },
                            onModeChange: { mode in
                                viewModel.setTrackMode(trackId: "A", mode: mode)
                            }
                        )

                        // Track B
                        TrackCard(
                            track: viewModel.trackB,
                            onPowerToggle: {
                                viewModel.toggleTrackPower(trackId: "B")
                            },
                            onModeChange: { mode in
                                viewModel.setTrackMode(trackId: "B", mode: mode)
                            }
                        )

                        // All Tracks Control
                        VStack(spacing: 16) {
                            Text("All Tracks")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 12) {
                                Button {
                                    viewModel.powerOnAllTracks()
                                } label: {
                                    HStack {
                                        Image(systemName: "power")
                                        Text("Power ON All")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.successGreen)
                                    .cornerRadius(12)
                                }

                                Button {
                                    viewModel.powerOffAllTracks()
                                } label: {
                                    HStack {
                                        Image(systemName: "poweroff")
                                        Text("Power OFF All")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.dangerRed)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color.cardDark)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.borderDark, lineWidth: 1)
                        )

                        // Info message
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text("Tracks must be powered ON to control locomotives")
                                .font(.caption)
                        }
                        .foregroundColor(.textSecondary)
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Track Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentBlue)
                }
            }
        }
    }
}

// MARK: - Track Card
struct TrackCard: View {
    let track: Track
    let onPowerToggle: () -> Void
    let onModeChange: (TrackMode) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Track header
            HStack {
                // Track name and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(track.powerState == .on ? Color.successGreen : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(track.powerState == .on ? "Powered ON" : "Powered OFF")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                // Power toggle
                Button {
                    onPowerToggle()
                } label: {
                    Image(systemName: track.powerState == .on ? "power.circle.fill" : "power.circle")
                        .font(.system(size: 32))
                        .foregroundColor(track.powerState == .on ? .successGreen : .gray)
                }
            }

            Divider()
                .background(Color.borderDark)

            // Mode selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Mode")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Picker("Mode", selection: Binding(
                    get: { track.mode },
                    set: { onModeChange($0) }
                )) {
                    ForEach(TrackMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(track.powerState == .on) // Can't change mode while powered on
            }

            if track.powerState == .on && track.mode == .program {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("Program mode active - use for CV programming only")
                        .font(.caption2)
                }
                .foregroundColor(.cautionYellow)
            }
        }
        .padding()
        .background(Color.cardDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(track.powerState == .on ? Color.successGreen.opacity(0.5) : Color.borderDark, lineWidth: 2)
        )
    }
}

// MARK: - Preview
struct TrackManagementView_Previews: PreviewProvider {
    static var previews: some View {
        TrackManagementView()
            .environmentObject(ThrottleViewModel())
    }
}
