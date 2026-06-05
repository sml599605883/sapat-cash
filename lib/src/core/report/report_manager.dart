import 'dart:async';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_session_failure.dart';
import 'package:adjust_sdk/adjust_session_success.dart';
import 'package:sapat_cash/src/features/auth/auth_cache.dart';

import '../json/json.dart';
import '../network/api/api_client.dart';
import '../network/core/error_message_adapter.dart';
import 'report_cache.dart';
import 'report_models.dart';
import 'report_native_bridge.dart';
import 'report_payload_helper.dart';

class ReportManager {
  ReportManager._();

  static final ReportManager instance = ReportManager._();

  bool _started = false;
  bool _starting = false;
  bool _resumeHandling = false;
  bool _startupPermissionRequesting = false;
  bool _resumePermissionRequesting = false;
  bool _marketReporting = false;
  bool _pushTokenListenerAttached = false;
  String _reportingPushToken = '';
  Future<ReportLocation?>? _pendingLocationFuture;
  StreamSubscription<Json>? _nativeEventSubscription;
  bool _waitingFirstLaunchTracking = false;
  bool _adjustInitializing = false;

  Future<void> onAppStarted() async {
    if (_started || _starting) {
      return;
    }
    _starting = true;
    try {
      final isFirstLaunch = await ReportCache.markAppOpened();
      if (isFirstLaunch) {
        _waitingFirstLaunchTracking = true;
        _listenNativeEvents();
      }
      _started = true;

      unawaited(_requestStartupPermissions());
      unawaited(reportNativeLocation());
      if (!isFirstLaunch) {
        unawaited(reportGoogleMarket());
      }
      _listenPushTokenChanges();
      unawaited(reportPushToken());
    } finally {
      _starting = false;
    }
  }

  Future<void> onAppResumed() async {
    if (_resumeHandling) {
      return;
    }
    _resumeHandling = true;
    try {
      await _requestResumeTrackingPermission();
      unawaited(reportGoogleMarket());
    } finally {
      _resumeHandling = false;
    }
  }

  Future<void> onLoginSuccess() async {
    await ReportCache.setLoginAt(DateTime.now().millisecondsSinceEpoch);
    unawaited(reportGoogleMarket());
    unawaited(reportNativeLocation());
    unawaited(reportPushToken());
  }

  Future<void> reportNativeLocation() async {
    final userToken = await AuthCache.getUserToken();
    if (userToken.trim().isEmpty) {
      return;
    }
    final location = await getCurrentLocation();
    if (location == null || !location.isValid) {
      return;
    }
    try {
      await apiService.reportLocation(
        province: location.province,
        countryCode: location.countryCode,
        country: location.country,
        street: location.street,
        latitude: location.latitude,
        longitude: location.longitude,
        city: location.city,
      );
      unawaited(reportDeviceInfo());
    } catch (error) {
      unawaited(reportDeviceInfo());
      _log(error);
    }
  }

  Future<void> reportGoogleMarket() async {
    final snapshot = await ReportNativeBridge.getDeviceSnapshot();
    final signature =
        '${ReportPayloadHelper.normalize(snapshot.idfv)}|${ReportPayloadHelper.normalize(snapshot.idfa)}';
    if (signature == '|' || signature.trim().isEmpty || _marketReporting) {
      return;
    }
    if (await ReportCache.getLastMarketSignature() == signature) {
      return;
    }

    _marketReporting = true;
    try {
      final response = await apiService.reportGoogleMarket(
        idfv: snapshot.idfv,
        idfa: snapshot.idfa,
      );
      await ReportCache.setLastMarketSignature(signature);
      final token = ReportPayloadHelper.normalize(
        response.json['sociolect'].stringOrNull,
      );
      await _initializeAdjust(token);
    } catch (error) {
      _log(error);
    } finally {
      _marketReporting = false;
    }
  }

