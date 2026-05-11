import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../json/json.dart';
import '../network/debug/network_proxy_manager.dart';
import 'report_models.dart';

class ReportNativeBridge {
  ReportNativeBridge._();

  static const _methodChannel = MethodChannel('sapat_cash/report_method');
  static const _eventChannel = EventChannel('sapat_cash/report_event');

  static Stream<Json>? _eventStream;

  static Stream<Json> nativeEvents() {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Json(event))
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
      final json = Json(
        await _methodChannel.invokeMethod<dynamic>('getLocation'),
      );
      if (json.mapOrNull == null) {
        return null;
      }
      return ReportLocation(
        province: json['province'].stringValue.isEmpty
            ? null
            : json['province'].stringValue,
        countryCode: json['countryCode'].stringValue,
        country: json['country'].stringValue,
        street: json['street'].stringValue,
        latitude: json['latitude'].stringValue,
        longitude: json['longitude'].stringValue,
        city: json['city'].stringValue,
        permissionStatus: json['permissionStatus'].stringValue,
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
      final json = Json(
        await _methodChannel.invokeMethod<dynamic>('getSystemProxy'),
      );
      if (json.mapOrNull == null) {
        return null;
      }
      final host = json['host'].stringValue.trim();
      final port = json['port'].intValue;
      final enabled = json['enabled'].boolValue;
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
      final json = Json(
        await _methodChannel.invokeMethod<dynamic>('getDeviceSnapshot'),
      );
      if (json.mapOrNull == null) {
        return _fallbackSnapshot();
      }
      return NativeDeviceSnapshot(
        idfv: json['idfv'].stringValue,
        idfa: json['idfa'].stringValue,
        deviceId: json['deviceId'].stringValue,
        batteryLevel: json['batteryLevel'].stringOrNull ?? '0',
        isCharging: json['isCharging'].stringOrNull ?? '0',
        elapsedMillis: json['elapsedMillis'].stringOrNull ?? '0',
        uptimeMillis: json['uptimeMillis'].stringOrNull ?? '0',
        isUsingProxy: json['isUsingProxy'].stringOrNull ?? '0',
        isUsingVpn: json['isUsingVpn'].stringOrNull ?? '0',
        isJailbroken: json['isJailbroken'].stringOrNull ?? '0',
        isEmulator: json['isEmulator'].stringOrNull ?? '0',
        language: json['language'].stringValue,
        carrier: json['carrier'].stringValue,
        networkType: json['networkType'].stringValue,
        timeZoneName: json['timeZoneName'].stringValue,
        cpuCoreCount: json['cpuCoreCount'].stringOrNull ?? '0',
        brand: json['brand'].stringValue,
        deviceName: json['deviceName'].stringValue,
        model: json['model'].stringValue,
        osVersion: json['osVersion'].stringValue,
        screenHeight: json['screenHeight'].stringOrNull ?? '0',
        screenWidth: json['screenWidth'].stringOrNull ?? '0',
        screenSize: json['screenSize'].stringOrNull ?? '0',
        innerIp: json['innerIp'].stringValue,
        currentWifiName: json['currentWifiName'].stringValue,
        currentWifiBssid: json['currentWifiBssid'].stringValue,
        currentWifiMac: json['currentWifiMac'].stringValue,
        availableStorage: json['availableStorage'].stringOrNull ?? '0',
        totalStorage: json['totalStorage'].stringOrNull ?? '0',
        totalMemory: json['totalMemory'].stringOrNull ?? '0',
        availableMemory: json['availableMemory'].stringOrNull ?? '0',
        pushToken: json['pushToken'].stringValue,
        riskDeviceId: json['riskDeviceId'].stringValue,
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
