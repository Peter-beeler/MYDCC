//
//  ConsoleView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

struct ConsoleView: View {
    @EnvironmentObject var viewModel: ThrottleViewModel
    @State private var autoScroll = true
    @State private var commandText = ""
    @FocusState private var isCommandFieldFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Console output
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: DeviceType.isiPad ? 8 : 4) {
                                ForEach(Array(viewModel.consoleMessages.enumerated()), id: \.offset) { index, message in
                                    ConsoleMessageRow(message: message)
                                        .id(index)
                                }
                            }
                            .adaptivePadding()
                        }
                        .onChange(of: viewModel.consoleMessages.count) { _, _ in
                            if autoScroll, let lastIndex = viewModel.consoleMessages.indices.last {
                                withAnimation {
                                    proxy.scrollTo(lastIndex, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Command input section
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.borderDark)

                        HStack(spacing: 12) {
                            // Command text field
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)

                                TextField("Enter DCC command (e.g., <t 3 50 1>)", text: $commandText)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.textPrimary)
                                    .focused($isCommandFieldFocused)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onSubmit {
                                        sendCommand()
                                    }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)

                            // Send button
                            Button {
                                sendCommand()
                            } label: {
                                Image(systemName: "paperplane.fill")
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(commandText.isEmpty ? Color.gray : Color.accentBlue)
                                    .cornerRadius(10)
                            }
                            .disabled(commandText.isEmpty || !viewModel.isConnected)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        Divider()
                            .background(Color.borderDark)

                        // Bottom toolbar
                        HStack(spacing: 16) {
                            Toggle("Auto-scroll", isOn: $autoScroll)
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Spacer()

                            // Connection status
                            if !viewModel.isConnected {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.dangerRed)
                                        .frame(width: 6, height: 6)
                                    Text("Not Connected")
                                        .font(.caption)
                                        .foregroundColor(.dangerRed)
                                }
                            }

                            Button {
                                viewModel.clearConsole()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text("Clear")
                                }
                                .font(.caption)
                                .foregroundColor(.dangerRed)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color.cardDark)
                }
            }
            .navigationTitle("Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            commandText = "<s>"
                        } label: {
                            Label("Status <s>", systemImage: "info.circle")
                        }

                        Button {
                            commandText = "<1>"
                        } label: {
                            Label("Power ON <1>", systemImage: "power")
                        }

                        Button {
                            commandText = "<0>"
                        } label: {
                            Label("Power OFF <0>", systemImage: "poweroff")
                        }

                        Button {
                            commandText = "<!>"
                        } label: {
                            Label("Emergency Stop <!>", systemImage: "exclamationmark.triangle")
                        }

                        Divider()

                        Button {
                            commandText = "<t 3 0 1>"
                        } label: {
                            Label("Stop Loco 3", systemImage: "stop.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.accentBlue)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Helper Functions

    private func sendCommand() {
        guard !commandText.isEmpty, viewModel.isConnected else { return }

        // Send the command to the DCC station
        viewModel.sendCommand(commandText)

        // Clear the text field
        commandText = ""

        // Dismiss keyboard
        isCommandFieldFocused = false
    }
}

// MARK: - Console Message Row
struct ConsoleMessageRow: View {
    let message: ConsoleMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(timeString(from: message.timestamp))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.textSecondary)
                .frame(width: 60, alignment: .leading)

            // Direction indicator
            Image(systemName: message.direction == .sent ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.caption)
                .foregroundColor(message.direction == .sent ? .accentBlue : .successGreen)

            // Message content
            Text(message.content)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.textPrimary)
                .textSelection(.enabled)

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(message.direction == .sent ? Color.accentBlue.opacity(0.05) : Color.successGreen.opacity(0.05))
        .cornerRadius(6)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Console Message Model
struct ConsoleMessage: Identifiable {
    let id = UUID()
    let timestamp: Date
    let direction: MessageDirection
    let content: String

    enum MessageDirection {
        case sent
        case received
    }
}

// MARK: - Preview
struct ConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = ThrottleViewModel(networkService: MockDCCEXNetworkService())
        mockViewModel.consoleMessages = [
            ConsoleMessage(timestamp: Date(), direction: .sent, content: "<t 3 50 1>"),
            ConsoleMessage(timestamp: Date(), direction: .received, content: "<T 1 50 1>"),
            ConsoleMessage(timestamp: Date(), direction: .sent, content: "<F 3 0 1>"),
            ConsoleMessage(timestamp: Date(), direction: .received, content: "<l 3 0 128 1>")
        ]

        return ConsoleView()
            .environmentObject(mockViewModel)
    }
}
