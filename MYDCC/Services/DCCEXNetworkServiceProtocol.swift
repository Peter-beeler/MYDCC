//
//  DCCEXNetworkServiceProtocol.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//


import Foundation
import Network // For NWConnection (TCP) and NWBrowser (Bonjour-like discovery)

// Protocol defining the expected behavior of the network service.
// This helps in mocking for tests.
protocol DCCEXNetworkServiceProtocol {
    var discoveredStationsPublisher: Published<[DCCEXStation]>.Publisher { get }
    var connectionStatusPublisher: Published<Bool>.Publisher { get }
    var lastReceivedMessagePublisher: Published<String?>.Publisher { get }

    func startDiscovery()
    func stopDiscovery()
    func connect(to station: DCCEXStation)
    func disconnect()
    func sendCommand(_ command: String)
}

class DCCEXNetworkService: NSObject, ObservableObject, DCCEXNetworkServiceProtocol {
    // Published properties to update the ViewModel/UI
    @Published private(set) var discoveredStations: [DCCEXStation] = []
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var lastReceivedMessage: String? = nil

    // Published WiThrottle messages for real-time updates
    @Published private(set) var receivedSpeed: (cab: Int, speed: Int)? = nil
    @Published private(set) var receivedDirection: (cab: Int, forward: Bool)? = nil
    @Published private(set) var receivedFunction: (cab: Int, function: Int, state: Bool)? = nil

    // Programming track responses
    @Published private(set) var programmingResponse: ProgrammingResponse? = nil

    // Publishers for protocol conformance
    var discoveredStationsPublisher: Published<[DCCEXStation]>.Publisher { $discoveredStations }
    var connectionStatusPublisher: Published<Bool>.Publisher { $isConnected }
    var lastReceivedMessagePublisher: Published<String?>.Publisher { $lastReceivedMessage }

    // Bonjour/Network Framework components for discovery
    private var browser: NWBrowser?
    // TCP Connection
    private var connection: NWConnection?
    private let dccExPort = NWEndpoint.Port(integerLiteral: 2560) // Standard DCC-EX port for WiThrottle
    private let serviceType = "_withrottle._tcp" // Standard WiThrottle Bonjour service type
    private var connectedStationName: String? // Track which station we're connected to

    // Dictionary to track all stations we've seen (key: station name)
    private var allStations: [String: DCCEXStation] = [:]

    // Timer for active health checking
    private var healthCheckTimer: Timer?

    override init() {
        super.init()
    }

    // MARK: - Discovery
    func startDiscovery() {
        startDiscovery(clearHistory: false)
    }

