//
//  AdaptiveMainView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

/// Navigation destination enum for routing
enum NavigationDestination: Hashable, Identifiable {
    case roster
    case throttle
    case programming
    case console
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .roster: return "Roster"
        case .throttle: return "Throttle"
        case .programming: return "Programming"
        case .console: return "Console"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .roster: return "train.side.front.car"
        case .throttle: return "speedometer"
        case .programming: return "wrench.and.screwdriver.fill"
        case .console: return "terminal"
        case .settings: return "gear"
        }
    }
}

/// Adaptive main view that uses NavigationSplitView on iPad and TabView on iPhone
struct AdaptiveMainView: View {
    @EnvironmentObject var viewModel: ThrottleViewModel
    @State private var selectedDestination: NavigationDestination = .roster
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    // Check if either track is in program mode
    private var isProgrammingAvailable: Bool {
        viewModel.trackA.mode == .program || viewModel.trackB.mode == .program
    }

    // Available destinations based on programming mode
    private var availableDestinations: [NavigationDestination] {
        var destinations: [NavigationDestination] = [.roster, .throttle]
        if isProgrammingAvailable {
            destinations.append(.programming)
        }
        destinations.append(contentsOf: [.console, .settings])
        return destinations
    }

    var body: some View {
        if DeviceType.isiPad {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPad Layout (Split View)
    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List {
                ForEach(availableDestinations) { destination in
                    Button {
                        selectedDestination = destination
                    } label: {
                        HStack {
                            Label(destination.title, systemImage: destination.icon)
                                .font(.headline)
                            Spacer()
                            if selectedDestination == destination {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentBlue)
                            }
                        }
                    }
                    .listRowBackground(
                        selectedDestination == destination ? Color.accentBlue.opacity(0.1) : Color.clear
                    )
                }
            }
            .navigationTitle("MY DCC")
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.sidebar)
        } detail: {
            // Detail view
            destinationView(for: selectedDestination)
                .onChange(of: viewModel.selectedLocomotive) { _, newValue in
                    // Auto-switch to throttle when locomotive is selected
                    if newValue != nil && selectedDestination == .roster {
                        selectedDestination = .throttle
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - iPhone Layout (Tabs)
    private var iPhoneLayout: some View {
        TabView(selection: $selectedDestination) {
            ForEach(availableDestinations) { destination in
                destinationView(for: destination)
                    .tabItem {
                        Label(destination.title, systemImage: destination.icon)
                    }
                    .tag(destination)
            }
        }
        .accentColor(.accentBlue)
        .onChange(of: viewModel.selectedLocomotive) { _, newValue in
            // Auto-switch to throttle tab when locomotive is selected
            if newValue != nil && selectedDestination == .roster {
                selectedDestination = .throttle
            }
        }
    }

    // MARK: - Destination View Builder
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .roster:
            LocomotiveRosterView()
        case .throttle:
            ContentView()
        case .programming:
            ProgrammingView()
        case .console:
            ConsoleView()
        case .settings:
            SettingsView()
        }
    }
}

struct AdaptiveMainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone Preview
            AdaptiveMainView()
                .environmentObject(ThrottleViewModel())
                .previewDevice("iPhone 16 Pro")
                .previewDisplayName("iPhone")

            // iPad Preview
            AdaptiveMainView()
                .environmentObject(ThrottleViewModel())
                .previewDevice("iPad Pro 13-inch (M5)")
                .previewDisplayName("iPad")
        }
    }
}
