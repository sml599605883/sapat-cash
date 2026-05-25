import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sapat_cash/src/core/report/report_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app.dart';
import '../../core/network/api/api_client.dart';
import '../../core/network/core/business_exception.dart';
import '../../core/network/core/error_message_adapter.dart';
import '../../core/report/report_native_bridge.dart';
import '../../features/common/permission_prompt_dialog.dart';
import '../../features/common/retain_popup_dialog.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_page.dart';
import '../../features/main_tab/main_tab_controller.dart';
import '../../features/mine/account_page.dart';
import '../../features/product/product_detail_model.dart';
import '../../features/recredit/waiting_credit_page.dart';
import '../../features/verification/pages/bind_card_page.dart';
import '../../features/verification/pages/contact_information_page.dart';
import '../../features/verification/pages/face_verification_page.dart';
import '../../features/verification/pages/identity_verification_page.dart';
import '../../features/verification/pages/personal_information_page.dart';
import '../../features/verification/pages/work_information_page.dart';
import '../../features/web/webview_page.dart';
import 'route_names.dart';

final class AppPush {
  const AppPush._();

  static final NavigatorObserver navigatorObserver = _AppPushRouteObserver();
  static const List<String> _verificationFlowRouteSequence = <String>[
    RouteNames.identityVerification,
    RouteNames.idUploadDemo,
    RouteNames.identityUploadSuccess,
    RouteNames.faceVerification,
    RouteNames.personalInformation,
    RouteNames.workInformation,
    RouteNames.contactInformation,
    RouteNames.bindCard,
    RouteNames.webView,
    RouteNames.waitingCredit,
  ];

  // Centralized page push entry. Default to the project's iOS-style slide route.
  static Future<T?> push<T>(
    BuildContext context, {
    required Widget page,
    String? routeName,
  }) {
    return pushWithNavigator<T>(
      Navigator.of(context),
      page: page,
      routeName: routeName,
    );
  }

  static Future<T?> pushWithNavigator<T>(
    NavigatorState navigator, {
    required Widget page,
    String? routeName,
  }) {
    return navigator.push<T>(_buildPushRoute(page, routeName: routeName));
  }

  static Future<T?> replace<T, TO>(
    BuildContext context, {
    required Widget page,
    String? routeName,
    TO? result,
  }) {
    return replaceWithNavigator<T, TO>(
      Navigator.of(context),
      page: page,
      routeName: routeName,
      result: result,
    );
  }

  static Future<T?> replaceWithNavigator<T, TO>(
    NavigatorState navigator, {
    required Widget page,
    String? routeName,
    TO? result,
  }) {
    return navigator.pushReplacement<T, TO>(
      _buildPushRoute(page, routeName: routeName),
      result: result,
    );
  }

  static Future<T?> replaceAll<T>(
    BuildContext context, {
    required Widget page,
    String? routeName,
  }) {
    return replaceAllWithNavigator<T>(
      Navigator.of(context),
      page: page,
      routeName: routeName,
    );
  }

  static Future<T?> replaceAllWithNavigator<T>(
    NavigatorState navigator, {
    required Widget page,
    String? routeName,
  }) {
    return navigator.pushAndRemoveUntil<T>(
      _buildPushRoute(page, routeName: routeName),
      (route) => false,
    );
  }

  // Push target page first, then prune matched history routes from the stack.
  // Example: A -> B -> C, call this when navigating C -> D with [B, C],
  // then returning from D will go straight back to A.
  static Future<T?> pushAndRemoveRoutes<T>(
    BuildContext context, {
    required Widget page,
    String? routeName,
    required List<String> removeRouteNames,
  }) {
    return pushAndRemoveRoutesWithNavigator<T>(
      Navigator.of(context),
      page: page,
      routeName: routeName,
      removeRouteNames: removeRouteNames,
    );
  }