  Future<void> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required int startTimeSeconds,
  }) async {
    try {
      final endTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final snapshot = await ReportNativeBridge.getDeviceSnapshot();
      final location = await _resolveLocationWithCacheFallback();
      final payload = ReportPayloadHelper.buildRiskPayload(
        productId: productId,
        sceneType: sceneType,
        orderNo: orderNo,
        snapshot: snapshot,
        location: location,
        startTimeSeconds: startTimeSeconds,
        endTimeSeconds: endTimeSeconds,
      );
      await apiService.reportRiskBehavior(
        productId: '${payload['fellest']}',
        sceneType: '${payload['bewrapt']}',
        orderNo: '${payload['unsuspecting']}',
        riskDeviceId: '${payload['girasoles']}',
        idfa: '${payload['goopier']}',
        longitude: '${payload['antisnob']}',
        latitude: '${payload['forages']}',
        startTime: '${payload['overtops']}',
        endTime: '${payload['cornered']}',
      );
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportDeviceInfo() async {
    final userToken = await AuthCache.getUserToken();
    if (userToken.trim().isEmpty) {
      return;
    }
    try {
      final snapshot = await ReportNativeBridge.getDeviceSnapshot();
      final location = await getCurrentLocation();
      final lastLoginAt = await ReportCache.getLoginAt();
      final encrypted = await ReportPayloadHelper.buildEncryptedDevicePayload(
        snapshot: snapshot,
        location: location,
        lastLoginAtMillis: lastLoginAt,
      );
      await apiService.reportDeviceInfo(encryptedPayload: encrypted);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportContacts(String encryptedPayload) async {
    try {
      await apiService.reportContacts(encryptedPayload: encryptedPayload);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportPushToken() async {
    String token = await ReportNativeBridge.getPushToken();
    if (token.isEmpty) {
      token = await _waitPushTokenFromStream();
    }
    if (token.isEmpty) {
      return;
    }
    if (_reportingPushToken == token ||
        await ReportCache.getLastPushToken() == token) {
      return;
    }

    _reportingPushToken = token;
    try {
      await apiService.reportApplePushToken(token: token);
      await ReportCache.setLastPushToken(token);
    } catch (error) {
      _log(error);
    } finally {
      _reportingPushToken = '';
    }
  }

  Future<void> reportFaceResult(FaceReportPayload payload) async {
    try {
      await apiService.reportTongdun(
        livenessId: payload.livenessId,
        requestId: payload.requestId,
        resultCode: payload.resultCode,
        result: payload.resultMessage,
      );
    } catch (error) {
      _log(error);
    }
  }

  Future<ReportLocation?> getCurrentLocation() {
    final pending = _pendingLocationFuture;
    if (pending != null) {
      return pending;
    }
    final future = _loadCurrentLocation();
    _pendingLocationFuture = future;
    return future.whenComplete(() {
      _pendingLocationFuture = null;
    });
  }

  Future<ReportLocation?> _loadCurrentLocation() async {
    try {
      final location = await ReportNativeBridge.getLocation();
      if (location == null || !location.isValid) {
        return null;
      }
      await ReportCache.saveLocation(location);
      return location;
    } catch (error) {
      _log(error);
      return null;
    }
  }

  Future<ReportLocation?> _resolveLocationWithCacheFallback() async {
    try {
      final location = await getCurrentLocation().timeout(
        const Duration(seconds: 3),
      );
      if (location != null && location.isValid) {
        return location;
      }
    } catch (_) {}
    return ReportCache.getLocation();
  }

  Future<void> _requestStartupPermissions() async {
    if (_startupPermissionRequesting) {
      return;
    }
    _startupPermissionRequesting = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await ReportNativeBridge.requestNotificationPermission();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await ReportNativeBridge.requestTrackingPermission();
    } catch (error) {
      _log(error);
    } finally {
      _startupPermissionRequesting = false;
    }
  }

  Future<void> _requestResumeTrackingPermission() async {
    if (_resumePermissionRequesting) {
      return;
    }
    _resumePermissionRequesting = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await ReportNativeBridge.requestTrackingPermission();
    } catch (error) {
      _log(error);
    } finally {
      _resumePermissionRequesting = false;
    }
  }

  Future<void> _initializeAdjust(String token) async {
    if (token.isEmpty ||
        _adjustInitializing ||
        await ReportCache.isAdjustInitialized()) {
      return;
    }
    _adjustInitializing = true;
    try {
      final config = AdjustConfig(token, AdjustEnvironment.production);
      config.logLevel = AdjustLogLevel.info;
      config.attributionCallback = (_) {};
      config.sessionSuccessCallback = _handleAdjustSessionSuccess;
      config.sessionFailureCallback = _handleAdjustSessionFailure;
      Adjust.initSdk(config);
      await ReportCache.setAdjustInitialized(true);
      await ReportCache.setAdjustLastStatus('started');
    } catch (error) {
      await ReportCache.setAdjustLastStatus(
        'start_failed:${ErrorMessageAdapter.resolve(error)}',
      );
      _log(error);
    } finally {
      _adjustInitializing = false;
    }
  }

  void _listenPushTokenChanges() {
    if (_pushTokenListenerAttached) {
      return;
    }
    _pushTokenListenerAttached = true;
    _listenNativeEvents();
  }

  void _listenNativeEvents() {
    _nativeEventSubscription ??= ReportNativeBridge.nativeEvents().listen((
      event,
    ) {
      final type = event['type'].stringValue;
      if (type == 'tracking_status_changed' && _waitingFirstLaunchTracking) {
        final status = event['status'].stringValue.trim();
        if (status.isEmpty ||
            status == 'not_supported' ||
            status == 'not_determined') {
          return;
        }
        _waitingFirstLaunchTracking = false;
        unawaited(reportGoogleMarket());
      }
      if (type == 'push_token' &&
          ReportPayloadHelper.normalize(
            event['token'].stringOrNull,
          ).isNotEmpty) {
        unawaited(reportPushToken());
      }
    });
  }

  Future<String> _waitPushTokenFromStream() async {
    try {
      final event = await ReportNativeBridge.nativeEvents()
          .firstWhere(
            (event) =>
                event['type'].stringValue == 'push_token' &&
                ReportPayloadHelper.normalize(
                  event['token'].stringOrNull,
                ).isNotEmpty,
          )
          .timeout(const Duration(seconds: 5));
      return ReportPayloadHelper.normalize(event['token'].stringOrNull);
    } catch (_) {
      return '';
    }
  }

  void _log(Object error) {
    // Keep failures non-blocking and normalize messages through the shared adapter.
    ErrorMessageAdapter.resolve(error);
  }

  Future<void> _handleAdjustSessionSuccess(
    AdjustSessionSuccess sessionSuccess,
  ) async {
    await ReportCache.setAdjustInitialized(true);
    await ReportCache.setAdjustLastStatus(
      'session_success:${sessionSuccess.message ?? ''}',
    );
  }

  Future<void> _handleAdjustSessionFailure(
    AdjustSessionFailure sessionFailure,
  ) async {
    await ReportCache.setAdjustLastStatus(
      'session_failure:${sessionFailure.message ?? ''}',
    );
  }
}
