import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trustdevice_pro_plugin/trustdevice_pro_plugin.dart';

import '../../../app/app.dart';
import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/business_exception.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/push/app_push.dart';
import '../../../core/push/route_names.dart';
import '../../../core/report/report_manager.dart';
import '../../product/product_detail_cache.dart';
import 'identity_verification_page.dart';
import '../widgets/verification_hint_row.dart';

class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({super.key});

  static const routeName = RouteNames.faceVerification;

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  static const _retainPopupType = '1';
  final TrustdeviceProPlugin _trustdeviceProPlugin = TrustdeviceProPlugin();
  int? _scene4StartTimeSeconds;

  Future<void> _handleRetainBack() async {
    final productId = ProductDetailCache.current?.productId.trim() ?? '';
    await AppPush.showRetainPopupThen(
      context,
      productId: productId,
      popupType: _retainPopupType,
      onGoBack: () => AppPush.pop(context),
    );
  }

  @override
  void initState() {
    super.initState();
    _initTrustDevice();
  }

  Future<void> _initTrustDevice() async {
    try {
      await _trustdeviceProPlugin.initWithOptions({
        'partner': 'boqin_ph',
        'appKey': '1dc25522f2adc77f5347816c0f7fa31b',
        'appName': 'julyTwo_test',
        'country': 'sg',
        'language': 'en',
      });
    } catch (error) {
      debugPrint('trustdevice_pro_plugin init failed: $error');
    }
  }

  Future<void> _onNextPressed() async {
    _scene4StartTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final allowed = await _ensureCameraPermission();
    if (!allowed) {
      return;
    }
    await _startFaceVerification();
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    final goToSettings =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('需要相机权限'),
              content: const Text('请前往设置开启相机权限后继续。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('去设置'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (goToSettings) {
      await openAppSettings();
    }
    return false;
  }

  Future<void> _startFaceVerification() async {
    final orderNo = ProductDetailCache.current?.orderNo.trim() ?? '';
    if (orderNo.isEmpty) {
      EasyLoading.showToast('Missing order information');
      return;
    }

    EasyLoading.show();
    try {
      final response = await apiService.fetchFaceToken(
        orderNo: orderNo,
        type: '0',
      );
      final payload = response.json;
      final sirras = payload['sirras'].intOrNull ?? 0;
      if (sirras == 400) {
        EasyLoading.dismiss();
        await _showReuploadDialog();
        return;
      }
      if (sirras == 500) {
        final procural =
            payload['procural'].stringOrNull?.trim() ?? 'Request failed';
        throw BusinessException(procural, code: sirras);
      }

      final license = payload['stolport'].stringValue;
      if (license.isEmpty) {
        throw const BusinessException('Missing face token');
      }

      await _trustdeviceProPlugin.showLiveness(
        license,
        TDLivenessCallback(
          onSuccess: (successResultMap) async {
            debugPrint('showLiveness success: $successResultMap');
            final productId =
                ProductDetailCache.current?.productId.trim() ?? '';
            if (productId.isEmpty || !mounted) {
              return;
            }
            final livenessId =
                successResultMap['liveness_id']?.toString().trim() ?? '';
            final image = successResultMap['image']?.toString().trim() ?? '';
            await _uploadFaceResult(
              livenessId: livenessId,
              license: license,
              image: image,
            );
            ReportManager.instance.reportRiskBehavior(
              productId: productId,
              sceneType: '4',
              orderNo: ProductDetailCache.current?.orderNo.trim() ?? '',
              startTimeSeconds:
                  _scene4StartTimeSeconds ??
                  DateTime.now().millisecondsSinceEpoch ~/ 1000,
            );
            await _continueToNextStep(productId);
          },
          onFailed: (failResultMap) {
            debugPrint('showLiveness failed: $failResultMap');
            final message =
                failResultMap['message'].toString().trim().isNotEmpty
                ? failResultMap['message'].toString().trim()
                : 'Face verification failed';
            EasyLoading.showToast(message);
          },
        ),
      );
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _uploadFaceResult({
    required String livenessId,
    required String license,
    required String image,
  }) async {
    final imageFilePath = await _writeBase64ImageToTempFile(image);
    await apiService.uploadIdentityAsset(
      type: '10',
      imageSource: '1',
      cardType: '',
      bizTokenOrLivenessId: livenessId,
      authCode: license,
      faceType: '7',
      filePath: imageFilePath,
    );
  }

  Future<String> _writeBase64ImageToTempFile(String image) async {
    final normalized = image.trim();
    if (normalized.isEmpty) {
      throw const BusinessException('Missing liveness image');
    }

    final base64Body = normalized.contains(',')
        ? normalized.substring(normalized.indexOf(',') + 1)
        : normalized;
    final bytes = base64Decode(base64Body);
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/face_liveness_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _continueToNextStep(String productId) async {
    final currentContext = SapatCashApp.navigatorKey.currentContext;
    if (currentContext == null) {
      return;
    }
    await AppPush.productDetail(currentContext, productId: productId);
  }

  Future<void> _showReuploadDialog() async {
    if (!mounted) {
      return;
    }
    final goUpload =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('提示'),
              content: const Text('需要重新上传身份证照片，请重新上传后再继续。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('去上传'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!goUpload || !mounted) {
      return;
    }

    final productId = ProductDetailCache.current?.productId.trim() ?? '';
    if (productId.isEmpty) {
      return;
    }
    await AppPush.pushAndRemoveRoutes(
      context,
      page: IdentityVerificationPage(productId: productId),
      routeName: RouteNames.identityVerification,
      removeRouteNames: const [
        RouteNames.faceVerification,
        RouteNames.identityVerification,
        RouteNames.idUploadDemo,
        RouteNames.identityUploadSuccess,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final hintMessage =
        ProductDetailCache.current?.temporalize.faceHint.trim() ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screen.dp(72),
            screen.dp(12),
            screen.dp(72),
            screen.dp(34),
          ),
          child: _PrimaryButton(label: 'Next', onTap: _onNextPressed),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            screen.dp(16),
            screen.dp(15),
            screen.dp(16),
            screen.dp(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: _handleRetainBack),
              SizedBox(height: screen.dp(16)),
              VerificationHintRow(message: hintMessage),
              SizedBox(height: screen.dp(37)),
              Center(
                child: Image.asset(
                  'assets/image/verification/face_demo_preview.png',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return SizedBox(
      height: screen.dp(48),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                'assets/image/login_back_icon.png',
                width: screen.dp(24),
                height: screen.dp(24),
              ),
            ),
          ),
          Text(
            'ID Verification',
            style: TextStyle(
              color: const Color(0xFF281001),
              fontSize: screen.dp(20),
              height: 24 / 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: screen.dp(232),
        height: screen.dp(48),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF89350), Color(0xFFF45834)],
          ),
          borderRadius: BorderRadius.circular(screen.dp(24)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: screen.dp(16),
            height: 20 / 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
