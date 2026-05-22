import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sapat_cash/src/core/json/json.dart';
import 'package:sapat_cash/src/core/layout/screen.dart';

import '../../core/push/app_push.dart';
import 'webview_bridge_constants.dart';
import 'webview_bridge_dispatcher.dart';
import 'webview_bridge_models.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, required this.initialUrl, this.initialTitle});

  final String initialUrl;
  final String? initialTitle;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  static const String _bridgeHandlerName = 'ph_sapat_cash_ios';
  static const String _confirmFundsRetainPopupType = '5';

  InAppWebViewController? _controller;
  bool _loading = true;
  bool _loadFailed = false;
  bool _appForeground = true;
  bool _bridgeEnabled = false;
  late String _title;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _title = widget.initialTitle?.trim() ?? 'Loading...';
  }

  @override
  void dispose() {
    _appForeground = false;
    _syncJsBridgeState();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appForeground = state == AppLifecycleState.resumed;
    _syncJsBridgeState();
  }

  void _syncJsBridgeState() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (_appForeground == _bridgeEnabled) {
      return;
    }
    if (_appForeground) {
      controller.addJavaScriptHandler(
        handlerName: _bridgeHandlerName,
        callback: _handleJsBridgeCall,
      );
      _bridgeEnabled = true;
      return;
    }
    controller.removeJavaScriptHandler(handlerName: _bridgeHandlerName);
    _bridgeEnabled = false;
  }

  Future<dynamic> _handleJsBridgeCall(List<dynamic> arguments) async {
    if (!_appForeground || !mounted) {
      return <String, dynamic>{'ignored': true};
    }
    final raw = arguments.isNotEmpty ? arguments.first : null;
    final request = raw is String
        ? WebViewBridgeRequest.fromRawMessage(raw)
        : WebViewBridgeRequest.fromRawObject(raw);
    final result = await WebViewBridgeDispatcher.dispatch(
      context: context,
      request: request,
      goBackInWebView: _goBackInWebView,
      reloadOrOpenInWebView: _reloadOrOpenInWebView,
    );
    if (request.action != WebViewBridgeActionNames.requestCommonParams ||
        !request.expectsCallback ||
        !mounted ||
        result.code != 0 ||
        result.data.isEmpty) {
      return null;
    }

    final callbackPayload = Json({
      'callbackId': request.callbackId,
      'data': result.data,
    }).rawString();
    await _controller?.evaluateJavascript(
      source: 'window.$_bridgeHandlerName.handleMessage($callbackPayload);',
    );
    return null;
  }

  Future<bool> _goBackInWebView() async {
    final controller = _controller;
    if (controller == null) {
      return false;
    }
    if (await controller.canGoBack()) {
      await controller.goBack();
      return true;
    }
    return false;
  }

  Future<void> _reloadOrOpenInWebView(String url) async {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) {
      return;
    }
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final targetUri = await _resolveWebUri(normalizedUrl);
    if (targetUri == null) {
      return;
    }
    await controller.loadUrl(
      urlRequest: URLRequest(url: WebUri.uri(targetUri)),
    );
  }

  Future<Uri?> _resolveWebUri(String rawUrl) async {
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null) {
      return null;
    }
    if (parsed.hasScheme) {
      return parsed;
    }

    final currentUri = await _controller?.getUrl();
    if (currentUri != null) {
      return currentUri.resolveUri(parsed);
    }

    final initialUri = Uri.tryParse(widget.initialUrl.trim());
    if (initialUri != null) {
      return initialUri.resolveUri(parsed);
    }
    return parsed;
  }

  Future<void> _handleBackPressed() async {
    final currentUrl = (await _controller?.getUrl())?.toString().trim() ?? '';
    if (currentUrl.contains('Overproof')) {
      final productId = AppPush.readProductIdFromUrl(currentUrl);
      await AppPush.showRetainPopupThen(
        context,
        productId: productId,
        popupType: _confirmFundsRetainPopupType,
        onGoBack: () => AppPush.pop(context),
      );
      return;
    }
    if (await _goBackInWebView()) {
      return;
    }
    if (!mounted) {
      return;
    }
    AppPush.pop(context);
  }

  Future<NavigationActionPolicy> _handleShouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final uri = navigationAction.request.url;
    if (uri == null) {
      return NavigationActionPolicy.CANCEL;
    }
    if (_isInlineScheme(uri.scheme)) {
      return NavigationActionPolicy.ALLOW;
    }
    await AppPush.openUrlInBrowser(context, uri: uri);
    return NavigationActionPolicy.CANCEL;
  }

  bool _isInlineScheme(String scheme) {
    switch (scheme.toLowerCase()) {
      case 'http':
      case 'https':
      case 'about':
      case 'data':
      case 'javascript':
      case 'file':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _handleBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            _title.isEmpty ? 'Details' : _title,
            style: const TextStyle(color: Color(0xFF281001)),
          ),
          centerTitle: true,
          leading: GestureDetector(
            onTap: _handleBackPressed,
            child: Center(
              child: Image.asset(
                'assets/image/login_back_icon.png',
                width: screen.dp(24),
                height: screen.dp(24),
              ),
            ),
          ),
        ),
        body: _loadFailed
            ? _WebViewLoadFailed(
                onRetry: () async {
                  final uri = Uri.tryParse(widget.initialUrl.trim());
                  if (uri == null) {
                    return;
                  }
                  setState(() {
                    _loading = true;
                    _loadFailed = false;
                  });
                  await _controller?.loadUrl(
                    urlRequest: URLRequest(url: WebUri.uri(uri)),
                  );
                },
              )
            : Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri.uri(Uri.parse(widget.initialUrl.trim())),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useShouldOverrideUrlLoading: true,
                      allowsInlineMediaPlayback: true,
                      mediaPlaybackRequiresUserGesture: false,
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                      isInspectable: true,
                      useHybridComposition: true,
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                      _syncJsBridgeState();
                    },
                    onReceivedServerTrustAuthRequest:
                        (controller, challenge) async {
                          return ServerTrustAuthResponse(
                            action: ServerTrustAuthResponseAction.PROCEED,
                          );
                        },
                    onPermissionRequest: (controller, permissionRequest) async {
                      return PermissionResponse(
                        resources: permissionRequest.resources,
                        action: PermissionResponseAction.GRANT,
                      );
                    },
                    shouldOverrideUrlLoading: _handleShouldOverrideUrlLoading,
                    onLoadStart: (controller, url) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _loading = true;
                        _loadFailed = false;
                      });
                    },
                    onLoadStop: (controller, url) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _loading = false;
                      });
                    },
                    onReceivedError: (controller, request, error) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _loading = false;
                        _loadFailed = true;
                      });
                    },
                    onTitleChanged: (controller, title) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        EasyLoading.dismiss();
                        _title = (title?.trim().isNotEmpty ?? false)
                            ? title!.trim()
                            : (widget.initialTitle?.trim() ?? 'Details');
                      });
                    },
                  ),
                  if (_loading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
      ),
    );
  }
}

class _WebViewLoadFailed extends StatelessWidget {
  const _WebViewLoadFailed({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screen.dp(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: const Color(0xFF908E8C),
              size: screen.dp(36),
            ),
            SizedBox(height: screen.dp(12)),
            Text(
              'Page failed to load',
              style: TextStyle(
                color: const Color(0xFF281001),
                fontSize: screen.dp(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screen.dp(8)),
            Text(
              'Please check the network and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF908E8C),
                fontSize: screen.dp(12),
              ),
            ),
            SizedBox(height: screen.dp(20)),
            GestureDetector(
              onTap: () => onRetry(),
              child: Container(
                width: screen.dp(140),
                height: screen.dp(36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F3),
                  borderRadius: BorderRadius.circular(screen.dp(18)),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: const Color(0xFF281001),
                    fontSize: screen.dp(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
