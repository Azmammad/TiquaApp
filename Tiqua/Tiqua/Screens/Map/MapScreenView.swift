//
//  MapScreenView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//
import SwiftUI
import MapKit

struct MapScreenView: View {
    @EnvironmentObject var mapFocusState: MapFocusState
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showLocationActions = false

    var body: some View {
        Map(position: $position) {
            if let lat = mapFocusState.focusedLatitude,
               let lng = mapFocusState.focusedLongitude {
                Annotation(
                    mapFocusState.focusedLocationName ?? "Location",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                ) {
                    Button {
                        showLocationActions = true
                    } label: {
                        pinView
                    }
                }
            }
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic))
        .navigationTitle(mapFocusState.hasFocus ? (mapFocusState.focusedLocationName ?? "Map") : "Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateMapPosition()
        }
        .onChange(of: mapFocusState.focusedLatitude) { _, _ in
            updateMapPosition()
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

    private var pinView: some View {
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
}
