//
//  CreateView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 14.02.26.
//
import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()

    @State private var selectedItem: PhotosPickerItem?
    @State private var previewImage: Image?
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false

    private let captionCharacterLimit = 500

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let locationH: CGFloat = 70
                let infoH: CGFloat = 48
                let spacing: CGFloat = 12
                let captionH: CGFloat = max(80, geo.size.height * 0.14)
                let photoH = geo.size.height - locationH - captionH - infoH - spacing * 4

                VStack(spacing: spacing) {
                    locationSection
                        .frame(height: locationH)

                    photoSection(height: photoH)
                        .padding(.horizontal, 20)

                    captionSection(height: captionH)
                        .padding(.horizontal, 20)

                    infoSection
                        .frame(height: infoH)
                        .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.createPost() }
                    } label: {
                        Text("Post")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(viewModel.postButtonDisabled ? .secondary : .accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.postButtonDisabled
                                    ? Color(.systemGray5)
                                    : Color.accentColor.opacity(0.12)
                            )
                            .cornerRadius(20)
                    }
                    .disabled(viewModel.postButtonDisabled)
                }
            }
            .onAppear {
                viewModel.requestLocation()
            }
            .onChange(of: selectedItem) { _, newValue in
                if let newValue {
                    Task { await loadPhoto(from: newValue) }
                }
            }
            .onChange(of: viewModel.didCreateSuccessfully) { _, newValue in
                if newValue {
                    showSuccessAlert = true
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    resetAll()
                }
            } message: {
                Text("Your post has been shared!")
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

    private func resetAll() {
        previewImage = nil
        selectedItem = nil
        viewModel.reset()
    }

    @ViewBuilder
    private var locationSection: some View {
        if viewModel.locationManager.isLoading {
            locationLoadingView
        } else if viewModel.isLocationAvailable {
            locationVerifiedView
        } else if viewModel.locationManager.isDenied {
            locationDeniedView
        } else {
            locationRequestView
        }
    }

    private var locationLoadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.accentColor)
            Text("Getting your location...")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6).opacity(0.5))
    }

    private var locationVerifiedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(viewModel.locationName ?? "")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                    }
                    if let subtitle = viewModel.locationSubtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.accentColor)
                Text("Location verified \u{2013} You're currently at this place")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.06))
    }

    private var locationDeniedView: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 18))
                .foregroundColor(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text("Location Access Denied")
                    .font(.system(size: 14, weight: .semibold))
                Text("Enable in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .background(Color.red.opacity(0.05))
    }

    private var locationRequestView: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.circle")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            Text("Requesting location access...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Button {
                viewModel.requestLocation()
            } label: {
                Text("Retry")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .background(Color(.systemGray6).opacity(0.5))
    }

    private func photoSection(height: CGFloat) -> some View {
        VStack(spacing: 8) {
            if previewImage != nil {
                ZStack(alignment: .topTrailing) {
                    photoContainer(height: height - 28)

                    Button {
                        previewImage = nil
                        viewModel.selectedImageData = nil
                        selectedItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .padding(10)
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Change Photo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .frame(height: 20)
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    photoContainer(height: height)
                }
            }
        }
        .frame(height: height)
    }

    private func photoContainer(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6).opacity(0.5))
            .frame(height: height)
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
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 56, height: 56)
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
            }
            Text("Add Photo")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            Text("Tap to select from gallery")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }

    private func captionSection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Caption")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            ZStack(alignment: .topLeading) {
                if viewModel.caption.isEmpty {
                    Text("Share your experience at this place...")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray3))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $viewModel.caption)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .font(.system(size: 14))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .onChange(of: viewModel.caption) { _, newValue in
                        if newValue.count > captionCharacterLimit {
                            viewModel.caption = String(newValue.prefix(captionCharacterLimit))
                        }
                    }
            }
            .frame(height: height - 24)
        }
        .frame(height: height)
    }

    private var infoSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13))
                .foregroundColor(.orange.opacity(0.8))
            Text("You can only post when you're physically at the location")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.6))
        .cornerRadius(10)
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
