//
//  ProgrammingView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

struct ProgrammingView: View {
    @EnvironmentObject var viewModel: ThrottleViewModel
    @State private var selectedTab = 0
    @State private var cvNumber: String = "1"
    @State private var cvValue: String = "0"
    @State private var locoAddress: String = "3"
    @State private var isReading = false
    @State private var readResult: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var currentReadOperation: String = "" // Track what we're reading

    // Check if either track is in program mode and powered on
    private var isProgramTrackActive: Bool {
        (viewModel.trackA.mode == .program && viewModel.trackA.powerState == .on) ||
        (viewModel.trackB.mode == .program && viewModel.trackB.powerState == .on)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                if !isProgramTrackActive {
                    // Show message when no program track is active
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.cautionYellow)

                        Text("No Programming Track Active")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        Text("To use programming features:\n1. Set Track A or B to 'Program' mode\n2. Power ON the programming track")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            // Navigate to track management (you could add navigation)
                        } label: {
                            Text("Go to Track Management")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.accentBlue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Active track indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.successGreen)
                                    .frame(width: 12, height: 12)

                                Text(viewModel.trackA.mode == .program && viewModel.trackA.powerState == .on
                                     ? "Track A: Programming Mode Active"
                                     : "Track B: Programming Mode Active")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)

                                Spacer()
                            }
                            .padding(.horizontal)

                            // Tab selector
                            Picker("Function", selection: $selectedTab) {
                                Text("Decoder Address").tag(0)
                                Text("CV Operations").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)

                            if selectedTab == 0 {
                                // Decoder Address Programming
                                decoderAddressView
                            } else {
                                // CV Read/Write
                                cvOperationsView
                            }

                            // Safety warning
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Safety Reminder")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Text("Ensure only ONE locomotive is on the programming track")
                                        .font(.caption2)
                                }
                            }
                            .foregroundColor(.cautionYellow)
                            .padding()
                            .background(Color.cautionYellow.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Decoder Programming")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Programming Result", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: viewModel.programmingResponse) { _, newResponse in
                handleProgrammingResponse(newResponse)
            }
        }
    }

    // Handle programming responses from the station
    private func handleProgrammingResponse(_ response: ProgrammingResponse?) {
        guard let response = response else { return }

        isReading = false

        switch response.type {
        case "read_address", "read_value":
            readResult = String(response.value)
            if currentReadOperation == "address" {
                alertMessage = "Address read successfully: \(response.value)"
                showAlert = true
            }

        case "read_cv":
            readResult = String(response.value)
            if currentReadOperation == "cv" {
                alertMessage = "CV \(cvNumber) = \(response.value)"
                showAlert = true
            }

        case "write_address":
            alertMessage = "Address \(response.value) written successfully"
            showAlert = true

        case "write_cv":
            alertMessage = "CV written successfully"
            showAlert = true

        case "verify_cv":
            readResult = String(response.value)
            alertMessage = "CV verified: \(response.value)"
            showAlert = true

        default:
            break
        }

        currentReadOperation = ""
    }

    // MARK: - Decoder Address View
    private var decoderAddressView: some View {
        VStack(spacing: 20) {
            // Read Address Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.accentBlue)
                    Text("Read Decoder Address")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }

                Text("Read the current DCC address from the decoder on the programming track")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !readResult.isEmpty {
                    HStack {
                        Text("Current Address:")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Text(readResult)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.successGreen)
                        Spacer()
                    }
                    .padding()
                    .background(Color.successGreen.opacity(0.1))
                    .cornerRadius(8)
                }

                Button {
                    readDecoderAddress()
                } label: {
                    HStack {
                        if isReading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Image(systemName: "arrow.down.circle.fill")
                        Text(isReading ? "Reading..." : "Read Address")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isReading ? Color.gray : Color.accentBlue)
                    .cornerRadius(12)
                }
                .disabled(isReading)
            }
            .padding()
            .background(Color.cardDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDark, lineWidth: 1)
            )

            // Write Address Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.successGreen)
                    Text("Write Decoder Address")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }

                Text("Program a new DCC address to the decoder. Supports both short (1-127) and long (128-10239) addresses.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("New Address")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    TextField("Enter address (1-10239)", text: $locoAddress)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.backgroundDark)
                        .cornerRadius(8)
                }

                Button {
                    writeDecoderAddress()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Write Address")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.successGreen)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.cardDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDark, lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    // MARK: - CV Operations View
    private var cvOperationsView: some View {
        VStack(spacing: 20) {
            // Read CV Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.accentBlue)
                    Text("Read CV")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }

                Text("Read a Configuration Variable value from the decoder")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("CV Number")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    TextField("Enter CV (1-1024)", text: $cvNumber)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.backgroundDark)
                        .cornerRadius(8)
                }

                if !readResult.isEmpty {
                    HStack {
                        Text("CV Value:")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Text(readResult)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.successGreen)
                        Spacer()
                    }
                    .padding()
                    .background(Color.successGreen.opacity(0.1))
                    .cornerRadius(8)
                }

                Button {
                    readCV()
                } label: {
                    HStack {
                        if isReading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Image(systemName: "arrow.down.circle.fill")
                        Text(isReading ? "Reading..." : "Read CV")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isReading ? Color.gray : Color.accentBlue)
                    .cornerRadius(12)
                }
                .disabled(isReading)
            }
            .padding()
            .background(Color.cardDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDark, lineWidth: 1)
            )

            // Write CV Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.successGreen)
                    Text("Write CV")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }

                Text("Write a value to a Configuration Variable")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("CV Number")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    TextField("Enter CV (1-1024)", text: $cvNumber)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.backgroundDark)
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("CV Value")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    TextField("Enter value (0-255)", text: $cvValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.backgroundDark)
                        .cornerRadius(8)
                }

                Button {
                    writeCV()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Write CV")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.successGreen)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.cardDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDark, lineWidth: 1)
            )

            // Common CVs Reference
            commonCVsReference
        }
        .padding(.horizontal)
    }

    // MARK: - Common CVs Reference
    private var commonCVsReference: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundColor(.accentBlue)
                Text("Common CVs")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                cvReferenceRow(cv: "1", description: "Primary Address (1-127)")
                cvReferenceRow(cv: "17-18", description: "Extended Address (128-10239)")
                cvReferenceRow(cv: "7", description: "Decoder Version")
                cvReferenceRow(cv: "8", description: "Manufacturer ID")
                cvReferenceRow(cv: "29", description: "Configuration Data")
                cvReferenceRow(cv: "3", description: "Acceleration Rate")
                cvReferenceRow(cv: "4", description: "Deceleration Rate")
            }
            .font(.caption)
        }
        .padding()
        .background(Color.cardDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderDark, lineWidth: 1)
        )
    }

    private func cvReferenceRow(cv: String, description: String) -> some View {
        HStack {
            Text("CV \(cv):")
                .fontWeight(.medium)
                .foregroundColor(.accentBlue)
            Text(description)
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }

    // MARK: - Programming Functions
    private func readDecoderAddress() {
        isReading = true
        readResult = ""
        currentReadOperation = "address"

        // Send <R> command to read loco address
        viewModel.sendCommand("<R>")

        // Set timeout in case no response
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.isReading {
                self.isReading = false
                self.alertMessage = "Read timeout. Please try again."
                self.showAlert = true
                self.currentReadOperation = ""
            }
        }
    }

    private func writeDecoderAddress() {
        guard let address = Int(locoAddress), address > 0 && address < 10240 else {
            alertMessage = "Invalid address. Must be between 1 and 10239."
            showAlert = true
            return
        }

        // Send <W ADDRESS> command
        viewModel.sendCommand("<W \(address)>")

        alertMessage = "Writing address \(address) to decoder..."
        showAlert = true
    }

    private func readCV() {
        guard let cv = Int(cvNumber), cv > 0 && cv <= 1024 else {
            alertMessage = "Invalid CV number. Must be between 1 and 1024."
            showAlert = true
            return
        }

        isReading = true
        readResult = ""
        currentReadOperation = "cv"

        // Send <R CV> command
        viewModel.sendCommand("<R \(cv)>")

        // Set timeout in case no response
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.isReading {
                self.isReading = false
                self.alertMessage = "Read timeout. Please try again."
                self.showAlert = true
                self.currentReadOperation = ""
            }
        }
    }

    private func writeCV() {
        guard let cv = Int(cvNumber), cv > 0 && cv <= 1024 else {
            alertMessage = "Invalid CV number. Must be between 1 and 1024."
            showAlert = true
            return
        }

        guard let value = Int(cvValue), value >= 0 && value <= 255 else {
            alertMessage = "Invalid CV value. Must be between 0 and 255."
            showAlert = true
            return
        }

        // Send <W CV VALUE> command
        viewModel.sendCommand("<W \(cv) \(value)>")

        alertMessage = "Writing \(value) to CV \(cv)..."
        showAlert = true
    }
}

// MARK: - Preview
struct ProgrammingView_Previews: PreviewProvider {
    static var previews: some View {
        ProgrammingView()
            .environmentObject(ThrottleViewModel())
    }
}
