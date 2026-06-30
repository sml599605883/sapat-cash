import Flutter
import StoreKit
import UIKit
import AppTrackingTransparency
import AdSupport
import CFNetwork
import CoreLocation
import CoreTelephony
import Darwin
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
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
  private let geocoder = CLGeocoder()
  private var latestLocationPayload: [String: Any]?
  private var pendingLocationResults: [FlutterResult] = []
  private var locationRequestInFlight = false
  private var locationTimeoutWorkItem: DispatchWorkItem?
  private var pushToken: String = ""
  private var pendingPushRoutes: [String] = []

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
      handleLocationRequest(result: result)
    case "getPushToken":
      result(pushToken)
    case "getSystemProxy":
      result(buildSystemProxyPayload())
    case "getDeviceSnapshot":
      buildDeviceSnapshot(result: result)
    case "initializeAdjust":
      result(nil)
    case "requestAppReview":
      requestAppReview(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestAppReview(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      if #available(iOS 14.0, *) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first {
          SKStoreReviewController.requestReview(in: windowScene)
          result(nil)
          return
        }
      } else if #available(iOS 10.3, *) {
        SKStoreReviewController.requestReview()
        result(nil)
        return
      }
      result(nil)
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

  private func buildDeviceSnapshot(result: @escaping FlutterResult) {
    let wifiCount = wifiCount()
    fetchCurrentSSIDBSSID { [weak self] ssid, bssid in
      guard let self else {
        result([:])
        return
      }
      result(self.buildDeviceSnapshotPayload(
        wifiCount: wifiCount,
        currentWifiName: ssid,
        currentWifiBssid: bssid
      ))
    }
  }

  private func buildDeviceSnapshotPayload(
    wifiCount: Int,
    currentWifiName: String,
    currentWifiBssid: String
  ) -> [String: Any] {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    let locale = Locale.current
    let authorizationStatus = currentLocationAuthorizationStatus()
    let proxyPayload = buildSystemProxyPayload()
    let storagePayload = buildStoragePayload()
    let ipAddress = wifiIPv4Address()
    let networkType = currentNetworkType()
    let carrier = currentCarrierName()
    var idfa: String {
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        guard idfa == "00000000-0000-0000-0000-000000000000" else {
            return idfa
        }
        return ""
    }
    return [
      "idfv": device.identifierForVendor?.uuidString ?? "",
      "idfa": idfa,
      "deviceId": device.identifierForVendor?.uuidString ?? "",
      "batteryLevel": max(Int(device.batteryLevel * 100), 0),
      "isCharging": device.batteryState == .charging || device.batteryState == .full ? 1 : 0,
      "elapsedMillis": Int(ProcessInfo.processInfo.systemUptime * 1000),
      "uptimeMillis": "\(Int(ProcessInfo.processInfo.systemUptime * 1000))",
      "isUsingProxy": proxyPayload["enabled"] as? Bool == true ? "1" : "0",
      "isUsingVpn": isUsingVpn() ? 1 : 0,
      "isJailbroken": isJailbroken() ? 1: 0,
      "isEmulator": isRunningOnSimulator() ? 1 : 0,
      "language": locale.languageCode ?? "",
      "carrier": carrier,
      "networkType": networkType,
      "timeZoneName": TimeZone.current.abbreviation() ?? "",
      "cpuCoreCount": ProcessInfo.processInfo.activeProcessorCount,
      "brand": "\("QC_Re")feren\("ce_Phone")",
      "deviceName": device.name,
      "model": deviceMachineIdentifier(),
      "screenHeight": Int(UIScreen.main.bounds.height),
      "screenWidth": Int(UIScreen.main.bounds.width),
      "screenSize": "\(Int(UIScreen.main.nativeBounds.width))x\(Int(UIScreen.main.nativeBounds.height))",
      "innerIp": ipAddress,
      "currentWifiName": currentWifiName,
      "currentWifiBssid": currentWifiBssid,
      "wifiCount": "\(wifiCount)",
      "availableStorage": storagePayload.available,
      "totalStorage": storagePayload.total,
      "totalMemory": "\(ProcessInfo.processInfo.physicalMemory)",
      "availableMemory": currentAvailableMemory(),
      "pushToken": pushToken,
      "riskDeviceId": device.identifierForVendor?.uuidString ?? "",
      "locationPermissionStatus": permissionStatusString(authorizationStatus)
    ]
  }

  private func wifiCount() -> Int {
    currentWifiNetworkInfos().count
  }

  private func fetchCurrentSSIDBSSID(completion: @escaping (String, String) -> Void) {
    if #available(iOS 26.0, *) {
      NEHotspotNetwork.fetchCurrent { [weak self] network in
        let ssid = network?.ssid ?? ""
        let bssid = network?.bssid ?? ""
        if !ssid.isEmpty || !bssid.isEmpty {
          completion(ssid, bssid)
          return
        }
        let fallback = self?.legacySSIDBSSID() ?? ("", "")
        completion(fallback.0, fallback.1)
      }
      return
    }
    let fallback = legacySSIDBSSID()
    completion(fallback.0, fallback.1)
  }

  private func legacySSIDBSSID() -> (String, String) {
    let networks = currentWifiNetworkInfos()
    guard let first = networks.first else {
      return ("", "")
    }
    return (first.ssid, first.bssid)
  }

  private func currentWifiNetworkInfos() -> [(ssid: String, bssid: String)] {
    guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
      return []
    }

    var networks: [(ssid: String, bssid: String)] = []
    for interface in interfaces {
      guard
        let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any]
      else {
        continue
      }

      let ssid = info[kCNNetworkInfoKeySSID as String] as? String ?? ""
      let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String ?? ""
      guard !ssid.isEmpty || !bssid.isEmpty else {
        continue
      }
      networks.append((ssid: ssid, bssid: bssid))
    }
    return networks
  }
    
    private func isJailbroken() -> Bool {
#if targetEnvironment(simulator)
        return false
#else
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
        ]
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        if let url = URL(string: "cydia://package/com.example.package") {
            if UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        let testPath = "/private/jb_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
        }
        return false
