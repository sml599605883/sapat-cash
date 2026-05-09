import Flutter
import UIKit
import AppTrackingTransparency
import AdSupport
import CFNetwork
import CoreLocation
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate, FlutterStreamHandler {
  private let methodChannelName = "sapat_cash/report_method"
  private let eventChannelName = "sapat_cash/report_event"
  private var eventSink: FlutterEventSink?
  private var channelsConfigured = false
  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    return manager
  }()
  private var latestLocationPayload: [String: Any]?
  private var pendingLocationResult: FlutterResult?
  private var pushToken: String = ""

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    DispatchQueue.main.async { [weak self] in
      self?.configureChannelsIfNeeded()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    DispatchQueue.main.async { [weak self] in
      self?.configureChannelsIfNeeded()
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    eventSink?(["type": "push_token", "token": pushToken])
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    eventSink?(["type": "push_token_failed", "message": error.localizedDescription])
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestNotificationPermission":
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if let error {
          result(error.localizedDescription)
          return
        }
        result(granted ? "authorized" : "denied")
      }
    case "requestTrackingPermission":
      ATTrackingManager.requestTrackingAuthorization { [weak self] status in
        let value = self?.trackingStatusString(status) ?? "unknown"
        self?.eventSink?(["type": "tracking_status_changed", "status": value])
        result(value)
      }
    case "getTrackingStatus":
      result(trackingStatusString(ATTrackingManager.trackingAuthorizationStatus))
    case "getLocation":
      if let latestLocationPayload {
        result(latestLocationPayload)
        return
      }
      handleLocationRequest(result: result)
    case "getPushToken":
      result(pushToken)
    case "getSystemProxy":
      result(buildSystemProxyPayload())
    case "getDeviceSnapshot":
      result(buildDeviceSnapshot())
    case "initializeAdjust":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func trackingStatusString(_ status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .authorized:
      return "authorized"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .notDetermined:
      return "not_determined"
    @unknown default:
      return "unknown"
    }
  }

  private func buildDeviceSnapshot() -> [String: Any] {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    let locale = Locale.current
    let authorizationStatus = currentLocationAuthorizationStatus()

    return [
      "idfv": device.identifierForVendor?.uuidString ?? "",
      "idfa": ASIdentifierManager.shared().advertisingIdentifier.uuidString,
      "deviceId": device.identifierForVendor?.uuidString ?? "",
      "batteryLevel": "\(max(Int(device.batteryLevel * 100), 0))",
      "isCharging": device.batteryState == .charging || device.batteryState == .full ? "1" : "0",
      "elapsedMillis": "\(Int(ProcessInfo.processInfo.systemUptime * 1000))",
      "uptimeMillis": "\(Int(ProcessInfo.processInfo.systemUptime * 1000))",
      "isUsingProxy": buildSystemProxyPayload()["enabled"] as? Bool == true ? "1" : "0",
      "isUsingVpn": "0",
      "isJailbroken": "0",
      "isEmulator": isRunningOnSimulator() ? "1" : "0",
      "language": locale.languageCode ?? "",
      "carrier": "",
      "networkType": "OTHER",
      "timeZoneName": TimeZone.current.identifier,
      "cpuCoreCount": "\(ProcessInfo.processInfo.activeProcessorCount)",
      "brand": "Apple",
      "deviceName": device.name,
      "model": device.model,
      "osVersion": device.systemVersion,
      "screenHeight": "\(Int(UIScreen.main.bounds.height))",
      "screenWidth": "\(Int(UIScreen.main.bounds.width))",
      "screenSize": "\(UIScreen.main.nativeBounds.size)",
      "innerIp": "",
      "currentWifiName": "",
      "currentWifiBssid": "",
      "currentWifiMac": "",
      "availableStorage": "0",
      "totalStorage": "0",
      "totalMemory": "\(ProcessInfo.processInfo.physicalMemory)",
      "availableMemory": "0",
      "pushToken": pushToken,
      "riskDeviceId": device.identifierForVendor?.uuidString ?? "",
      "locationPermissionStatus": permissionStatusString(authorizationStatus)
    ]
  }

  private func buildSystemProxyPayload() -> [String: Any] {
    guard
      let unmanagedSettings = CFNetworkCopySystemProxySettings(),
      let settings = unmanagedSettings.takeRetainedValue() as? [String: Any]
    else {
      return ["enabled": false, "host": "", "port": 0]
    }

    let host = settings["HTTPProxy"] as? String ?? ""
    let port = settings["HTTPPort"] as? Int ?? 0
    let httpEnabled = (settings["HTTPEnable"] as? Int ?? 0) == 1
    let httpsHost = settings["HTTPSProxy"] as? String ?? ""
    let httpsPort = settings["HTTPSPort"] as? Int ?? 0
    let httpsEnabled = (settings["HTTPSEnable"] as? Int ?? 0) == 1

    if httpEnabled, !host.isEmpty, port > 0 {
      return ["enabled": true, "host": host, "port": port]
    }

    if httpsEnabled, !httpsHost.isEmpty, httpsPort > 0 {
      return ["enabled": true, "host": httpsHost, "port": httpsPort]
    }

    return ["enabled": false, "host": "", "port": 0]
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    handleLocationAuthorizationChanged(manager)
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    handleLocationAuthorizationChanged(manager)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      resolvePendingLocation(nil)
      return
    }

    let payload: [String: Any] = [
      "province": "",
      "countryCode": "",
      "country": "",
      "street": "",
      "latitude": "\(location.coordinate.latitude)",
      "longitude": "\(location.coordinate.longitude)",
      "city": "",
      "permissionStatus": permissionStatusString(currentLocationAuthorizationStatus())
    ]
    latestLocationPayload = payload
    resolvePendingLocation(payload)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    resolvePendingLocation(nil)
  }

  private func permissionStatusString(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
      return "not_determined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorizedAlways, .authorizedWhenInUse:
      return "authorized"
    @unknown default:
      return "unknown"
    }
  }

  private func handleLocationRequest(result: @escaping FlutterResult) {
    pendingLocationResult = result

    guard CLLocationManager.locationServicesEnabled() else {
      resolvePendingLocation(locationPermissionPayload(status: .denied))
      return
    }

    switch currentLocationAuthorizationStatus() {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse:
      locationManager.requestLocation()
    case .restricted, .denied:
      resolvePendingLocation(locationPermissionPayload(status: currentLocationAuthorizationStatus()))
    @unknown default:
      resolvePendingLocation(locationPermissionPayload(status: currentLocationAuthorizationStatus()))
    }
  }

  private func handleLocationAuthorizationChanged(_ manager: CLLocationManager) {
    guard pendingLocationResult != nil else {
      return
    }

    switch currentLocationAuthorizationStatus() {
    case .authorizedAlways, .authorizedWhenInUse:
      manager.requestLocation()
    case .restricted, .denied:
      resolvePendingLocation(locationPermissionPayload(status: currentLocationAuthorizationStatus()))
    case .notDetermined:
      break
    @unknown default:
      resolvePendingLocation(locationPermissionPayload(status: currentLocationAuthorizationStatus()))
    }
  }

  private func currentLocationAuthorizationStatus() -> CLAuthorizationStatus {
    locationManager.authorizationStatus
  }

  private func locationPermissionPayload(status: CLAuthorizationStatus) -> [String: Any] {
    [
      "province": "",
      "countryCode": "",
      "country": "",
      "street": "",
      "latitude": "",
      "longitude": "",
      "city": "",
      "permissionStatus": permissionStatusString(status)
    ]
  }

  private func resolvePendingLocation(_ payload: [String: Any]?) {
    pendingLocationResult?(payload)
    pendingLocationResult = nil
  }

  private func configureChannelsIfNeeded() {
    guard !channelsConfigured else {
      return
    }
    guard let flutterViewController = currentFlutterViewController() else {
      return
    }

    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: flutterViewController.binaryMessenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }

    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: flutterViewController.binaryMessenger
    )
    eventChannel.setStreamHandler(self)
    channelsConfigured = true
  }

  private func currentFlutterViewController() -> FlutterViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    for scene in scenes {
      for window in scene.windows {
        if let controller = flutterViewController(from: window.rootViewController) {
          return controller
        }
      }
    }
    return flutterViewController(from: window?.rootViewController)
  }

  private func flutterViewController(from controller: UIViewController?) -> FlutterViewController? {
    if let flutterController = controller as? FlutterViewController {
      return flutterController
    }
    if let navigationController = controller as? UINavigationController {
      return flutterViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = controller as? UITabBarController {
      return flutterViewController(from: tabBarController.selectedViewController)
    }
    if let presentedController = controller?.presentedViewController {
      return flutterViewController(from: presentedController)
    }
    return controller?.children.lazy.compactMap { self.flutterViewController(from: $0) }.first
  }

  private func isRunningOnSimulator() -> Bool {
#if targetEnvironment(simulator)
    return true
#else
    return false
#endif
  }
}