  static Future<T?> pushAndRemoveRoutesWithNavigator<T>(
    NavigatorState navigator, {
    required Widget page,
    String? routeName,
    required List<String> removeRouteNames,
  }) {
    final normalizedNames = _normalizeRouteNames(removeRouteNames);
    final PageRoute<T> route = _buildPushRoute<T>(page, routeName: routeName);
    final future = navigator.push<T>(route);
    if (normalizedNames.isEmpty) {
      return future;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeRoutesWithNavigator(
        navigator,
        normalizedNames.toList(growable: false),
        except: route,
      );
    });
    return future;
  }

  static Future<T?> pushLogin<T>(BuildContext context) {
    return pushLoginWithNavigator<T>(Navigator.of(context));
  }

  static Future<T?> pushLoginWithNavigator<T>(NavigatorState navigator) {
    return pushWithNavigator<T>(
      navigator,
      page: const LoginPage(),
      routeName: RouteNames.login,
    );
  }

  static Future<T?> pushAccount<T>(BuildContext context) {
    return push<T>(
      context,
      page: const AccountPage(),
      routeName: RouteNames.account,
    );
  }

  static Future<T?> pushAccountWithNavigator<T>(NavigatorState navigator) {
    return pushWithNavigator<T>(
      navigator,
      page: const AccountPage(),
      routeName: RouteNames.account,
    );
  }

  static Future<T?> pushWebView<T>(
    BuildContext context, {
    required String url,
    String? title,
  }) {
    return pushWebViewWithNavigator<T>(
      Navigator.of(context),
      url: url,
      title: title,
    );
  }

  static Future<T?> pushWebViewWithNavigator<T>(
    NavigatorState navigator, {
    required String url,
    String? title,
  }) {
    return pushWithNavigator<T>(
      navigator,
      page: WebViewPage(initialUrl: url, initialTitle: title),
      routeName: RouteNames.webView,
    );
  }

  static Future<T?> pushIdentityVerification<T>(
    BuildContext context, {
    required String productId,
  }) {
    return push<T>(
      context,
      page: IdentityVerificationPage(productId: productId),
      routeName: RouteNames.identityVerification,
    );
  }

  static Future<T?> pushWaitingCredit<T>(
    BuildContext context, {
    required String productId,
  }) {
    return push<T>(
      context,
      page: WaitingCreditPage(productId: productId),
      routeName: RouteNames.waitingCredit,
    );
  }

  static Future<void> productDetail(
    BuildContext context, {
    required String productId,
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }

    EasyLoading.show();
    try {
      final response = await apiService.productDetail(
        productId: normalizedProductId,
      );
      await _handleProductDetailLanding(response.data);
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  static Future<void> clickApply(
    BuildContext context, {
    required String productId,
    String? apiremind,
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }

    final navigator = Navigator.of(context);
    final authController = navigator.context.read<AuthController>();
    await authController.ensureInitialized();
    if (!authController.isLoggedIn) {
      await pushLoginWithNavigator(navigator);
      return;
    }
    final canContinue = await _ensureLocationAccessForApply();
    if (!canContinue) {
      return;
    }

    ReportManager.instance.reportNativeLocation();
    EasyLoading.show();
    try {
      final response = await apiService.clickApply(
        productId: normalizedProductId,
        apiremind: apiremind,
      );
      final responseJson = response.json;
      // Backend may return either a direct landing url or a signal to fetch
      // the next in-app verification step from product detail again.
      final oreides = responseJson['oreides'].stringOrNull?.trim() ?? '';
      if (oreides.isNotEmpty) {
        final opened = await openWebUriWithNavigator(
          navigator,
          rawUrl: oreides,
        );
        if (!opened) {
          throw const BusinessException('Unable to open link');
        }
        return;
      }

      final earphone = responseJson['earphone'].intOrNull ?? 0;
      if (earphone == 200) {
        final detailResponse = await apiService.productDetail(
          productId: normalizedProductId,
        );
        await _handleProductDetailLanding(detailResponse.data);
        return;
      }

      final bulldogged = responseJson['bulldogged'].stringOrNull?.trim() ?? '';
      throw BusinessException(
        bulldogged.isNotEmpty ? bulldogged : 'Request failed',
      );
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  static void popToHomeTabbar(BuildContext context, {bool refreshHome = true}) {
    context.read<MainTabController>().switchToHome(refresh: refreshHome);
    popUntilRouteName(context, RouteNames.mainTab);
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      return;
    }
    navigator.pop<T>(result);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentContext = SapatCashApp.navigatorKey.currentContext;
      if (currentContext == null) {
        return;
      }
      final currentRouteName = AppPush.currentRouteName();
      if (currentRouteName != RouteNames.mainTab) {
        return;
      }
      final mainTabController = currentContext.read<MainTabController>();
      if (mainTabController.currentIndex == 0) {
        mainTabController.switchToHome(refresh: true);
      }
    });
  }

  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  static void popUntilRouteName(BuildContext context, String routeName) {
    final normalized = routeName.trim();
    if (normalized.isEmpty) {
      return;
    }
    Navigator.of(
      context,
    ).popUntil((route) => (route.settings.name?.trim() ?? '') == normalized);
  }

  static void popUntilOneOf(BuildContext context, List<String> routeNames) {
    final normalizedNames = _normalizeRouteNames(routeNames);
    if (normalizedNames.isEmpty) {
      return;
    }
    Navigator.of(context).popUntil(
      (route) => normalizedNames.contains(route.settings.name?.trim() ?? ''),
    );
  }

  static void removeRoutes(BuildContext context, List<String> routeNames) {
    _removeRoutesWithNavigator(Navigator.of(context), routeNames);
  }

  static Future<void> showRetainPopupThen(
    BuildContext context, {
    required String productId,
    required String popupType,
    required VoidCallback onGoBack,
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      onGoBack();
      return;
    }

    try {
      final response = await apiService.fetchRetainPopup(
        popupType: popupType,
        productId: normalizedProductId,
      );
      final haem = response.json['haem'];
      final imageUrl = haem['oreides'].stringValue.trim();
      if (imageUrl.isEmpty) {
        onGoBack();
        return;
      }

      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x80000000),
        builder: (dialogContext) {
          return RetainPopupDialog(
            imageUrl: imageUrl,
            onGoBack: () {
              Navigator.of(dialogContext).pop();
              onGoBack();
            },
            onGetFunds: () {
              Navigator.of(dialogContext).pop();
            },
          );
        },
      );
    } catch (_) {
      onGoBack();
    }
  }

  // Debug/helper API for checking the tracked navigator stack by route name.
  static List<String> routeStackNames() {
    final observer = navigatorObserver;
    if (observer is! _AppPushRouteObserver) {
      return const <String>[];
    }
    return observer.routes
        .map((route) => route.settings.name?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  static String? currentRouteName() {
    final names = routeStackNames();
    if (names.isEmpty) {
      return null;
    }
    return names.last;
  }

  static PageRoute<T> _buildPushRoute<T>(Widget page, {String? routeName}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Match the product's native-like push feeling:
        // incoming page slides in from right while current page shifts slightly left.
        final primaryPosition = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
        final secondaryPosition =
            Tween<Offset>(begin: Offset.zero, end: const Offset(-0.18, 0))
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(secondaryAnimation);

        return SlideTransition(
          position: primaryPosition,
          child: SlideTransition(position: secondaryPosition, child: child),
        );
      },
    );
  }

  static void _removeRoutesWithNavigator(
    NavigatorState navigator,
    List<String> routeNames, {
    Route<dynamic>? except,
  }) {
    final observer = navigatorObserver;
    if (observer is! _AppPushRouteObserver) {
      return;
    }
    final normalizedNames = _normalizeRouteNames(routeNames);
    if (normalizedNames.isEmpty) {
      return;
    }
    final removableRoutes = observer.routes
        .where(
          (item) =>
              item != except &&
              normalizedNames.contains(item.settings.name?.trim() ?? ''),
        )
        .toList(growable: false);
    for (final item in removableRoutes) {
      navigator.removeRoute(item);
    }
  }

  static Future<void> _handleProductDetailLanding(
    ProductDetailModel? detail,
  ) async {
    if (detail == null) {
      return;
    }

    if (detail.profiteers.isNull()) {
      await _openOrderLandingByDetail(detail);
      return;
    }

    final derms = detail.profiteers['derms'].stringOrNull?.trim() ?? '';
    // `derms` is the backend-driven next-step marker for the apply flow.
    await _handleProfiteersDerms(detail, derms);
  }

  static Future<void> _handleProfiteersDerms(
    ProductDetailModel detail,
    String derms,
  ) async {
    final currentContext = SapatCashApp.navigatorKey.currentContext;
    if (currentContext == null) {
      return;
    }

    switch (derms) {
      case 'UnravishedOrderable':
        await pushIdentityVerification(
          currentContext,
          productId: detail.productId,
        );
        return;
      case 'AsunderSabir':
        EasyLoading.dismiss();
        await _pushVerificationFlowStep(
          currentContext,
          page: const FaceVerificationPage(),
          routeName: RouteNames.faceVerification,
        );
        return;
      case 'Liquidating':
        await _pushVerificationFlowStep(
          currentContext,
          page: PersonalInformationPage(productId: detail.productId),
          routeName: RouteNames.personalInformation,
        );
        return;
      case 'AtrophyAlertest':
        await _pushVerificationFlowStep(
          currentContext,
          page: WorkInformationPage(productId: detail.productId),
          routeName: RouteNames.workInformation,
        );
        return;
      case 'InwardnessCapturer':
        await _pushVerificationFlowStep(
          currentContext,
          page: ContactInformationPage(productId: detail.productId),
          routeName: RouteNames.contactInformation,
        );
        return;
      case 'Cakewalked':
        await _pushVerificationFlowStep(
          currentContext,
          page: BindCardPage(
            productId: detail.productId,
            orderNo: detail.orderNo,
          ),
          routeName: RouteNames.bindCard,
        );
        return;
      default:
        return;
    }
  }

  static Future<void> _openOrderLandingByDetail(
    ProductDetailModel detail,
  ) async {
    final currentContext = SapatCashApp.navigatorKey.currentContext;
    if (currentContext == null) {
      return;
    }
    final navigator = Navigator.of(currentContext);

    final orderNo = detail.orderNo.trim();
    if (orderNo.isEmpty) {
      return;
    }

    final scene9StartTimeSeconds =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final response = await apiService.fetchOrderLandingUrl(
      orderNo: orderNo,
      amount: detail.amount.trim(),
      loanTerm: detail.fieldstone.trim(),
      loanTermType: '${detail.nonbiological}',
    );
    ReportManager.instance.reportRiskBehavior(
      productId: detail.productId.trim(),
      sceneType: '9',
      orderNo: orderNo,
      startTimeSeconds: scene9StartTimeSeconds,
    );
    final oreides = response.json['oreides'].stringOrNull?.trim() ?? '';
    if (oreides.isEmpty) {
      return;
    }

    final opened = await openWebUriWithNavigator(navigator, rawUrl: oreides);
    if (!opened) {
      throw const BusinessException('Unable to open link');
    }
  }

  static Future<bool> _ensureLocationAccessForApply() async {
    final location = await ReportNativeBridge.getLocation();
    if (location != null && location.isValid) {
      return true;
    }

    final serviceStatus = await Permission.locationWhenInUse.serviceStatus;
    if (serviceStatus != ServiceStatus.enabled) {
      final context = SapatCashApp.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        return false;
      }
      final goToService = await _showPermissionPromptDialog(
        context,
        title: 'Location service required',
        content:
            'Device location service is turned off. Turn it on to improve risk control and service delivery.',
        cancelText: 'Cancel',
        confirmText: 'Location Service',
      );
      if (goToService) {
        await openAppSettings();
        return false;
      }
      return true;
    }

    final context = SapatCashApp.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return false;
    }
    final goToSettings = await _showPermissionPromptDialog(
      context,
      title: 'Location permission required',
      content: 'Please allow location access in Settings to continue.',
      cancelText: 'Cancel',
      confirmText: 'Settings',
    );
    if (goToSettings) {
      await openAppSettings();
      return false;
    }
    return true;
  }

  static Future<bool> _showPermissionPromptDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String cancelText,
    required String confirmText,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return PermissionPromptDialog(
              title: title,
              content: content,
              cancelText: cancelText,
              confirmText: confirmText,
            );
          },
        ) ??
        false;
  }

  static Future<void> _pushVerificationFlowStep(
    BuildContext context, {
    required Widget page,
    required String routeName,
  }) {
    return pushAndRemoveRoutes(
      context,
      page: page,
      routeName: routeName,
      removeRouteNames: _verificationFlowHistoryBefore(routeName),
    );
  }

  static List<String> _verificationFlowHistoryBefore(String routeName) {
    final normalizedRouteName = routeName.trim();
    final routeIndex = _verificationFlowRouteSequence.indexOf(
      normalizedRouteName,
    );
    if (routeIndex <= 0) {
      return const <String>[];
    }
    return _verificationFlowRouteSequence
        .take(routeIndex)
        .toList(growable: false);
  }

  static Set<String> _normalizeRouteNames(Iterable<String> routeNames) {
    return routeNames
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static Future<bool> openWebPage(
    BuildContext context, {
    required String rawUrl,
    String? title,
  }) {
    return openWebUriWithNavigator(
      Navigator.of(context),
      rawUrl: rawUrl,
      title: title,
    );
  }

  static Future<bool> openUrlInBrowser(
    BuildContext context, {
    required Uri uri,
  }) {
    return openUrlInBrowserWithNavigator(Navigator.of(context), uri: uri);
  }

  static Future<bool> openWebUriWithNavigator(
    NavigatorState navigator, {
    Uri? uri,
    String? rawUrl,
    String? title,
  }) async {
    final resolvedUri = uri ?? _tryParseUri(rawUrl ?? '');
    if (resolvedUri == null) {
      return false;
    }
    if (await handleInternalScheme(navigator, resolvedUri)) {
      return true;
    }
    if (_shouldOpenInWebView(resolvedUri)) {
      await pushAndRemoveRoutesWithNavigator(
        navigator,
        page: WebViewPage(
          initialUrl: resolvedUri.toString(),
          initialTitle: title,
        ),
        routeName: RouteNames.webView,
        removeRouteNames: _verificationFlowRouteSequence,
      );
      return true;
    }
    return openExternalUri(resolvedUri);
  }

  static Future<bool> openUrlInBrowserWithNavigator(
    NavigatorState navigator, {
    required Uri uri,
  }) async {
    if (await handleInternalScheme(navigator, uri)) {
      return true;
    }
    return openExternalUri(uri);
  }

  static Future<bool> openExternalUri(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> handleInternalScheme(
    NavigatorState navigator,
    Uri uri,
  ) async {
    if (!_isInternalAppUri(uri)) {
      return false;
    }

    final routeSegments = _normalizedPathSegments(uri).skip(1).toList();
    if (routeSegments.isEmpty) {
      return false;
    }

    final mainTabController = navigator.context.read<MainTabController>();
    final target = routeSegments.first.trim();

    switch (target) {
      case 'PhenologiesCommunicative':
        mainTabController.switchToHome(refresh: true);
        return true;
      case 'TennisGametogenic':
        await pushAccountWithNavigator(navigator);
        return true;
      case 'ConsumeRunny':
        await pushLoginWithNavigator(navigator);
        return true;
      case 'SalpiansDemyelination':
        return _handleInternalProductRoute(
          navigator,
          uri,
          action: (productId) {
            return productDetail(navigator.context, productId: productId);
          },
        );
      case 'QuixotismVallate':
        return _handleInternalProductRoute(
          navigator,
          uri,
          beforeAction: EasyLoading.dismiss,
          action: (productId) {
            return pushWaitingCredit(navigator.context, productId: productId);
          },
        );
      case 'Connoted':
        return _handleInternalProductRoute(
          navigator,
          uri,
          action: (productId) {
            return clickApply(navigator.context, productId: productId);
          },
        );
      case 'DisavowalsSnuggeries':
        final balsamic = _readBalsamicFromUri(uri);
        if (balsamic.isEmpty) {
          return false;
        }
        debugPrint('order list type: $balsamic');
        return true;
      default:
        return false;
    }
  }

  static Future<bool> _handleInternalProductRoute(
    NavigatorState navigator,
    Uri uri, {
    VoidCallback? beforeAction,
    required Future<void> Function(String productId) action,
  }) async {
    final productId = _readProductIdFromUri(uri);
    if (productId.isEmpty) {
      return false;
    }
    beforeAction?.call();
    await action(productId);
    return true;
  }

  static String _readProductIdFromUri(Uri uri) {
    const keys = ['productId', 'silken', 'fellest'];

    final directValue = _readFirstNonEmptyQueryValue(uri, keys);
    if (directValue.isNotEmpty) {
      return directValue;
    }

    final fragment = uri.fragment.trim();
    if (fragment.isNotEmpty) {
      final fragmentUri = Uri.tryParse(
        fragment.contains('?') ? fragment : '/?$fragment',
      );
      if (fragmentUri != null) {
        final fragmentValue = _readFirstNonEmptyQueryValue(fragmentUri, keys);
        if (fragmentValue.isNotEmpty) {
          return fragmentValue;
        }
      }
    }

    final pathSegments = uri.pathSegments.reversed.map((item) => item.trim());
    for (final segment in pathSegments) {
      if (segment.isNotEmpty && !segment.contains('=')) {
        return segment;
      }
    }

    return '';
  }

  static String readProductIdFromUrl(String rawUrl) {
    final normalizedUrl = rawUrl.trim();
    if (normalizedUrl.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(normalizedUrl);
    if (uri != null) {
      final directProductId = _readProductIdFromUri(uri);
      if (directProductId.isNotEmpty) {
        return directProductId;
      }

      final fragment = uri.fragment.trim();
      if (fragment.isNotEmpty) {
        final fragmentProductId = readProductIdFromUrl(fragment);
        if (fragmentProductId.isNotEmpty) {
          return fragmentProductId;
        }
      }
    }

    const keys = ['productId', 'silken', 'braciole', 'fellest'];
    for (final key in keys) {
      final patterns = ['?$key=', '&$key=', '#$key='];
      for (final pattern in patterns) {
        final start = normalizedUrl.indexOf(pattern);
        if (start < 0) {
          continue;
        }
        final valueStart = start + pattern.length;
        final tail = normalizedUrl.substring(valueStart);
        var nextSeparatorIndex = -1;
        for (final separator in ['&', '#', '/']) {
          final separatorIndex = tail.indexOf(separator);
          if (separatorIndex < 0) {
            continue;
          }
          if (nextSeparatorIndex < 0 || separatorIndex < nextSeparatorIndex) {
            nextSeparatorIndex = separatorIndex;
          }
        }
        final rawValue = nextSeparatorIndex >= 0
            ? tail.substring(0, nextSeparatorIndex)
            : tail;
        final decodedValue = Uri.decodeComponent(rawValue).trim();
        if (decodedValue.isNotEmpty) {
          return decodedValue;
        }
      }
    }

    return '';
  }

  static String _readBalsamicFromUri(Uri uri) {
    const keys = ['balsamic', 'type'];
    return _readFirstNonEmptyQueryValue(uri, keys);
  }

  static bool _shouldOpenInWebView(Uri uri) {
    final scheme = uri.scheme.trim().toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  static Uri? _tryParseUri(String rawUrl) {
    final normalizedUrl = rawUrl.trim();
    if (normalizedUrl.isEmpty) {
      return null;
    }
    return Uri.tryParse(normalizedUrl);
  }

  static bool _isInternalAppUri(Uri uri) {
    final scheme = uri.scheme.trim().toLowerCase();
    final host = uri.host.trim().toLowerCase();
    final pathSegments = _normalizedPathSegments(uri);
    return scheme == 'ph' &&
        host == 'sapat-cash' &&
        pathSegments.isNotEmpty &&
        pathSegments.first.toLowerCase() == 'ios';
  }

  static List<String> _normalizedPathSegments(Uri uri) {
    return uri.pathSegments
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
  }

  static String _readFirstNonEmptyQueryValue(Uri uri, List<String> keys) {
    for (final key in keys) {
      final value = uri.queryParameters[key]?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}

final class _AppPushRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _routes = <Route<dynamic>>[];

  List<Route<dynamic>> get routes => List.unmodifiable(_routes);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
