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

    static var shared = LocationManager()
    private override init() {

    }

    func setup() {
        locationManger.delegate = self
        // バックグラウンドでも位置情報更新をONにする
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
        print("didUpdateLocations locations=\(locations)")
        var log = ""
        locations.forEach { location in
            let longitude =  location.coordinate.longitude
            let latitude = location.coordinate.latitude
            log += "long \(longitude), lat \(latitude)"
        }
        let steps = PedometerManager.shared.numberOfSteps
        // 歩数が違うときだけプッシュ通知
        if steps != _lastNumberOfSteps {
            _lastNumberOfSteps = steps
            NotificationManager.shared.sendNotification(title: "歩数: \(steps), 位置情報", body: log)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError error=\(error.localizedDescription)")
    }
}