    func startDiscovery(clearHistory: Bool) {
        // If already browsing, stop first to get a fresh scan
        if browser != nil {
            print("Restarting discovery for fresh scan...")
            stopDiscovery(clearList: clearHistory)
        }

        let parameters = NWParameters() // Use default parameters for TCP over Wi-Fi/Ethernet
        parameters.includePeerToPeer = true // Important for local network discovery

        // Create a browser to find services of a specific type on the local network
        browser = NWBrowser(for: .bonjour(type: serviceType, domain: "local."), using: parameters)
        
        browser?.stateUpdateHandler = { newState in
            print("Browser new state: \(newState)")
            // Handle browser state changes (e.g., failed, ready)
        }

        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            guard let self = self else { return }

            // Process changes to update station status
            for change in changes {
                switch change {
                case .added(let result):
                    if case let .service(name, _, domain, _) = result.endpoint {
                        print("Service added: \(name)")
                        // Add or update the station as online
                        let hostName = "\(name).\(domain)"

                        var station = self.allStations[name] ?? DCCEXStation(
                            name: name,
                            hostName: hostName,
                            ipAddress: "Resolving...",
                            port: Int(self.dccExPort.rawValue),
                            isOnline: true
                        )
                        station.isOnline = true
                        self.allStations[name] = station

                        // Try to resolve IP address
                        self.resolveIPAddress(for: hostName, stationName: name)
                    }
                case .removed(let result):
                    if case let .service(name, _, _, _) = result.endpoint {
                        print("Service removed: \(name)")
                        // Mark station as offline instead of removing it
                        if var station = self.allStations[name] {
                            station.isOnline = false
                            self.allStations[name] = station
                        }

                        // If the removed service is the one we're connected to, disconnect
                        if let connectedName = self.connectedStationName, connectedName == name {
                            print("Connected station went offline, disconnecting...")
                            self.disconnect()
                        }
                    }
                case .changed(_, let new, let flags):
                    if case let .service(name, _, _, _) = new.endpoint {
                        print("Service changed: \(name), flags: \(flags)")
                    }
                case .identical:
                    break
                @unknown default:
                    break
                }
            }

            // Also sync with current results to catch any we might have missed
            var currentOnlineNames = Set<String>()
            for result in results {
                if case let .service(name, _, domain, _) = result.endpoint {
                    currentOnlineNames.insert(name)

                    // Ensure this station exists and is marked online
                    let hostName = "\(name).\(domain)"

                    var station = self.allStations[name] ?? DCCEXStation(
                        name: name,
                        hostName: hostName,
                        ipAddress: "Resolving...",
                        port: Int(self.dccExPort.rawValue),
                        isOnline: true
                    )
                    station.isOnline = true
                    self.allStations[name] = station

                    // Try to resolve IP address if not already resolved
                    if station.ipAddress == "Resolving..." {
                        self.resolveIPAddress(for: hostName, stationName: name)
                    }
                }
            }

            // Mark any stations not in current results as offline
            for (name, var station) in self.allStations {
                if !currentOnlineNames.contains(name) && station.isOnline {
                    station.isOnline = false
                    self.allStations[name] = station
                }
            }

            // Update on the main thread as this will trigger UI changes
            DispatchQueue.main.async {
                self.updateDiscoveredStations()
                print("Discovered stations updated: \(self.discoveredStations.map { "\($0.name) (\($0.isOnline ? "online" : "offline"))" })")
            }
        }
        browser?.start(queue: .main) // Use a dedicated queue in a real app
        print("Started Bonjour discovery for \(serviceType)")

