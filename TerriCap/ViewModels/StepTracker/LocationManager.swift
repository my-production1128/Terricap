//
//  LocationManager.swift
//  step tracker
//
//  Created by 濱松未波 on 2025/11/18.
//
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate, LocationServiceType {

    // ひとむ追加：最後に公園検索を実行した場所を保存するプロパティ
    private var lastSearchLocation: CLLocation?
    
    // ひとむ追加：何メートル移動したら再検索するか
    private let searchThreshold: CLLocationDistance = 100


    
    var locationManger = CLLocationManager()

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
   
        //--------------------------------
        // ★ 追加:移動距離判定
        let shouldSearch: Bool
        if let lastLocation = lastSearchLocation {
            // 前回検索した場所からの距離（メートル）を計算
            let distance = location.distance(from: lastLocation)
            print("📏 移動距離: \(Int(distance))m / 次のスキャンまで残り: \(Int(searchThreshold - distance))m")
            shouldSearch = distance >= searchThreshold
        } else {
            // 初回起動時は前回地点がないので必ず実行
            shouldSearch = true
        }
        
        if shouldSearch {
            print("[AUTO SCAN] \(Int(searchThreshold))m以上移動したため、公園検索を実行します。")
            ParkSearchService.shared.searchAndSave(at: location.coordinate)
            // 今の場所を「最後に検索した場所」として記憶
            lastSearchLocation = location
        }
        
        
        
        
    //---------------------------------------------------
        
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

