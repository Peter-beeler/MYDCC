//
//  EmergencyStopView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

struct EmergencyStopView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ThrottleViewModel

    var body: some View {
        ZStack {
            // Dark red emergency background
            Color(hex: "#221010").edgesIgnoringSafeArea(.all)

            VStack(spacing: 32) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("EMERGENCY STOP")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("All Locomotives")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.dangerRed)
                }
                .padding(.top, 40)

                // Large circular stop button
                Button(action: executeEmergencyStop) {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 80))
                        Text("TAP TO STOP ALL")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .padding(50)
                    .foregroundColor(.white)
                    .background(Color(hex: "#ec1313"))
                    .clipShape(Circle())
                    .shadow(color: Color(hex: "#ec1313").opacity(0.6), radius: 25, x: 0, y: 12)
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)

                // Warning message
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("This will stop ALL trains on the track")
                            .font(.caption)
                    }
                    .foregroundColor(.cautionYellow)

                    Text("Use the yellow STOP button for a single locomotive")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Cancel button
                Button("Cancel") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 40)
            }
            .padding()
        }
    }

    private func executeEmergencyStop() {
        // Stop ALL locomotives using global emergency stop
        viewModel.emergencyStop()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

struct EmergencyStopView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyStopView()
            .environmentObject(ThrottleViewModel())
    }
}
