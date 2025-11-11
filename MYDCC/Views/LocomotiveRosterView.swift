//
//  LocomotiveRosterView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

struct LocomotiveRosterView: View {
    @EnvironmentObject var viewModel: ThrottleViewModel
    @StateObject var roster = LocomotiveRoster()
    @State private var showingAddLoco = false
    @State private var selectedLoco: Locomotive?
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDark.edgesIgnoringSafeArea(.all)

                if roster.locomotives.isEmpty {
                    emptyStateView
                } else {
                    if DeviceType.isiPad {
                        iPadRosterView
                    } else {
                        iPhoneRosterView
                    }
                }
            }
            .navigationTitle("My Locomotives")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !roster.locomotives.isEmpty {
                        Button(editMode == .inactive ? "Edit" : "Done") {
                            withAnimation {
                                editMode = editMode == .inactive ? .active : .inactive
                            }
                        }
                        .foregroundColor(.accentBlue)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddLoco = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentBlue)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddLoco) {
                LocomotiveEditorView(roster: roster)
            }
            .sheet(item: $selectedLoco) { loco in
                LocomotiveEditorView(roster: roster, locomotive: loco)
            }
        }
    }

    // MARK: - iPad Roster View (Grid Layout)
    private var iPadRosterView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 20)
                ],
                spacing: 20
            ) {
                ForEach(roster.locomotives) { loco in
                    LocomotiveCard(locomotive: loco) {
                        viewModel.selectLocomotive(loco)
                        roster.markAsUsed(loco)
                    }
                    .contextMenu {
                        Button {
                            selectedLoco = loco
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            withAnimation {
                                roster.deleteLocomotive(loco)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    // MARK: - iPhone Roster View (List Layout)
    private var iPhoneRosterView: some View {
        List {
            ForEach(roster.locomotives) { loco in
                LocomotiveCard(locomotive: loco) {
                    viewModel.selectLocomotive(loco)
                    roster.markAsUsed(loco)
                }
                .listRowBackground(Color.backgroundDark)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation {
                            roster.deleteLocomotive(loco)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        selectedLoco = loco
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.accentBlue)
                }
            }
            .onDelete { indexSet in
                roster.deleteLocomotives(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .environment(\.editMode, $editMode)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "train.side.front.car")
                .font(.system(size: 80))
                .foregroundColor(.textSecondary)

            Text("No Locomotives")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("Tap + to add your first locomotive")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Button {
                showingAddLoco = true
            } label: {
                Label("Add Locomotive", systemImage: "plus.circle.fill")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentBlue)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
    }
}

// MARK: - Locomotive Card
struct LocomotiveCard: View {
    let locomotive: Locomotive
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Locomotive image or placeholder
                if let imageName = locomotive.imageName,
                   let uiImage = loadImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "train.side.front.car")
                            .font(.title)
                            .foregroundColor(.textSecondary)
                    }
                }

                // Locomotive info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(locomotive.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        if locomotive.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.cautionYellow)
                        }
                    }

                    HStack(spacing: 12) {
                        Label("\(locomotive.address)", systemImage: "number")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)

                        Label("\(locomotive.maxSpeed) steps", systemImage: "speedometer")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }

                    Text(relativeDateString(from: locomotive.lastUsed))
                        .font(.caption)
                        .foregroundColor(.textSecondary.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(Color.cardDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDark, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func loadImage(named: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(named),
           let imageData = try? Data(contentsOf: filePath) {
            return UIImage(data: imageData)
        }
        return nil
    }

    private func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Used " + formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct LocomotiveRosterView_Previews: PreviewProvider {
    static var previews: some View {
        LocomotiveRosterView()
            .environmentObject(ThrottleViewModel())
    }
}
