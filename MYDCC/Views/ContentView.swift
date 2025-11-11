//
//  ContentView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//


import SwiftUI

struct ContentView: View {
    // Access the shared ViewModel from the environment
    @EnvironmentObject var viewModel: ThrottleViewModel
    @AppStorage("isHapticFeedbackOn") private var isHapticFeedbackOn = true
    @State private var showingEmergencyStop = false
    @State private var showingTrackManagement = false
    @State private var functionStates: [Bool] = Array(repeating: false, count: 8)
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        // Use iPad-optimized view on iPad, regular view on iPhone
        if DeviceType.isiPad {
            iPadThrottleView()
                .environmentObject(viewModel)
        } else {
            iPhoneThrottleView
        }
    }

    // MARK: - iPhone Throttle View
    private var iPhoneThrottleView: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Connection Status and Selected Station
                        if viewModel.isConnected, let station = viewModel.selectedStation {
                            connectedView(station: station)
                        } else {
                            connectionView
                        }

                        // Section for Locomotive Control (only if connected)
                        if viewModel.isConnected {
                            throttleControlView
                        }
                    }
                    .padding(.bottom, 100) // Add padding to prevent tab bar overlap
                }
                .onTapGesture {
                    // Dismiss keyboard when tapping outside
                    isAddressFocused = false
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
                // Start continuous monitoring when the view appears
                viewModel.scanForStations()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Connected View
    private func connectedView(station: DCCEXStation) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.successGreen)
                .frame(width: 8, height: 8)
            Text("Connected: \(station.name)")
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Button {
                viewModel.disconnect()
            } label: {
                Text("Disconnect")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.dangerRed)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.cardDark)
    }

    // MARK: - Connection View
    private var connectionView: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Connect to a Station")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            // Show station list when not connected
            if viewModel.discoveredStations.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentBlue))
                        .scaleEffect(1.2)
                    Text("Scanning for DCC-EX stations...")
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.discoveredStations) { station in
                        StationRow(station: station)
                            .onTapGesture {
                                // Only allow connecting to online stations
                                if station.isOnline {
                                    viewModel.connect(to: station)
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Throttle Control View
    private var throttleControlView: some View {
        VStack(spacing: 20) {
            Divider()
                .background(Color.borderDark)
                .padding(.horizontal)

            // Selected Locomotive Info
            if let loco = viewModel.selectedLocomotive {
                HStack(spacing: 16) {
                    // Locomotive image or placeholder
                    if let imageName = loco.imageName,
                       let uiImage = loadLocoImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 60, height: 60)

                            Image(systemName: "train.side.front.car")
                                .font(.title2)
                                .foregroundColor(.accentBlue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(loco.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("Address: \(loco.address) • \(loco.maxSpeed) steps")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    if loco.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.cautionYellow)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            // Message Activity Indicator
            if !viewModel.lastServerMessage.isEmpty {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.successGreen)
                        .frame(width: 8, height: 8)
                    Text(viewModel.lastServerMessage)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
                .transition(.opacity)
            }

            // Loco Address Section (NEVER DISABLED)
            VStack(spacing: 12) {
                Text("Locomotive Control")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 12) {
                    Text("Address:")
                        .foregroundColor(.textSecondary)
                    TextField("e.g., 3", text: $viewModel.locomotiveAddress)
                        .keyboardType(.numberPad)
                        .focused($isAddressFocused)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.textPrimary)
                        .frame(width: 100)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isAddressFocused = false
                                }
                            }
                        }
                    Button {
                        isAddressFocused = false
                        viewModel.onLocomotiveAddressChanged()
                    } label: {
                        Text("Set")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.accentBlue)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.locomotiveAddress.isEmpty)
                }
            }
            .padding(.horizontal)

            // Track Power Warning
            if viewModel.trackA.powerState == .off && viewModel.trackB.powerState == .off {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("Tracks are powered OFF. Enable track power to control locomotives.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(.cautionYellow)
                .padding()
                .background(Color.cautionYellow.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            // Control Section (DISABLED when no address or no track power)
            VStack(spacing: 20) {
                // Speed Display
                VStack(spacing: 8) {
                    Text("\(Int(viewModel.currentSpeed * 126))")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Speed")
                        .font(.headline)
                        .foregroundColor(.textSecondary)
                }

                // Speed Slider
                DCCSliderView(value: $viewModel.currentSpeed, onRelease: { newSpeed in
                    viewModel.setSpeed(newSpeed)
                }, enableHaptic: isHapticFeedbackOn)
                .padding(.horizontal, 24)

                // Direction Control
                Picker("Direction", selection: $viewModel.currentDirectionIsForward) {
                    Text("Forward").tag(true)
                    Text("Reverse").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: viewModel.currentDirectionIsForward) { _, newValue in
                    viewModel.setDirection(isForward: newValue)
                }

                // Stop and Emergency Stop Buttons
                HStack(spacing: 12) {
                    // Stop Button (stops selected loco only)
                    Button {
                        viewModel.stopLocomotive()
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("STOP")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cautionYellow)
                        .cornerRadius(16)
                    }

                    // Emergency Stop Button (stops ALL trains)
                    Button {
                        showingEmergencyStop = true
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("E-STOP ALL")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.dangerRed)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)

                // Function Buttons Grid
                VStack(spacing: 12) {
                    Text("Functions")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(0..<8) { index in
                            FunctionButton(
                                functionNumber: index,
                                isActive: functionStates[index]
                            ) {
                                // Haptic feedback
                                if isHapticFeedbackOn {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                                functionStates[index].toggle()
                                viewModel.setFunction(index, state: functionStates[index])
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .disabled(viewModel.locomotiveAddress.isEmpty || (viewModel.trackA.powerState == .off && viewModel.trackB.powerState == .off))
            .opacity((viewModel.locomotiveAddress.isEmpty || (viewModel.trackA.powerState == .off && viewModel.trackB.powerState == .off)) ? 0.5 : 1.0)
        }
        .sheet(isPresented: $showingEmergencyStop) {
            EmergencyStopView()
                .environmentObject(viewModel)
        }
    }

    // MARK: - Helper Functions

    private func loadLocoImage(named: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(named),
           let imageData = try? Data(contentsOf: filePath) {
            return UIImage(data: imageData)
        }
        return nil
    }
}

// MARK: - Station Row View
struct StationRow: View {
    let station: DCCEXStation

    var body: some View {
        HStack(spacing: 16) {
            // Train icon
            Image(systemName: "train.side.front.car")
                .font(.title2)
                .foregroundColor(station.isOnline ? .accentBlue : .gray)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

            // Station info
            VStack(alignment: .leading, spacing: 6) {
                Text(station.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text(station.ipAddress)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Status indicator
            if station.isOnline {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.successGreen)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.successGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.successGreen.opacity(0.15))
                .cornerRadius(12)
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.dangerRed)
                        .frame(width: 8, height: 8)
                    Text("Offline")
                        .font(.caption)
                        .foregroundColor(.dangerRed)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.dangerRed.opacity(0.15))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.cardDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(station.isOnline ? Color.accentBlue.opacity(0.3) : Color.borderDark, lineWidth: 1)
        )
        .opacity(station.isOnline ? 1.0 : 0.6)
    }
}

// MARK: - DCC Speed Slider
struct DCCSliderView: View {
    @Binding var value: Double
    let onRelease: (Double) -> Void
    var enableHaptic: Bool = true

    @State private var lastHapticValue: Double = 0
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 12)

                // Progress track
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.dccBlue, Color.accentBlue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(value), height: 12)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: geometry.size.width * CGFloat(value) - 16)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                    if enableHaptic {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                }

                                let newValue = Double(gesture.location.x / geometry.size.width)
                                    .clamped(to: 0...1)
                                value = newValue

                                // Haptic feedback every ~10% change
                                if enableHaptic {
                                    let speedStep = Int(newValue * 12.6) // 126 steps / 10
                                    let lastStep = Int(lastHapticValue * 12.6)
                                    if speedStep != lastStep {
                                        let generator = UISelectionFeedbackGenerator()
                                        generator.selectionChanged()
                                        lastHapticValue = newValue
                                    }
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                if enableHaptic {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                }
                                onRelease(value)
                            }
                    )
            }
        }
        .frame(height: 32)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Function Button