#endif
    }
    
  private func currentCarrierName() -> String {
      let networkInfo = CTTelephonyNetworkInfo()
      var carrierName = ""
      if #available(iOS 12.0, *) {
          if let carriers = networkInfo.serviceSubscriberCellularProviders {
              if carriers.values.first?.isoCountryCode == nil {
                  carrierName = ""
              } else {
                  carrierName = carriers.values.first?.carrierName ?? ""
              }
          }
      } else {
          if networkInfo.subscriberCellularProvider?.isoCountryCode == nil {
              carrierName = ""
          } else {
              carrierName = networkInfo.subscriberCellularProvider?.carrierName ?? ""
          }
      }
      return carrierName
  }

  private func currentNetworkType() -> String {
    let interfaceNames = activeInterfaceNames()
    if interfaceNames.contains("en0") {
      return "WIFI"
    }

    let networkInfo = CTTelephonyNetworkInfo()
    let radioTech: String?
    if #available(iOS 12.0, *) {
      radioTech = networkInfo.serviceCurrentRadioAccessTechnology?.values.first
    } else {
      radioTech = networkInfo.currentRadioAccessTechnology
    }

    switch radioTech {
    case CTRadioAccessTechnologyGPRS,
      CTRadioAccessTechnologyEdge,
      CTRadioAccessTechnologyCDMA1x:
      return "2G"
    case CTRadioAccessTechnologyWCDMA,
      CTRadioAccessTechnologyHSDPA,
      CTRadioAccessTechnologyHSUPA,
      CTRadioAccessTechnologyCDMAEVDORev0,
      CTRadioAccessTechnologyCDMAEVDORevA,
      CTRadioAccessTechnologyCDMAEVDORevB,
      CTRadioAccessTechnologyeHRPD:
      return "3G"
    case CTRadioAccessTechnologyLTE:
      return "4G"
    default:
      if #available(iOS 14.1, *),
         radioTech == CTRadioAccessTechnologyNR ||
         radioTech == CTRadioAccessTechnologyNRNSA {
        return "5G"
      }
      return "OTHER"
    }
  }

  private func wifiIPv4Address() -> String {
    var address = ""
    var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?

    guard getifaddrs(&ifaddrPointer) == 0, let firstAddress = ifaddrPointer else {
      return address
    }
    defer { freeifaddrs(ifaddrPointer) }

    for interface in sequence(first: firstAddress, next: { $0.pointee.ifa_next }) {
      guard let interfaceAddress = interface.pointee.ifa_addr else {
        continue
      }
      let addrFamily = interfaceAddress.pointee.sa_family
      guard addrFamily == UInt8(AF_INET) else {
        continue
      }

      let name = String(cString: interface.pointee.ifa_name)
      guard name == "en0" else {
        continue
      }

      var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
      var addr = interfaceAddress.pointee
      if getnameinfo(
        &addr,
        socklen_t(interfaceAddress.pointee.sa_len),
        &hostname,
        socklen_t(hostname.count),
        nil,
        socklen_t(0),
        NI_NUMERICHOST
      ) == 0 {
        address = String(cString: hostname)
        break
      }
    }

    return address
  }

  private func activeInterfaceNames() -> [String] {
    var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddrPointer) == 0, let firstAddress = ifaddrPointer else {
      return []
    }
    defer { freeifaddrs(ifaddrPointer) }

    var names = Set<String>()
    for interface in sequence(first: firstAddress, next: { $0.pointee.ifa_next }) {
      let flags = Int32(interface.pointee.ifa_flags)
      let isUp = (flags & IFF_UP) == IFF_UP
      let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
      guard isUp, isRunning else {
        continue
      }
      names.insert(String(cString: interface.pointee.ifa_name))
    }
    return Array(names)
  }

  private func isUsingVpn() -> Bool {
      guard
          let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
              as? [String: Any],
          let scoped = settings["__SCOPED__"] as? [String: Any]
      else {
          return false
      }

      let keys = scoped.keys.map { $0.lowercased() }
      let isVPN = keys.contains { key in
          key.contains("tap") || key.contains("tun") || key.contains("ppp")
              || key.contains("ipsec") || key.contains("utun")
      }
      return isVPN
  }

  private func buildStoragePayload() -> (available: String, total: String) {
    guard
      let path = NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true
      ).first
    else {
      return ("0", "0")
    }

    do {
      let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
      let available = attributes[.systemFreeSize] as? UInt64 ?? 0
      let total = attributes[.systemSize] as? UInt64 ?? 0
      return ("\(available)", "\(total)")
    } catch {
      return ("0", "0")
    }
  }

  private func currentAvailableMemory() -> String {
    var vmStats = vm_statistics_data_t()
    var infoCount = mach_msg_type_number_t(
      MemoryLayout<vm_statistics_data_t>.size / MemoryLayout<integer_t>.size
    )
    let result: kern_return_t = withUnsafeMutableBytes(of: &vmStats) { rawBuffer in
      let reboundBuffer = rawBuffer.bindMemory(to: integer_t.self)
      return host_statistics(
        mach_host_self(),
        HOST_VM_INFO,
        reboundBuffer.baseAddress,
        &infoCount
      )
    }

    guard result == KERN_SUCCESS else {
      return "0"
    }

    let freeBytes =
      UInt64(vm_page_size) * UInt64(vmStats.free_count) +
      UInt64(vm_page_size) * UInt64(vmStats.inactive_count)
    return "\(freeBytes)"
  }

  private func deviceMachineIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let mirror = Mirror(reflecting: systemInfo.machine)
    return mirror.children.reduce(into: "") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else {
        return
      }
      identifier.append(Character(UnicodeScalar(UInt8(value))))
    }
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
    flushPendingPushRoutesIfNeeded()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    guard let url = extractPushUrl(from: userInfo) else {
      completionHandler([.banner, .badge, .sound])
      return
    }
    sendPushRouteToFlutter(url)
    completionHandler([])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    defer { completionHandler() }
    let userInfo = response.notification.request.content.userInfo
    guard let url = extractPushUrl(from: userInfo) else {
      return
    }
    sendPushRouteToFlutter(url)
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

    if geocoder.isGeocoding {
      geocoder.cancelGeocode()
    }

    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
      guard let self else {
        return
      }

      guard let placemark = placemarks?.first else {
        return
      }

      let payload = self.locationPayload(
        location: location,
        placemark: placemark,
        status: self.currentLocationAuthorizationStatus()
      )
      self.latestLocationPayload = payload
      self.resolvePendingLocation(payload)
    }
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
    pendingLocationResults.append(result)
    if locationRequestInFlight {
      return
    }
    locationRequestInFlight = true
    scheduleLocationTimeoutFallback()

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
    guard locationRequestInFlight else {
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
      "fullAddress": "",
      "countryCode": "",
      "country": "",
      "street": "",
      "latitude": "",
      "longitude": "",
      "city": "",
      "permissionStatus": permissionStatusString(status)
    ]
  }

  private func locationPayload(
    location: CLLocation,
    placemark: CLPlacemark?,
    status: CLAuthorizationStatus
  ) -> [String: Any] {
    [
      "province": placemark?.administrativeArea ?? "",
      "subAdminArea": placemark?.subAdministrativeArea ?? "",
      "fullAddress": buildFullAddress(from: placemark),
      "countryCode": placemark?.isoCountryCode ?? "",
      "country": placemark?.country ?? "",
      "street": buildStreet(from: placemark),
      "latitude": "\(location.coordinate.latitude)",
      "longitude": "\(location.coordinate.longitude)",
      "city": placemark?.locality ?? placemark?.subAdministrativeArea ?? "",
      "permissionStatus": permissionStatusString(status)
    ]
  }

  private func buildStreet(from placemark: CLPlacemark?) -> String {
    guard let placemark else {
      return ""
    }

    let parts = [
      placemark.subThoroughfare,
      placemark.thoroughfare,
      placemark.subLocality,
      placemark.name
    ]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    var seen = Set<String>()
    let uniqueParts = parts.filter { seen.insert($0).inserted }
    return uniqueParts.joined(separator: " ")
  }

  private func extractPushUrl(from userInfo: [AnyHashable: Any]) -> String? {
    if let url = normalizedPushUrl(userInfo["url"]) {
      return url
    }

    if let params = userInfo["params"] as? [AnyHashable: Any],
       let url = normalizedPushUrl(params["url"]) {
      return url
    }

    if let paramsText = userInfo["params"] as? String,
       let data = paramsText.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let url = normalizedPushUrl(json["url"]) {
      return url
    }

    return nil
  }

  private func normalizedPushUrl(_ rawValue: Any?) -> String? {
    guard let value = rawValue as? String else {
      return nil
    }
    let url = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return url.isEmpty ? nil : url
  }

  private func sendPushRouteToFlutter(_ url: String) {
    if let eventSink {
      eventSink(["type": "push_route", "url": url])
      return
    }
    pendingPushRoutes.append(url)
  }

  private func flushPendingPushRoutesIfNeeded() {
    guard let eventSink, !pendingPushRoutes.isEmpty else {
      return
    }
    let routes = pendingPushRoutes
    pendingPushRoutes.removeAll()
    for route in routes {
      eventSink(["type": "push_route", "url": route])
    }
  }

  private func buildFullAddress(from placemark: CLPlacemark?) -> String {
    guard let placemark else {
      return ""
    }

    let parts = [
      placemark.name,
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.country
    ]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    var seen = Set<String>()
    let uniqueParts = parts.filter { seen.insert($0).inserted }
    return uniqueParts.joined(separator: ", ")
  }

  private func resolvePendingLocation(_ payload: [String: Any]?) {
    locationTimeoutWorkItem?.cancel()
    locationTimeoutWorkItem = nil
    let pendingResults = pendingLocationResults
    pendingLocationResults.removeAll()
    locationRequestInFlight = false
    for result in pendingResults {
      result(payload)
    }
  }

  private func scheduleLocationTimeoutFallback() {
    locationTimeoutWorkItem?.cancel()

    let workItem = DispatchWorkItem { [weak self] in
      guard let self else {
        return
      }
      guard self.locationRequestInFlight else {
        return
      }

      if let latestLocationPayload = self.latestLocationPayload {
        self.resolvePendingLocation(latestLocationPayload)
      } else {
        self.resolvePendingLocation(nil)
      }
    }

    locationTimeoutWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: workItem)
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
