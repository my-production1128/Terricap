//
//  LocationManager.swift
//  step tracker
//
//  Created by 濱松未波 on 2025/11/18.
//
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate, LocationServiceType {
    private var locationManger = CLLocationManager()

    private var _lastNumberOfSteps: NSNumber = 0
    weak var delegate: LocationServiceDelegate?

    static var shared = LocationManager()
    private override init() {

    }

    func setup() {
        locationManger.delegate = self

        locationManger.allowsBackgroundLocationUpdates = true
        locationManger.pausesLocationUpdatesAutomatically = false

        let status = locationManger.authorizationStatus
        switch status {
        case .authorizedAlways:
            print("authorizedAlways")
        case .authorizedWhenInUse:
            print("authorizedWhenInUse")
        case .denied:
            print("denied")
        case .restricted:
            print("restricted")
        case .notDetermined:
            requestAuthorize()
        default:
            break
        }
    }

    func requestAuthorize() {
        locationManger.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorization status=\(status)")
        switch status {
        case .authorizedAlways:
            print("authorizedAlways")
        case .authorizedWhenInUse:
            print("authorizedWhenInUse")
            locationManger.requestAlwaysAuthorization()
        case .denied,
             .restricted,
             .notDetermined:
            break
        default:
            break
        }
    }

    func startUpdateLocation() {
        _lastNumberOfSteps = PedometerManager.shared.numberOfSteps
        locationManger.startUpdatingLocation()
    }

    func stopUpdateLocation() {
        locationManger.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("didUpdateLocations locations=\(locations)")
        delegate?.locationManager(self, didUpdateLocation: location)

        var log = ""
        locations.forEach { location in
            let longitude =  location.coordinate.longitude
            let latitude = location.coordinate.latitude
            log += "long \(longitude), lat \(latitude)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError error=\(error.localizedDescription)")
    }
}