struct FunctionButton: View {
    let functionNumber: Int
    let isActive: Bool
    let action: () -> Void

    private var functionLabel: String {
        switch functionNumber {
        case 0: return "Lights"
        case 1: return "Bell"
        case 2: return "Horn"
        case 3: return "Coupler"
        case 4: return "Smoke"
        case 5: return "Mute"
        case 6: return "Dim"
        case 7: return "Aux"
        default: return "F\(functionNumber)"
        }
    }

    private var functionIcon: String {
        switch functionNumber {
        case 0: return "lightbulb"
        case 1: return "bell"
        case 2: return "speaker.wave.2"
        case 3: return "link"
        case 4: return "smoke"
        case 5: return "speaker.slash"
        case 6: return "sun.min"
        case 7: return "gearshape"
        default: return "f.circle"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: functionIcon)
                    .font(.title2)
                Text(functionLabel)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .foregroundColor(isActive ? .white : .textSecondary)
            .background(isActive ? Color.dccBlue : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.dccBlue : Color.borderDark, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock ViewModel for previewing purposes
        let mockViewModel = ThrottleViewModel(networkService: MockDCCEXNetworkService())
        // Simulate some discovered stations for the preview
        mockViewModel.discoveredStations = [
            DCCEXStation(name: "My DCC-EX", hostName: "dcc-ex.local", ipAddress: "192.168.1.100", port: 2560, isOnline: true),
            DCCEXStation(name: "Test Rig", hostName: "test-rig.local", ipAddress: "192.168.1.102", port: 2560, isOnline: false)
        ]

        return ContentView()
            .environmentObject(mockViewModel)
    }
}

// Mock Network Service for Previews and Testing
class MockDCCEXNetworkService: DCCEXNetworkServiceProtocol {
    @Published var _discoveredStations: [DCCEXStation] = []
    var discoveredStationsPublisher: Published<[DCCEXStation]>.Publisher { $_discoveredStations }

    @Published var _isConnected: Bool = false
    var connectionStatusPublisher: Published<Bool>.Publisher { $_isConnected }

    @Published var _lastReceivedMessage: String? = nil
    var lastReceivedMessagePublisher: Published<String?>.Publisher { $_lastReceivedMessage }

    func startDiscovery() { print("Mock: Start Discovery") }
    func stopDiscovery() { print("Mock: Stop Discovery") }
    func connect(to station: DCCEXStation) {
        print("Mock: Connect to \(station.name)")
        _isConnected = true
        _lastReceivedMessage = "Connected to mock station."
    }
    func disconnect() {
        print("Mock: Disconnect")
        _isConnected = false
        _lastReceivedMessage = "Disconnected from mock station."
    }
    func sendCommand(_ command: String) {
        print("Mock: Send Command: \(command)")
        _lastReceivedMessage = "Sent: \(command)"
    }
}
