import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sapat_cash/src/core/network/core/error_message_adapter.dart';
import 'package:sapat_cash/src/features/verification/pages/bank_account_list_page.dart';
import 'package:sapat_cash/src/features/verification/pages/bind_card_page.dart';

import '../../core/json/json.dart';
import '../../core/push/app_push.dart';
import '../../core/report/report_manager.dart';
import 'webview_bridge_constants.dart';
import 'webview_bridge_models.dart';
import '../../core/network/api/api_client.dart';

class WebViewBridgeDispatcher {
  const WebViewBridgeDispatcher._();

  static Future<WebViewBridgeResult> dispatch({
    required dynamic context,
    required WebViewBridgeRequest request,
    required Future<bool> Function() goBackInWebView,
    required Future<void> Function(String url) reloadOrOpenInWebView,
  }) async {
    try {
      switch (request.action) {
        case WebViewBridgeActionNames.uploadRiskLoan:
          final productId =
              Json(request.data['fellest']).stringOrNull?.trim() ?? '';
          final orderNo =
              Json(request.data['unsuspecting']).stringOrNull?.trim() ?? '';
          if (productId.isEmpty) {
            return WebViewBridgeResult.failure('Missing productId');
          }
          final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          ReportManager.instance.reportRiskBehavior(
            productId: productId,
            sceneType: '10',
            orderNo: orderNo,
            startTimeSeconds: nowSeconds,
          );
          return WebViewBridgeResult.success();
        case WebViewBridgeActionNames.openExternalBrowser:
          final url = _readRawUrl(request);
          if (url.isEmpty) {
            return WebViewBridgeResult.failure('Missing url');
          }
          final uri = Uri.tryParse(url);
          if (uri == null) {
            return WebViewBridgeResult.failure('Invalid url');
          }
          final opened = await AppPush.openUrlInBrowser(context, uri: uri);
          return opened
              ? WebViewBridgeResult.success()
              : WebViewBridgeResult.failure('Unable to open external browser');
        case WebViewBridgeActionNames.openScheme:
          final url = _readRawUrl(request);
          if (url.isEmpty) {
            return WebViewBridgeResult.failure('Missing scheme');
          }
          final uri = Uri.tryParse(url);
          if (uri == null) {
            return WebViewBridgeResult.failure('Invalid scheme');
          }
          final opened = await AppPush.handleInternalScheme(
            Navigator.of(context),
            uri,
          );
          return opened
              ? WebViewBridgeResult.success()
              : WebViewBridgeResult.failure('Unable to open scheme');
        case WebViewBridgeActionNames.closePage:
          AppPush.pop(context);
          return WebViewBridgeResult.success();
        case WebViewBridgeActionNames.backToHome:
          AppPush.popToHomeTabbar(context);
          return WebViewBridgeResult.success();
        case WebViewBridgeActionNames.requestCommonParams:
          final path = request.rawDataString;
          if (path.isEmpty) {
            return WebViewBridgeResult.failure('Missing path');
          }
          final mappedParams = await apiService.networkManager
              .resolveMappedCommonParams(path: path);
          return WebViewBridgeResult.success(mappedParams);
        case WebViewBridgeActionNames.toGrade:
          return WebViewBridgeResult.failure(
            'Unsupported action: toGrade',
            code: -2,
          );
        case WebViewBridgeActionNames.retryOrderDialog:
          final orderNo =
              Json(request.data['unsuspecting']).stringOrNull?.trim() ?? '';
          if (orderNo.isEmpty) {
            return WebViewBridgeResult.failure('Missing orderNo');
          }
          EasyLoading.show();
          final response = await apiService.confirmRetryOrder(orderNo: orderNo);
          final claviform = response.json['claviform'].stringValue.trim();
          EasyLoading.dismiss();
          if (claviform.isEmpty) {
            return WebViewBridgeResult.failure('Missing claviform');
          }
          await reloadOrOpenInWebView(claviform);
          return WebViewBridgeResult.success();
        case WebViewBridgeActionNames.changeAccount:
          final productId =
              Json(request.data['fellest']).stringOrNull?.trim() ?? '';
          final orderNo =
              Json(request.data['unsuspecting']).stringOrNull?.trim() ?? '';
          if (productId.isEmpty) {
            return WebViewBridgeResult.failure('Missing productId');
          }
          final response = await apiService.fetchAccountList(
            productId: productId,
          );
          final accountList = response.json['noniron'].listValue;
          if (orderNo.isEmpty) {
            return WebViewBridgeResult.failure('Missing orderNo');
          }
          final claviform = await AppPush.push<String>(
            context,
            page: accountList.isNotEmpty
                ? BankAccountListPage(productId: productId, orderNo: orderNo)
                : BindCardPage(
                    productId: productId,
                    orderNo: orderNo,
                    isChangeBankCard: true,
                  ),
            routeName: accountList.isNotEmpty
                ? BankAccountListPage.routeName
                : BindCardPage.routeName,
          );
          final normalizedUrl = claviform?.trim() ?? '';
          if (normalizedUrl.isEmpty) {
            return WebViewBridgeResult.failure('Missing claviform');
          }
          await reloadOrOpenInWebView(normalizedUrl);
          return WebViewBridgeResult.success();
        default:
          return WebViewBridgeResult.failure(
            'Unsupported action: ${request.action}',
            code: -2,
          );
      }
    } catch (error) {
      EasyLoading.dismiss();
      final message = ErrorMessageAdapter.resolve(error);
      EasyLoading.showError(message);
      return WebViewBridgeResult.failure(message);
    }
  }

  static String _readRawUrl(WebViewBridgeRequest request) {
    final mappedUrl =
        Json(
          request.data['url'] ??
              request.data['scheme'] ??
              request.data['appPkg'],
        ).stringOrNull?.trim() ??
        '';
    if (mappedUrl.isNotEmpty) {
      return mappedUrl;
    }
    return request.rawDataString;
  }
}

/*
{
"alligators": 0,
"cyanogenetic": "success",
"evaginate": {
  "noniron": [
    {
      "tutorials": 1,
      "parader": "Bank",
      "navigators": "************",
      "platinoids": [
        {
          "reads": 555,
          "dragomen": "https://pera-agad-ios-files-prod.oss-ap-southeast-6.aliyuncs.com/other/7ciqq.png",
          "subversions": 1, // 状态, 1:可用, 0:维护中, 不影响用户选择此银行卡，维护中的状态时用户依然可以选择绑定此银行卡
          "phpht": "***",
          "grewsomest": "账号",
          "turbots": {
            "auto": "a",
            "horseraces": "b",
            "deans": "c"
          },
          "entreats": 1,
          "refortification": 8
        }
      ]
    }
  ]
}
}
*/
