import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../report/report_cache.dart';
import '../../report/report_native_bridge.dart';
import 'common_param_provider.dart';

class NetworkCommonParamProvider implements AsyncCommonParamProvider {
  const NetworkCommonParamProvider();

  static const String _channel = 'appstore-ph-sapat-cash-ios';

  @override
  Future<Map<String, dynamic>> getCommonParams() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final snapshot = await ReportNativeBridge.getDeviceSnapshot();
    final sessionId = await ReportCache.getSessionId();
    var deviceName = snapshot.deviceName;
    try {
      final iosInfo = await deviceInfo.iosInfo;
      if (iosInfo.modelName.trim().isNotEmpty) {
        deviceName = iosInfo.modelName.trim();
      }
    } catch (_) {
      if (deviceName.trim().isEmpty) {
        deviceName = snapshot.model;
      }
    }

    return {
      'appVersion': packageInfo.version,
      'deviceName': deviceName,
      'deviceId': snapshot.idfv,
      'systemVersion': snapshot.osVersion,
      'channel': _channel,
      'sessionId': sessionId,
      'advertisingId': snapshot.idfv,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }
}
