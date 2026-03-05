//
//  MapScreenView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//

import SwiftUI
import MapKit

struct MapScreenView: View {
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
                Map(position: $position) {
                    Annotation(
                        locationName ?? "Location",
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    ) {
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
                .mapStyle(.standard(elevation: .realistic))
                .onAppear {
                    position = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "map")
                        .font(.system(size: 56))
                        .foregroundColor(Color(.systemGray3))
                    Text("Map coming soon")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(locationName ?? "Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}
