import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/push/app_push.dart';
import '../../../core/push/route_names.dart';
import '../../product/product_detail_cache.dart';
import 'identity_upload_success_page.dart';
import '../widgets/verification_hint_row.dart';

class IdUploadDemoPage extends StatefulWidget {
  const IdUploadDemoPage({super.key, required this.documentType});

  static const routeName = RouteNames.idUploadDemo;

  final String documentType;

  @override
  State<IdUploadDemoPage> createState() => _IdUploadDemoPageState();
}

class _IdUploadDemoPageState extends State<IdUploadDemoPage> {
  static const List<String> _uploadOptions = ['Camera', 'Album'];

  final ImagePicker _imagePicker = ImagePicker();
  String _selectedUploadOption = _uploadOptions.first;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final hintMessage =
        ProductDetailCache.current?.temporalize.identityHint.trim() ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screen.dp(16),
            screen.dp(15),
            screen.dp(16),
            screen.dp(34),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: () => Navigator.of(context).maybePop()),
              SizedBox(height: screen.dp(16)),
              VerificationHintRow(message: hintMessage),
              SizedBox(height: screen.dp(26)),
              _PreviewCard(),
              const Spacer(),
              Center(
                child: _PrimaryButton(
                  label: 'Submit',
                  onTap: _showDocumentTypeSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDocumentTypeSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _DocumentTypeSheet(
          title: widget.documentType,
          options: _uploadOptions,
          selectedValue: _selectedUploadOption,
        );
      },
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _selectedUploadOption = selected;
    });
    await _pickImage(selected);
  }

  Future<void> _pickImage(String option) async {
    final source = option == 'Album' ? ImageSource.gallery : ImageSource.camera;
    if (source == ImageSource.camera) {
      final allowed = await _ensureCameraPermission();
      if (!allowed) {
        return;
      }
    }
    EasyLoading.show();
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (!mounted || pickedFile == null) {
      return;
    }
    final compressedFile = await _compressToLimit(File(pickedFile.path));
    if (!mounted || compressedFile == null) {
      return;
    }
    await _uploadCompressedImage(compressedFile, option);
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!mounted) {
        return false;
      }
      final goToSettings =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Camera permission required'),
                content: const Text(
                  'Please allow camera access in Settings to continue.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Settings'),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!goToSettings) {
        return false;
      }
      await openAppSettings();
      return false;
    }

    final requestStatus = await Permission.camera.request();
    return requestStatus.isGranted;
  }

  Future<void> _uploadCompressedImage(File imageFile, String option) async {
    EasyLoading.show();
    try {
      final response = await apiService.uploadIdentityAsset(
        type: '11',
        imageSource: _mapImageSource(option),
        cardType: widget.documentType.trim(),
        filePath: imageFile.path,
      );
      if (!mounted) {
        return;
      }
      final result = IdentityUploadSuccessResult.fromResponse(response);
      AppPush.replace(
        context,
        page: IdentityUploadSuccessPage(
          result: result,
          documentType: widget.documentType.trim(),
        ),
        routeName: RouteNames.identityUploadSuccess,
      );
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  String _mapImageSource(String option) {
    return option == 'Album' ? '1' : '2';
  }

  Future<File?> _compressToLimit(File file) async {
    final target = 500 * 1024;
    var quality = 90;
    File compressFile = file;
    while (quality >= 10) {
      compressFile = await _compressImageQuality(compressFile, quality);
      final curSize = compressFile.lengthSync();
      if (curSize <= target) {
        return compressFile;
      }
      quality -= 5;
    }

    final bytes = await compressFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final originalImage = await codec.getNextFrame();
    int curWidth = originalImage.image.width;
    int curHeight = originalImage.image.height;

    while (curWidth > 100 && curHeight > 100) {
      curWidth = (curWidth * 0.95).toInt();
      curHeight = (curHeight * 0.95).toInt();
      compressFile = await _compressImageSize(file, curWidth, curHeight);
      final curSize = compressFile.lengthSync();
      if (curSize <= target) {
        return compressFile;
      }
    }
    return compressFile;
  }

  Future<File> _compressImageQuality(File file, int quality) async {
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/id_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      path,
      quality: quality,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: false,
      keepExif: false,
    );
    return File(result!.path);
  }

  Future<File> _compressImageSize(File file, int width, int height) async {
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/id_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      path,
      minWidth: width,
      minHeight: height,
      quality: 95,
      format: CompressFormat.jpeg,
    );
    return File(result!.path);
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  static const double _designWidth = 343;
  static const double _designHeight = 324;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final cardWidth = screen.width - screen.dp(32);
    final cardHeight = cardWidth * _designHeight / _designWidth;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screen.dp(14)),
        child: Image(
          image: AssetImage('assets/image/verification/id_demo_card.png'),
          width: cardWidth,
          height: cardHeight,
          fit: BoxFit.cover,
        ),
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

class _DocumentTypeSheet extends StatefulWidget {
  const _DocumentTypeSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<String> options;
  final String selectedValue;

  @override
  State<_DocumentTypeSheet> createState() => _DocumentTypeSheetState();
}

class _DocumentTypeSheetState extends State<_DocumentTypeSheet> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = screen.height * 0.45;
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screen.dp(14)),
            topRight: Radius.circular(screen.dp(14)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screen.dp(16),
            screen.dp(26),
            screen.dp(16),
            math.max(screen.dp(9), screen.safeBottom + bottomInset),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: screen.dp(26)),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final selected = option == _selectedValue;
                    return _DocumentTypeOptionTile(
                      label: option,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _selectedValue = option;
                        });
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: screen.dp(10)),
              _PrimaryButton(
                label: 'Submit',
                onTap: () => Navigator.of(context).pop(_selectedValue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentTypeOptionTile extends StatelessWidget {
  const _DocumentTypeOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screen.dp(16),
              vertical: screen.dp(16),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F3),
              borderRadius: BorderRadius.circular(screen.dp(10)),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF281001)
                      : const Color(0xFF908E8C),
                  fontSize: screen.dp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'assets/image/verification/id_type_selected_badge.png',
                width: screen.dp(16),
                height: screen.dp(16),
              ),
            ),
        ],
      ),
    );
  }
}
