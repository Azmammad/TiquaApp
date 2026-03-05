//
//  MapPlaceholderSection.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 26.02.26.
//
import SwiftUI
import MapKit

struct MapPlaceholderSection: View {
    var latitude: Double? = nil
    var longitude: Double? = nil
    var locationName: String? = nil

    @State private var position: MapCameraPosition = .automatic

    private var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    var body: some View {
        Group {
            if hasLocation, let lat = latitude, let lng = longitude {
                Map(position: $position, interactionModes: [.pan, .zoom]) {
                    Annotation(
                        locationName ?? "",
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    ) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                    }
                }
                .mapStyle(.standard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onChange(of: lat) { _, _ in updateCamera() }
                .onChange(of: lng) { _, _ in updateCamera() }
                .onAppear { updateCamera() }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "map")
                                .font(.system(size: 22))
                                .foregroundColor(Color(.systemGray3))
                            Text("No location")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(.systemGray3))
                        }
                    )
            }
        }
        .padding(.horizontal, 16)
    }

    private func updateCamera() {
        guard let lat = latitude, let lng = longitude else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            position = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            ))
        }
    }
}
