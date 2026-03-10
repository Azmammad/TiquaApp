//
//  MapScreenView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//
import SwiftUI
import MapKit
import FirebaseFirestore

struct MapScreenView: View {
    @EnvironmentObject var mapFocusState: MapFocusState
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var allPosts: [Post] = []
    @State private var selectedPost: Post?
    @State private var showLocationActions = false

    private var isFocusedMode: Bool {
        mapFocusState.hasFocus
    }

    var body: some View {
        Map(position: $position) {
            UserAnnotation()

            if isFocusedMode {
                if let lat = mapFocusState.focusedLatitude,
                   let lng = mapFocusState.focusedLongitude {
                    Annotation(
                        mapFocusState.focusedLocationName ?? "Location",
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    ) {
                        Button {
                            showLocationActions = true
                        } label: {
                            focusedPinView
                        }
                    }
                }
            } else {
                ForEach(allPosts.filter { $0.latitude != nil && $0.longitude != nil }) { post in
                    Annotation(
                        post.locationName ?? "",
                        coordinate: CLLocationCoordinate2D(
                            latitude: post.latitude!,
                            longitude: post.longitude!
                        )
                    ) {
                        Button {
                            selectedPost = post
                        } label: {
                            defaultPinView
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .navigationTitle(isFocusedMode ? (mapFocusState.focusedLocationName ?? "Map") : "Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateMapPosition()
            if !isFocusedMode {
                Task { await loadAllPosts() }
            }
        }
        .onChange(of: mapFocusState.focusedLatitude) { _, _ in
            updateMapPosition()
        }
        .onChange(of: isFocusedMode) { _, newValue in
            if !newValue {
                Task { await loadAllPosts() }
            }
        }
        .confirmationDialog(
            mapFocusState.focusedLocationName ?? "Location",
            isPresented: $showLocationActions,
            titleVisibility: .visible
        ) {
            if let lat = mapFocusState.focusedLatitude,
               let lng = mapFocusState.focusedLongitude {
                Button("Copy Coordinates") {
                    UIPasteboard.general.string = "\(lat), \(lng)"
                }
                Button("Open in Apple Maps") {
                    let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lng)")!
                    UIApplication.shared.open(url)
                }
                Button("Open in Google Maps") {
                    let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lng)")!
                    UIApplication.shared.open(url)
                }
                Button("Open in Waze") {
                    let url = URL(string: "https://waze.com/ul?ll=\(lat),\(lng)&navigate=yes")!
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay(alignment: .bottom) {
            if let post = selectedPost, !isFocusedMode {
                viewPostCallout(post: post)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedPost?.id)
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
    }

    private func updateMapPosition() {
        if let lat = mapFocusState.focusedLatitude,
           let lng = mapFocusState.focusedLongitude {
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        } else {
            locationManager.requestLocation()
            position = .userLocation(fallback: .automatic)
        }
    }

    private func viewPostCallout(post: Post) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(post.locationName ?? post.countryDisplayName ?? "Post")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("@\(post.username)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                selectedPost = post
            } label: {
                Text("View Post")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var focusedPinView: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.accentColor)

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundColor(.accentColor)
                .offset(y: -3)
        }
    }

    private var defaultPinView: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 9))
                .foregroundColor(.accentColor)
                .offset(y: -3)
        }
    }

    private func loadAllPosts() async {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("posts")
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()

            allPosts = snapshot.documents.compactMap { doc -> Post? in
                let data = doc.data()
                guard
                    let id = data["id"] as? String,
                    let ownerId = data["ownerId"] as? String,
                    let username = data["username"] as? String,
                    let imageURL = data["imageURL"] as? String,
                    let timestamp = data["createdAt"] as? Timestamp
                else { return nil }

                return Post(
                    id: id,
                    ownerId: ownerId,
                    username: username,
                    imageURL: imageURL,
                    caption: data["caption"] as? String,
                    locationName: data["locationName"] as? String,
                    countryName: data["countryName"] as? String,
                    latitude: data["latitude"] as? Double,
                    longitude: data["longitude"] as? Double,
                    createdAt: timestamp.dateValue()
                )
            }
        } catch {}
    }
}
