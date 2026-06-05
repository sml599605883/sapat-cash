import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../network/config/network_config.dart';
import '../network/crypto/encryption_helper.dart';
import 'report_models.dart';

class ReportPayloadHelper {
  ReportPayloadHelper._();

  static final EncryptionHelper _encryptionHelper = EncryptionHelper(
    key: NetworkConfig.encryptionKey,
    iv: NetworkConfig.encryptionIv,
  );

  static String normalize(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text == 'null' ? '' : text;
  }

  static Map<String, dynamic> buildRiskPayload({
    required String productId,
    required String sceneType,
    required String orderNo,
    required NativeDeviceSnapshot snapshot,
    required ReportLocation? location,
    required int startTimeSeconds,
    required int endTimeSeconds,
  }) {
    return {
      'fellest': normalize(productId),
      'bewrapt': normalize(sceneType),
      'unsuspecting': normalize(orderNo),
      'girasoles': normalize(snapshot.riskDeviceId),
      'goopier': normalize(snapshot.idfa),
      'antisnob': normalize(location?.longitude),
      'forages': normalize(location?.latitude),
      'overtops': '$startTimeSeconds',
      'cornered': '$endTimeSeconds',
    };
  }

  static Future<String> buildEncryptedDevicePayload({
    required NativeDeviceSnapshot snapshot,
    required ReportLocation? location,
    required int lastLoginAtMillis,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;

    final payload = {
      'vulgates': iosInfo.systemVersion,
      'mycobacteria': lastLoginAtMillis,
      'fluorinating': normalize(packageInfo.packageName),
      'lamas': {
        'scalls': snapshot.batteryLevel,
        'hedgehog': snapshot.isCharging,
      },
      'trouser': {
        'zoolatry': normalize(location?.longitude),
        'legendizes': normalize(location?.latitude),
        'unchronological': normalize(location?.fullAddress),
        'embranglement': {
          'dreamlike': normalize(location?.country),
          'paperclips': normalize(location?.countryCode),
          'thionins': normalize(location?.province),
          'baseboards': normalize(location?.city),
          'crural': normalize(location?.locality),
          'compeller': normalize(location?.street),
        },
      },
      'monocarp': {
        'donkeys': normalize(snapshot.idfv),
        'owlishly': normalize(snapshot.idfa),
        'ejaculators': normalize(snapshot.currentWifiBssid),
        'incantational': DateTime.now().millisecondsSinceEpoch,
        'cosponsoring': normalize(snapshot.uptimeMillis),
        'defiances': normalize(snapshot.networkType),
        'recolor': normalize(snapshot.carrier),
        'shrubbiest': normalize(snapshot.language),
        'diphthongizes': normalize(snapshot.timeZoneName),
        'catabolically': snapshot.elapsedMillis,
        'discombobulated': snapshot.isUsingProxy,
        'subrogated': snapshot.isUsingVpn,
        'precommitments': snapshot.isJailbroken,
        'wedeln': snapshot.isEmulator,
      },
      'ritz': {
        'humanity': normalize(snapshot.brand),
        'downshifts': iosInfo.model,
        'cashoo': snapshot.cpuCoreCount,
        'regilds': snapshot.screenHeight,
        'trickily': normalize(snapshot.deviceName),
        'winesap': snapshot.screenWidth,
        'bombings': iosInfo.modelName,
        'aplombs': normalize(snapshot.screenSize),
        'menazons': iosInfo.systemVersion,
      },
      'sanitorium': {
        'scourges': normalize(snapshot.innerIp),
        'sandlots': [
          {
            'fornices': normalize(snapshot.currentWifiName),
            'colatitudes': normalize(snapshot.currentWifiBssid),
            'ejaculators': normalize(snapshot.currentWifiBssid),
            'jokily': normalize(snapshot.currentWifiName),
          },
        ],
        'crinites': {
          'fornices': normalize(snapshot.currentWifiName),
          'colatitudes': normalize(snapshot.currentWifiBssid),
          'ejaculators': normalize(snapshot.currentWifiBssid),
          'jokily': normalize(snapshot.currentWifiName),
        },
        'etymologist': normalize(snapshot.wifiCount),
      },
      'clubwomen': {
        'wherever': normalize(snapshot.availableStorage),
        'step': normalize(snapshot.totalStorage),
        'outstarted': normalize(snapshot.totalMemory),
        'trasher': normalize(snapshot.availableMemory),
      },
    };

    return _encryptionHelper.encryptText(jsonEncode(payload));
  }
}
