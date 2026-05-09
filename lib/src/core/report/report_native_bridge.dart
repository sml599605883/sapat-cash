import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../network/debug/network_proxy_manager.dart';
import 'report_models.dart';

class ReportNativeBridge {
  ReportNativeBridge._();

  static const _methodChannel = MethodChannel('sapat_cash/report_method');
  static const _eventChannel = EventChannel('sapat_cash/report_event');

  static Stream<Map<String, dynamic>>? _eventStream;

  static Stream<Map<String, dynamic>> nativeEvents() {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map))
        .handleError((_) {});
    return _eventStream!;
  }

  static Future<String> requestNotificationPermission() async {
    return _invokeString('requestNotificationPermission');
  }

  static Future<String> requestTrackingPermission() async {
    return _invokeString('requestTrackingPermission');
  }

  static Future<String> getTrackingStatus() async {
    return _invokeString('getTrackingStatus');
  }

  static Future<ReportLocation?> getLocation() async {
    try {
      final raw = await _methodChannel.invokeMethod<dynamic>('getLocation');
      if (raw is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(raw);
      return ReportLocation(
        province: '${map['province'] ?? ''}'.isEmpty
            ? null
            : '${map['province'] ?? ''}',
        countryCode: '${map['countryCode'] ?? ''}',
        country: '${map['country'] ?? ''}',
        street: '${map['street'] ?? ''}',
        latitude: '${map['latitude'] ?? ''}',
        longitude: '${map['longitude'] ?? ''}',
        city: '${map['city'] ?? ''}',
        permissionStatus: '${map['permissionStatus'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> getPushToken() async {
    return _invokeString('getPushToken');
  }

  static Future<SystemProxyConfig?> getSystemProxy() async {
    try {
      final raw = await _methodChannel.invokeMethod<dynamic>('getSystemProxy');
      if (raw is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(raw);
      final host = '${map['host'] ?? ''}'.trim();
      final port = int.tryParse('${map['port'] ?? ''}') ?? 0;
      final enabled = map['enabled'] == true || '${map['enabled']}' == '1';
      return SystemProxyConfig(
        host: host,
        port: port,
        isEnabled: enabled && host.isNotEmpty && port > 0,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<NativeDeviceSnapshot> getDeviceSnapshot() async {
    try {
      final raw = await _methodChannel.invokeMethod<dynamic>(
        'getDeviceSnapshot',
      );
      if (raw is! Map) {
        return _fallbackSnapshot();
      }
      final map = Map<String, dynamic>.from(raw);
      return NativeDeviceSnapshot(
        idfv: '${map['idfv'] ?? ''}',
        idfa: '${map['idfa'] ?? ''}',
        deviceId: '${map['deviceId'] ?? ''}',
        batteryLevel: '${map['batteryLevel'] ?? '0'}',
        isCharging: '${map['isCharging'] ?? '0'}',
        elapsedMillis: '${map['elapsedMillis'] ?? '0'}',
        uptimeMillis: '${map['uptimeMillis'] ?? '0'}',
        isUsingProxy: '${map['isUsingProxy'] ?? '0'}',
        isUsingVpn: '${map['isUsingVpn'] ?? '0'}',
        isJailbroken: '${map['isJailbroken'] ?? '0'}',
        isEmulator: '${map['isEmulator'] ?? '0'}',
        language: '${map['language'] ?? ''}',
        carrier: '${map['carrier'] ?? ''}',
        networkType: '${map['networkType'] ?? ''}',
        timeZoneName: '${map['timeZoneName'] ?? ''}',
        cpuCoreCount: '${map['cpuCoreCount'] ?? '0'}',
        brand: '${map['brand'] ?? ''}',
        deviceName: '${map['deviceName'] ?? ''}',
        model: '${map['model'] ?? ''}',
        osVersion: '${map['osVersion'] ?? ''}',
        screenHeight: '${map['screenHeight'] ?? '0'}',
        screenWidth: '${map['screenWidth'] ?? '0'}',
        screenSize: '${map['screenSize'] ?? '0'}',
        innerIp: '${map['innerIp'] ?? ''}',
        currentWifiName: '${map['currentWifiName'] ?? ''}',
        currentWifiBssid: '${map['currentWifiBssid'] ?? ''}',
        currentWifiMac: '${map['currentWifiMac'] ?? ''}',
        availableStorage: '${map['availableStorage'] ?? '0'}',
        totalStorage: '${map['totalStorage'] ?? '0'}',
        totalMemory: '${map['totalMemory'] ?? '0'}',
        availableMemory: '${map['availableMemory'] ?? '0'}',
        pushToken: '${map['pushToken'] ?? ''}',
        riskDeviceId: '${map['riskDeviceId'] ?? ''}',
      );
    } catch (_) {
      return _fallbackSnapshot();
    }
  }

  static Future<void> initializeAdjust(String token) async {
    try {
      await _methodChannel.invokeMethod<void>('initializeAdjust', {
        'token': token,
      });
    } catch (_) {}
  }

  static Future<String> _invokeString(String method) async {
    try {
      final result = await _methodChannel.invokeMethod<String>(method);
      return result?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static NativeDeviceSnapshot _fallbackSnapshot() {
    return NativeDeviceSnapshot(
      language: PlatformDispatcher.instance.locale.languageCode,
      timeZoneName: DateTime.now().timeZoneName,
      cpuCoreCount: '${Platform.numberOfProcessors}',
      osVersion: Platform.operatingSystemVersion,
      brand: Platform.operatingSystem,
      model: Platform.localHostname,
      deviceName: Platform.localHostname,
    );
  }
}
