//
//  LocationManager.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 18.02.26.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var locationName: String?
    @Published var locationSubtitle: String?
    @Published var countryName: String?
    @Published var isLoading: Bool = false
    @Published var isDenied: Bool = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isDenied = true
        case .authorizedWhenInUse, .authorizedAlways:
            isLoading = true
            manager.requestLocation()
        @unknown default:
            break
        }
    }

    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        let englishLocale = Locale(identifier: "en_US")

        geocoder.reverseGeocodeLocation(location, preferredLocale: englishLocale) { [weak self] placemarks, _ in
            guard let self = self, let placemark = placemarks?.first else {
                Task { @MainActor in self?.isLoading = false }
                return
            }

            Task { @MainActor in
                self.countryName = placemark.country

                var nameParts: [String] = []
                var subtitleParts: [String] = []

                if let name = placemark.name { nameParts.append(name) }
                if let locality = placemark.locality { nameParts.append(locality) }

                if let adminArea = placemark.administrativeArea { subtitleParts.append(adminArea) }
                if let country = placemark.country { subtitleParts.append(country) }

                self.locationName = nameParts.joined(separator: ", ")
                self.locationSubtitle = subtitleParts.joined(separator: ", ")
                self.isLoading = false
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.reverseGeocode(location: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isDenied = false
                self.isLoading = true
                manager.requestLocation()
            case .denied, .restricted:
                self.isDenied = true
                self.isLoading = false
            default:
                break
            }
        }
    }
}
