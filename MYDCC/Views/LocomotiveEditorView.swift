//
//  LocomotiveEditorView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI
import PhotosUI

struct LocomotiveEditorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var roster: LocomotiveRoster

    var locomotive: Locomotive?

    @State private var name: String
    @State private var address: String
    @State private var maxSpeed: Int
    @State private var isFavorite: Bool
    @State private var notes: String
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false

    init(roster: LocomotiveRoster, locomotive: Locomotive? = nil) {
        self.roster = roster
        self.locomotive = locomotive

        _name = State(initialValue: locomotive?.name ?? "")
        _address = State(initialValue: String(locomotive?.address ?? 3))
        _maxSpeed = State(initialValue: locomotive?.maxSpeed ?? 128)
        _isFavorite = State(initialValue: locomotive?.isFavorite ?? false)
        _notes = State(initialValue: locomotive?.notes ?? "")

        if let imageName = locomotive?.imageName {
            _selectedImage = State(initialValue: LocomotiveEditorView.loadImage(named: imageName))
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDark.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 24) {
                        // Image picker
                        imageSection

                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(.textSecondary)

                            TextField("e.g., Big Boy 4014", text: $name)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.textPrimary)
                        }

                        // Address field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DCC Address")
                                .font(.headline)
                                .foregroundColor(.textSecondary)

                            TextField("e.g., 3", text: $address)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.textPrimary)
                        }

                        // Speed steps picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Speed Steps")
                                .font(.headline)
                                .foregroundColor(.textSecondary)

                            Picker("Speed Steps", selection: $maxSpeed) {
                                Text("28").tag(28)
                                Text("128").tag(128)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }

                        // Favorite toggle
                        Toggle("Favorite", isOn: $isFavorite)
                            .foregroundColor(.textPrimary)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)

                        // Notes field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .foregroundColor(.textSecondary)

                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.textPrimary)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(locomotive == nil ? "Add Locomotive" : "Edit Locomotive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLoco()
                    }
                    .foregroundColor(.accentBlue)
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || address.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    private var imageSection: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.borderDark, lineWidth: 1)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 200, height: 150)

                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.textSecondary)
                        Text("Add Photo")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    showingImagePicker = true
                } label: {
                    Label(selectedImage == nil ? "Add Photo" : "Change Photo", systemImage: "photo")
                        .font(.subheadline)
                        .foregroundColor(.accentBlue)
                }

                if selectedImage != nil {
                    Button {
                        selectedImage = nil
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.subheadline)
                            .foregroundColor(.dangerRed)
                    }
                }
            }
        }
    }

    private func saveLoco() {
        guard let addr = Int(address), !name.isEmpty else { return }

        var imageName: String?

        // Save image if one was selected
        if let image = selectedImage {
            imageName = "\(UUID().uuidString).jpg"
            saveImage(image, withName: imageName!)
        } else if let existingImageName = locomotive?.imageName {
            imageName = existingImageName
        }

        let newLoco = Locomotive(
            id: locomotive?.id ?? UUID(),
            name: name,
            address: addr,
            imageName: imageName,
            notes: notes,
            maxSpeed: maxSpeed,
            isFavorite: isFavorite,
            lastUsed: locomotive?.lastUsed ?? Date()
        )

        if locomotive == nil {
            roster.addLocomotive(newLoco)
        } else {
            roster.updateLocomotive(newLoco)
        }

        dismiss()
    }

    private func saveImage(_ image: UIImage, withName name: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(name),
           let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: filePath)
        }
    }

    private static func loadImage(named: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(named),
           let imageData = try? Data(contentsOf: filePath) {
            return UIImage(data: imageData)
        }
        return nil
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct LocomotiveEditorView_Previews: PreviewProvider {
    static var previews: some View {
        LocomotiveEditorView(roster: LocomotiveRoster())
    }
}
