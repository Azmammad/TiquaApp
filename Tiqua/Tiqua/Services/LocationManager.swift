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
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var locationName: String?
    @Published var locationSubtitle: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var hasResolved = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }

        isLoading = true
        errorMessage = nil
        hasResolved = false
        manager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.cancelGeocode()

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let error {
                    self.locationName = nil
                    self.locationSubtitle = nil
                    self.errorMessage = "Unable to determine location name: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }

                guard let placemark = placemarks?.first else {
                    self.locationName = nil
                    self.locationSubtitle = nil
                    self.isLoading = false
                    return
                }

                let name = placemark.name
                    ?? placemark.thoroughfare
                    ?? placemark.subLocality
                    ?? placemark.locality
                    ?? "Unknown Location"

                var subtitleParts: [String] = []
                if let locality = placemark.locality, locality != name {
                    subtitleParts.append(locality)
                }
                if let country = placemark.country {
                    subtitleParts.append(country)
                }

                self.locationName = name
                self.locationSubtitle = subtitleParts.isEmpty ? nil : subtitleParts.joined(separator: ", ")
                self.isLoading = false
            }
        }
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor [weak self] in
            guard let self, !self.hasResolved else { return }
            self.hasResolved = true
            self.currentLocation = location
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status

            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.requestLocation()
            }
        }
    }
}
