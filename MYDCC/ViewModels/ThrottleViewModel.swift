//
//  ThrottleViewModel.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//


import Foundation
import Combine // For using Cancellable to manage subscriptions

class ThrottleViewModel: ObservableObject {
    // Published properties that the View will observe
    @Published var discoveredStations: [DCCEXStation] = []
    @Published var selectedStation: DCCEXStation?
    @Published var isConnected: Bool = false
    @Published var currentSpeed: Double = 0 // 0.0 to 1.0 for a slider, then map to DCC steps
    @Published var currentDirectionIsForward: Bool = true
    @Published var locomotiveAddress: String = "3" // Default loco address
    @Published var lastServerMessage: String = ""

    // Selected locomotive from roster
    @Published var selectedLocomotive: Locomotive?

    // Console messages for debugging
    @Published var consoleMessages: [ConsoleMessage] = []

    // Track management
    @Published var trackA: Track = Track.trackA
    @Published var trackB: Track = Track.trackB

    // Programming track responses
    @Published var programmingResponse: ProgrammingResponse? = nil

    // The network service dependency
    private let networkService: DCCEXNetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>() // To store subscriptions

    // Initializer with dependency injection for testability
    init(networkService: DCCEXNetworkServiceProtocol = DCCEXNetworkService()) {
        self.networkService = networkService
        subscribeToNetworkService()
    }

    private func subscribeToNetworkService() {
        // Subscribe to discovered stations
        networkService.discoveredStationsPublisher
            .receive(on: DispatchQueue.main) // Ensure UI updates are on the main thread
            .sink { [weak self] stations in
                self?.discoveredStations = stations
            }
            .store(in: &cancellables)

        // Subscribe to connection status
        networkService.connectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isConnected = status
                if !status {
                    self?.selectedStation = nil // Clear selected station on disconnect
                }
            }
            .store(in: &cancellables)

