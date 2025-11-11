//
//  MainTabView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var viewModel: ThrottleViewModel
    @State private var selectedTab = 0

    // Check if either track is in program mode
    private var isProgrammingAvailable: Bool {
        viewModel.trackA.mode == .program || viewModel.trackB.mode == .program
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Locomotive Roster Tab
            LocomotiveRosterView()
                .tabItem {
                    Label("Roster", systemImage: "train.side.front.car")
                }
                .tag(0)

            // Throttle Control Tab
            ContentView()
                .tabItem {
                    Label("Throttle", systemImage: "speedometer")
                }
                .tag(1)

            // Programming Tab - only show when track is in program mode
            if isProgrammingAvailable {
                ProgrammingView()
                    .tabItem {
                        Label("Program", systemImage: "wrench.and.screwdriver.fill")
                    }
                    .tag(2)
            }

            // Console Tab
            ConsoleView()
                .tabItem {
                    Label("Console", systemImage: "terminal")
                }
                .tag(isProgrammingAvailable ? 3 : 2)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(isProgrammingAvailable ? 4 : 3)
        }
        .accentColor(.accentBlue)
        .onChange(of: viewModel.selectedLocomotive) { _, newValue in
            // Auto-switch to throttle tab when locomotive is selected
            if newValue != nil && selectedTab == 0 {
                selectedTab = 1
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(ThrottleViewModel())
    }
}