        // Start health check timer to actively verify station availability
        startHealthCheckTimer()
    }

    private func startHealthCheckTimer() {
        // Cancel existing timer if any
        healthCheckTimer?.invalidate()

        // Check station health every 5 seconds
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
    }

    private func performHealthCheck() {
        // Check each station that claims to be online
        for (name, station) in allStations where station.isOnline {
            // Quick connectivity check using NWConnection
            let host = NWEndpoint.Host(station.hostName)
            guard let port = NWEndpoint.Port(rawValue: UInt16(station.port)) else { continue }

            let connection = NWConnection(host: host, port: port, using: .tcp)
            let checkStartTime = Date()

            connection.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }

                switch state {
                case .ready:
                    // Station is online and reachable
                    connection.cancel()
                case .failed(_), .waiting(_):
                    // Station is not reachable - mark as offline
                    let elapsed = Date().timeIntervalSince(checkStartTime)
                    if elapsed > 2.0 { // If it takes more than 2 seconds, consider it offline
                        DispatchQueue.main.async {
                            if var currentStation = self.allStations[name], currentStation.isOnline {
                                currentStation.isOnline = false
                                self.allStations[name] = currentStation
                                self.updateDiscoveredStations()
                                print("Health check: \(name) marked offline")
                            }
                        }
                    }
                    connection.cancel()
                default:
                    break
                }
            }

            connection.start(queue: .global(qos: .utility))

            // Also set a timeout
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0) {
                if connection.state != .ready && connection.state != .cancelled {
                    connection.cancel()
                    // Mark as offline if not ready within timeout
                    DispatchQueue.main.async {
                        if var currentStation = self.allStations[name], currentStation.isOnline {
                            currentStation.isOnline = false
                            self.allStations[name] = currentStation
                            self.updateDiscoveredStations()
                            print("Health check timeout: \(name) marked offline")
                        }
                    }
                }
            }
        }
    }

    private func updateDiscoveredStations() {
        // Convert dictionary to sorted array (online stations first, then by name)
        discoveredStations = Array(allStations.values).sorted { station1, station2 in
            if station1.isOnline != station2.isOnline {
                return station1.isOnline // Online stations first
            }
            return station1.name < station2.name
        }
    }

    private func resolveIPAddress(for hostName: String, stationName: String) {
        // Use NWConnection to resolve the IP address
        let host = NWEndpoint.Host(hostName)
        let port = dccExPort

        let connection = NWConnection(host: host, port: port, using: .tcp)

        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .ready:
                // Try to get the remote endpoint which may have the IP
                if let path = connection.currentPath,
                   let remoteEndpoint = path.remoteEndpoint {
                    var ipAddress = "Unknown"

                    // Extract IP from the endpoint
                    switch remoteEndpoint {
                    case .hostPort(let host, _):
                        // Convert host to string
                        ipAddress = "\(host)"
                    default:
                        break
                    }

                    // Update the station with resolved IP
                    DispatchQueue.main.async {
                        if var station = self.allStations[stationName] {
                            station.ipAddress = ipAddress
                            self.allStations[stationName] = station
                            self.updateDiscoveredStations()
                            print("Resolved IP for \(stationName): \(ipAddress)")
                        }
                    }
                }
                connection.cancel()
            case .failed(_), .waiting(_):
                connection.cancel()
            default:
                break
            }
        }

        connection.start(queue: .global(qos: .utility))

        // Timeout after 3 seconds
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3.0) {
            connection.cancel()
        }
    }

    func stopDiscovery() {
        stopDiscovery(clearList: true)
    }

    private func stopDiscovery(clearList: Bool) {
        browser?.cancel()
        browser = nil

        // Stop health check timer
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil

        if clearList {
            DispatchQueue.main.async {
                self.discoveredStations = []
            }
            allStations.removeAll() // Also clear the stations dictionary
        }
        print("Stopped Bonjour discovery")
    }

    // MARK: - Connection
    func connect(to station: DCCEXStation) {
        guard let port = NWEndpoint.Port(rawValue: UInt16(station.port)) else {
            print("Invalid port for station: \(station.name)")
            return
        }
        let host = NWEndpoint.Host(station.hostName) // Use hostname for connection

        // Track the connected station name
        connectedStationName = station.name

        connection = NWConnection(host: host, port: port, using: .tcp)

        connection?.stateUpdateHandler = { [weak self] newState in
            DispatchQueue.main.async {
                switch newState {
                case .ready:
                    self?.isConnected = true
                    print("Connected to \(station.name) at \(station.hostName):\(station.port)")
                    self?.receive() // Start listening for incoming data
                    // Optionally send an initial command, like requesting version
                    // self?.sendCommand("<V>")
                case .failed(let error):
                    print("Connection failed: \(error.localizedDescription)")
                    self?.isConnected = false
                    self?.connection = nil
                    self?.connectedStationName = nil
                case .cancelled:
                    print("Connection cancelled.")
                    self?.isConnected = false
                    self?.connection = nil
                    self?.connectedStationName = nil
                case .waiting(let error):
                    print("Connection waiting: \(error.localizedDescription)")
                    // This can happen if the host is not reachable
                    self?.isConnected = false
                default:
                    break
                }
            }
        }
        connection?.start(queue: .global(qos: .background)) // Use a background queue for network operations
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        connectedStationName = nil
        DispatchQueue.main.async {
            self.isConnected = false
        }
        print("Disconnected.")
    }

    // MARK: - Communication
    func sendCommand(_ command: String) {
        guard isConnected, let connection = connection else {
            print("Not connected, cannot send command: \(command)")
            return
        }
        
        // DCC-EX commands often need a newline character
        let commandData = (command + "\n").data(using: .utf8)
        
        connection.send(content: commandData, completion: .contentProcessed({ error in
            if let error = error {
                print("Error sending command \(command): \(error.localizedDescription)")
                // Optionally handle re-try or disconnect
            } else {
                print("Sent command: \(command)")
            }
        }))
    }

    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                if let message = String(data: data, encoding: .utf8) {
                    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)

                    // Update last received message
                    DispatchQueue.main.async {
                        self?.lastReceivedMessage = trimmed
                    }

                    // Parse WiThrottle messages
                    self?.parseReceivedMessage(trimmed)
                }
            }
            if let error = error {
                print("Receive error: \(error.localizedDescription)")
                // Handle error, possibly disconnect
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                return
            }
            if isComplete {
                print("Connection closed by peer.")
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                return
            }
            // If not an error and not complete, continue receiving
            if self?.isConnected == true {
                 self?.receive()
            }
        }
    }

    private func parseReceivedMessage(_ message: String) {
        // Messages may contain multiple lines
        let lines = message.components(separatedBy: .newlines)

        for line in lines {
            guard !line.isEmpty else { continue }

            // First try to parse DCC-EX native protocol responses
            if parseDCCEXResponse(line) {
                // Successfully parsed as DCC-EX response
                continue
            }

            // Parse using WiThrottleParser
            if let parsed = WiThrottleParser.parse(line) {
                print("Parsed: \(parsed)")

                // Update published properties based on message type
                DispatchQueue.main.async { [weak self] in
                    switch parsed {
                    case .speed(_, let cab, let speed):
                        self?.receivedSpeed = (cab, speed)
                        print("📊 Speed Update: Cab \(cab) → \(speed)")

                    case .direction(_, let cab, let forward):
                        self?.receivedDirection = (cab, forward)
                        print("🔄 Direction Update: Cab \(cab) → \(forward ? "Forward" : "Reverse")")

                    case .function(_, let cab, let fnNum, let state):
                        self?.receivedFunction = (cab, fnNum, state)
                        print("⚡️ Function Update: Cab \(cab) F\(fnNum) → \(state ? "ON" : "OFF")")

                    case .heartbeat:
                        print("💓 Heartbeat")

                    case .unknown(let msg):
                        print("❓ Unknown message: \(msg)")
                    }
                }
            }
        }
    }

    /// Parse DCC-EX native protocol responses
    /// Returns true if the message was parsed successfully
    private func parseDCCEXResponse(_ message: String) -> Bool {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)

        // DCC-EX responses are in format <X ...>
        guard trimmed.hasPrefix("<") && trimmed.hasSuffix(">") else {
            return false
        }

        // Remove the < and > brackets
        let content = trimmed.dropFirst().dropLast()
        let parts = content.split(separator: " ", omittingEmptySubsequences: true)

        guard let firstPart = parts.first else {
            return false
        }

        let command = String(firstPart).lowercased()

        switch command {
        case "r":
            // Read response: <r CV|CALLBACKNUM|CALLBACKSUB VALUE>
            // For read loco address: <r ADDRESS>
            if parts.count >= 2, let value = Int(parts[1]) {
                DispatchQueue.main.async { [weak self] in
                    self?.programmingResponse = ProgrammingResponse(type: "read_address", value: value)
                    print("📖 Programming: Read Address → \(value)")
                }
                return true
            }

        case "r1", "r2", "r3":
            // Read CV response with callback: <rX|CV VALUE>
            if parts.count >= 2, let value = Int(parts[1]) {
                DispatchQueue.main.async { [weak self] in
                    self?.programmingResponse = ProgrammingResponse(type: "read_cv", value: value)
                    print("📖 Programming: Read CV → \(value)")
                }
                return true
            }

        case "w":
            // Write response: <w VALUE>
            if parts.count >= 2, let value = Int(parts[1]) {
                DispatchQueue.main.async { [weak self] in
                    self?.programmingResponse = ProgrammingResponse(type: "write_address", value: value)
                    print("✏️ Programming: Write Address → \(value)")
                }
                return true
            }

        case "w1", "w2", "w3":
            // Write CV response with callback
            if parts.count >= 2, let value = Int(parts[1]) {
                DispatchQueue.main.async { [weak self] in
                    self?.programmingResponse = ProgrammingResponse(type: "write_cv", value: value)
                    print("✏️ Programming: Write CV → \(value)")
                }
                return true
            }

        case "v":
            // Verify response: <v CV VALUE>
            if parts.count >= 3, let value = Int(parts[2]) {
                DispatchQueue.main.async { [weak self] in
                    self?.programmingResponse = ProgrammingResponse(type: "verify_cv", value: value)
                    print("✅ Programming: Verify CV → \(value)")
                }
                return true
            }

        default:
            // Check if it's a generic programming response with just a number
            if command.first?.isNumber == true, let value = Int(command) {
                // This might be a simple read response like <235>
                DispatchQueue.main.async { [weak self] in
                    self?.programmingResponse = ProgrammingResponse(type: "read_value", value: value)
                    print("📖 Programming: Read Value → \(value)")
                }
                return true
            }
        }

        return false
    }
}
