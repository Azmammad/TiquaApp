//
//  CreateView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 14.02.26.
//
import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreatePostViewModel()

    @State private var selectedItem: PhotosPickerItem?
    @State private var previewImage: Image?
    @State private var showErrorAlert = false

    var locationName: String? = nil
    var locationSubtitle: String? = nil
    var isLocationVerified: Bool = false
    var latitude: Double? = nil
    var longitude: Double? = nil

    private let captionCharacterLimit = 500

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if locationName != nil {
                        locationSection
                    }

                    photoSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    captionSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    infoSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    Spacer(minLength: 40)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .disabled(viewModel.isLoading)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.createPost(
                                locationName: locationName,
                                latitude: latitude,
                                longitude: longitude
                            )
                        }
                    } label: {
                        Text("Post")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(postButtonDisabled ? .secondary : .accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                postButtonDisabled
                                    ? Color(.systemGray5)
                                    : Color.accentColor.opacity(0.12)
                            )
                            .cornerRadius(20)
                    }
                    .disabled(postButtonDisabled)
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                if let newValue {
                    Task { await loadPhoto(from: newValue) }
                }
            }
            .onChange(of: viewModel.didCreateSuccessfully) { _, newValue in
                if newValue { dismiss() }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .allowsHitTesting(!viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.3)
                                .tint(.accentColor)
                        )
                }
            }
        }
    }

    private var postButtonDisabled: Bool {
        viewModel.selectedImageData == nil || viewModel.isLoading
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(locationName ?? "")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        if isLocationVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.accentColor)
                        }
                    }

                    if let subtitle = locationSubtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            if isLocationVerified {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentColor)

                    Text("Location verified - You're currently at this place")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            } else {
                Spacer()
                    .frame(height: 14)
            }
        }
        .background(Color.accentColor.opacity(0.06))
    }

    private var photoSection: some View {
        VStack(spacing: 12) {
            if previewImage != nil {
                ZStack(alignment: .topTrailing) {
                    photoContainer

                    Button {
                        previewImage = nil
                        viewModel.selectedImageData = nil
                        selectedItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .padding(12)
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Change Photo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    photoContainer
                }
            }
        }
    }

    private var photoContainer: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6).opacity(0.5))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    if let previewImage = previewImage {
                        previewImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholderContent
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                Group {
                    if previewImage == nil {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                            )
                            .foregroundColor(Color(.systemGray4))
                    }
                }
            )
    }

    private var placeholderContent: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 72, height: 72)

                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
            }

            Text("Add Photo")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            Text("Tap to select from gallery")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            ZStack(alignment: .topLeading) {
                if viewModel.caption.isEmpty {
                    Text("Share your experience at this place...")
                        .font(.system(size: 16))
                        .foregroundColor(Color(.systemGray3))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $viewModel.caption)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .frame(minHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .onChange(of: viewModel.caption) { _, newValue in
                        if newValue.count > captionCharacterLimit {
                            viewModel.caption = String(newValue.prefix(captionCharacterLimit))
                        }
                    }
            }
        }
    }

    private var infoSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange.opacity(0.8))

            Text("You can only post when you're physically at the location")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.6))
        .cornerRadius(12)
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            viewModel.errorMessage = "Failed to load image"
            return
        }

        viewModel.selectedImageData = data
        previewImage = Image(data: data)
    }
}

private extension Image {
    init?(data: Data) {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        self.init(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        self.init(nsImage: nsImage)
        #else
        return nil
        #endif
    }
}
