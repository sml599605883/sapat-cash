class ReportLocation {
  const ReportLocation({
    this.province,
    required this.fullAddress,
    required this.countryCode,
    required this.country,
    required this.street,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.permissionStatus = '',
  });

  final String? province;
  final String fullAddress;
  final String countryCode;
  final String country;
  final String street;
  final String latitude;
  final String longitude;
  final String city;
  final String permissionStatus;

  bool get isEmpty =>
      province == null &&
      fullAddress.isEmpty &&
      countryCode.isEmpty &&
      country.isEmpty &&
      street.isEmpty &&
      latitude.isEmpty &&
      longitude.isEmpty &&
      city.isEmpty;

  bool get isValid =>
      latitude.isNotEmpty ||
      longitude.isNotEmpty ||
      fullAddress.isNotEmpty ||
      street.isNotEmpty ||
      city.isNotEmpty ||
      country.isNotEmpty;

  Map<String, dynamic> toCacheMap() {
    return {
      'province': province,
      'fullAddress': fullAddress,
      'countryCode': countryCode,
      'country': country,
      'street': street,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'permissionStatus': permissionStatus,
    };
  }

  factory ReportLocation.fromCacheMap(Map<String, dynamic> map) {
    return ReportLocation(
      province: map['province'] as String?,
      fullAddress: '${map['fullAddress'] ?? ''}',
      countryCode: '${map['countryCode'] ?? ''}',
      country: '${map['country'] ?? ''}',
      street: '${map['street'] ?? ''}',
      latitude: '${map['latitude'] ?? ''}',
      longitude: '${map['longitude'] ?? ''}',
      city: '${map['city'] ?? ''}',
      permissionStatus: '${map['permissionStatus'] ?? ''}',
    );
  }
}

class NativeDeviceSnapshot {
  const NativeDeviceSnapshot({
    this.idfv = '',
    this.idfa = '',
    this.deviceId = '',
    this.batteryLevel = 0,
    this.isCharging = 0,
    this.elapsedMillis = 0,
    this.uptimeMillis = '0',
    this.isUsingProxy = 0,
    this.isUsingVpn = 0,
    this.isJailbroken = 0,
    this.isEmulator = 0,
    this.language = '',
    this.carrier = '',
    this.networkType = '',
    this.timeZoneName = '',
    this.cpuCoreCount = 0,
    this.brand = '',
    this.deviceName = '',
    this.model = '',
    this.screenHeight = 0,
    this.screenWidth = 0,
    this.screenSize = '0',
    this.innerIp = '',
    this.currentWifiName = '',
    this.currentWifiBssid = '',
    this.wifiCount = 0,
    this.availableStorage = '0',
    this.totalStorage = '0',
    this.totalMemory = '0',
    this.availableMemory = '0',
    this.pushToken = '',
    this.riskDeviceId = '',
  });

  final String idfv;
  final String idfa;
  final String deviceId;
  final int batteryLevel;
  final int isCharging;
  final int elapsedMillis;
  final String uptimeMillis;
  final int isUsingProxy;
  final int isUsingVpn;
  final int isJailbroken;
  final int isEmulator;
  final String language;
  final String carrier;
  final String networkType;
  final String timeZoneName;
  final int cpuCoreCount;
  final String brand;
  final String deviceName;
  final String model;
  final int screenHeight;
  final int screenWidth;
  final String screenSize;
  final String innerIp;
  final String currentWifiName;
  final String currentWifiBssid;
  final int wifiCount;
  final String availableStorage;
  final String totalStorage;
  final String totalMemory;
  final String availableMemory;
  final String pushToken;
  final String riskDeviceId;
}

class FaceReportPayload {
  const FaceReportPayload({
    required this.livenessId,
    required this.requestId,
    required this.resultCode,
    required this.resultMessage,
  });

  final String livenessId;
  final String requestId;
  final String resultCode;
  final String resultMessage;
}