        // Subscribe to last received message
        networkService.lastReceivedMessagePublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0 } // Ignore nil values
            .sink { [weak self] message in
                self?.lastServerMessage = message
                // Log received message to console
                self?.logMessage(message, direction: .received)
            }
            .store(in: &cancellables)

        // Subscribe to parsed speed updates from station
        if let concreteService = networkService as? DCCEXNetworkService {
            concreteService.$receivedSpeed
                .receive(on: DispatchQueue.main)
                .compactMap { $0 }
                .sink { [weak self] (cab, speed) in
                    guard let self = self,
                          let currentCab = Int(self.locomotiveAddress),
                          currentCab == cab else { return }

                    // Update UI with confirmed speed from station
                    self.currentSpeed = Double(speed) / 127.0
                    print("✅ Speed confirmed: \(speed)")
                }
                .store(in: &cancellables)

            // Subscribe to parsed direction updates from station
            concreteService.$receivedDirection
                .receive(on: DispatchQueue.main)
                .compactMap { $0 }
                .sink { [weak self] (cab, forward) in
                    guard let self = self,
                          let currentCab = Int(self.locomotiveAddress),
                          currentCab == cab else { return }

                    // Update UI with confirmed direction from station
                    self.currentDirectionIsForward = forward
                    print("✅ Direction confirmed: \(forward ? "Forward" : "Reverse")")
                }
                .store(in: &cancellables)

            // Subscribe to parsed function updates from station
            concreteService.$receivedFunction
                .receive(on: DispatchQueue.main)
                .compactMap { $0 }
                .sink { [weak self] (cab, fnNum, state) in
                    guard let self = self,
                          let currentCab = Int(self.locomotiveAddress),
                          currentCab == cab else { return }

                    print("✅ Function F\(fnNum) confirmed: \(state ? "ON" : "OFF")")
                    // Future: Update function button states here
                }
                .store(in: &cancellables)

            // Subscribe to programming track responses
            concreteService.$programmingResponse
                .receive(on: DispatchQueue.main)
                .sink { [weak self] response in
                    self?.programmingResponse = response
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Intents (User Actions)

    func scanForStations() {
        print("ViewModel: Starting station scan...")
        networkService.startDiscovery()
    }

    func refreshScan() {
        print("ViewModel: Refreshing station scan...")
        // Cast to concrete type to access the clearHistory parameter
        if let concreteService = networkService as? DCCEXNetworkService {
            concreteService.startDiscovery(clearHistory: true)
        } else {
            networkService.startDiscovery()
        }
    }

    func stopScanning() {
        print("ViewModel: Stopping station scan...")
        networkService.stopDiscovery()
    }

    // Select a locomotive from the roster
    func selectLocomotive(_ loco: Locomotive) {
        selectedLocomotive = loco
        locomotiveAddress = String(loco.address)
        currentSpeed = 0 // Reset speed when selecting new loco
        currentDirectionIsForward = true
        print("Selected locomotive: \(loco.name) (Address: \(loco.address))")
    }

    func connect(to station: DCCEXStation) {
        selectedStation = station
        networkService.connect(to: station)
    }

    func disconnect() {
        networkService.disconnect()
    }


    func setSpeed(_ speed: Double) {
        guard isConnected, let address = Int(locomotiveAddress) else {
            print("❌ Cannot set speed - not connected or invalid address: \(locomotiveAddress)")
            return
        }
        currentSpeed = speed

        // DCC-EX native command format: <t CAB SPEED DIRECTION>
        // CAB = DCC address (0-10239)
        // SPEED = 0-126 (0=stop, -1=emergency stop)
        // DIRECTION = 0 (reverse) or 1 (forward)
        let dccSpeed = Int(speed * 126) // Map 0.0-1.0 to 0-126
        let directionValue = currentDirectionIsForward ? 1 : 0
        let command = "<t \(address) \(dccSpeed) \(directionValue)>"
        print("🚂 Setting speed - Address: \(address), Speed: \(dccSpeed), Direction: \(directionValue), Command: \(command)")
        sendCommandWithLogging(command)
    }

    func setDirection(isForward: Bool) {
        guard isConnected, let address = Int(locomotiveAddress) else { return }
        currentDirectionIsForward = isForward

        // DCC-EX native command format: <t CAB SPEED DIRECTION>
        let dccSpeed = Int(currentSpeed * 126) // Send current speed with new direction
        let directionValue = isForward ? 1 : 0
        let command = "<t \(address) \(dccSpeed) \(directionValue)>"
        print("🔄 Setting direction - Address: \(address), Speed: \(dccSpeed), Direction: \(directionValue), Command: \(command)")
        sendCommandWithLogging(command)
    }
    
    func stopLocomotive() {
        guard isConnected, let address = Int(locomotiveAddress) else { return }
        currentSpeed = 0.0
        // DCC-EX command to stop current locomotive: set speed to 0
        let directionValue = currentDirectionIsForward ? 1 : 0
        let command = "<t \(address) 0 \(directionValue)>"
        print("⏹️ Stop locomotive - Address: \(address), Command: \(command)")
        sendCommandWithLogging(command)
    }

    func emergencyStop() {
        guard isConnected else { return }
        currentSpeed = 0.0
        // DCC-EX emergency stop ALL command
        let command = "<!>"
        print("🛑 Emergency stop ALL trains - Command: \(command)")
        sendCommandWithLogging(command)
    }

    // Send raw command to station (for emergency stop view and advanced features)
    func sendCommand(_ command: String) {
        sendCommandWithLogging(command)
    }

    // Send function command
    func setFunction(_ functionNum: Int, state: Bool) {
        guard isConnected, let address = Int(locomotiveAddress) else { return }

        // DCC-EX native command for functions: <f CAB BYTE1 [BYTE2]>
        // For simplicity, use simple format
        let command = "<F \(address) \(functionNum) \(state ? 1 : 0)>"
        sendCommandWithLogging(command)
    }

    // MARK: - Console Logging

    private func sendCommandWithLogging(_ command: String) {
        logMessage(command, direction: .sent)
        networkService.sendCommand(command)
    }

    private func logMessage(_ content: String, direction: ConsoleMessage.MessageDirection) {
        let message = ConsoleMessage(timestamp: Date(), direction: direction, content: content)
        consoleMessages.append(message)
        // Keep only last 500 messages to prevent memory issues
        if consoleMessages.count > 500 {
            consoleMessages.removeFirst(consoleMessages.count - 500)
        }
    }

    func clearConsole() {
        consoleMessages.removeAll()
    }
    
    func onLocomotiveAddressChanged() {
        // When the user changes the target locomotive address,
        // just log it. DCC-EX doesn't require explicit loco acquisition.
        // Commands will target the new address directly.
        if let address = Int(locomotiveAddress) {
            print("📍 Locomotive address changed to: \(address)")
        }
    }

    // MARK: - Track Management

    func toggleTrackPower(trackId: String) {
        guard isConnected else { return }

        if trackId == "A" {
            trackA.powerState = trackA.powerState == .on ? .off : .on
            let onOff = trackA.powerState == .on ? 1 : 0
            // Power command affects all tracks, so we use blank parameter
            let command = "<\(onOff)>"
            print("⚡ Track A power: \(trackA.powerState == .on ? "ON" : "OFF") - Command: \(command)")
            sendCommandWithLogging(command)
        } else if trackId == "B" {
            trackB.powerState = trackB.powerState == .on ? .off : .on
            let onOff = trackB.powerState == .on ? 1 : 0
            // Power command affects all tracks, so we use blank parameter
            let command = "<\(onOff)>"
            print("⚡ Track B power: \(trackB.powerState == .on ? "ON" : "OFF") - Command: \(command)")
            sendCommandWithLogging(command)
        }
    }

    func setTrackMode(trackId: String, mode: TrackMode) {
        guard isConnected else { return }

        if trackId == "A" {
            trackA.mode = mode
            let state = mode == .main ? "MAIN" : "PROG"
            let command = "<= A \(state)>"
            print("🔧 Track A mode: \(mode.rawValue) - Command: \(command)")
            sendCommandWithLogging(command)
        } else if trackId == "B" {
            trackB.mode = mode
            let state = mode == .main ? "MAIN" : "PROG"
            let command = "<= B \(state)>"
            print("🔧 Track B mode: \(mode.rawValue) - Command: \(command)")
            sendCommandWithLogging(command)
        }

        // Note: Mode changes should only happen when track is powered off
    }

    func powerOnAllTracks() {
        guard isConnected else { return }

        trackA.powerState = .on
        trackB.powerState = .on

        // DCC-EX command to power on both tracks: <1> (blank = both Main and Prog)
        let command = "<1>"
        print("⚡ Powering ON all tracks - Command: \(command)")
        sendCommandWithLogging(command)
    }

    func powerOffAllTracks() {
        guard isConnected else { return }

        trackA.powerState = .off
        trackB.powerState = .off

        // DCC-EX command to power off both tracks: <0> (blank = both Main and Prog)
        let command = "<0>"
        print("⚡ Powering OFF all tracks - Command: \(command)")
        sendCommandWithLogging(command)
    }

    deinit {
        // Clean up subscriptions
        cancellables.forEach { $0.cancel() }
        // Ensure discovery is stopped if ViewModel is deallocated
        networkService.stopDiscovery()
        if isConnected {
            networkService.disconnect()
        }
    }
}