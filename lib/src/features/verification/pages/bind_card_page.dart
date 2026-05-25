import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sapat_cash/src/core/network/core/business_exception.dart';
import 'package:sapat_cash/src/features/verification/pages/identity_verification_page.dart';
import 'package:trustdevice_pro_plugin/trustdevice_pro_plugin.dart';

import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/push/app_push.dart';
import '../../../core/push/route_names.dart';
import '../../../core/report/report_manager.dart';
import '../../../core/report/report_models.dart';
import '../../../core/widgets/dismiss_keyboard.dart';
import '../../product/product_detail_cache.dart';
import '../models/bind_card_model.dart';
import '../models/personal_information_model.dart';
import '../widgets/verification_hint_row.dart';

class BindCardPage extends StatefulWidget {
  const BindCardPage({
    super.key,
    required this.productId,
    required this.orderNo,
    this.isChangeBankCard = false,
  });

  static const routeName = RouteNames.bindCard;

  final String productId;
  final String orderNo;
  final bool isChangeBankCard;

  @override
  State<BindCardPage> createState() => _BindCardPageState();
}

class _BindCardPageState extends State<BindCardPage> {
  BindCardModel? _model;
  final ScrollController _scrollController = ScrollController();
  final Map<int, TextEditingController> _fieldControllers =
      <int, TextEditingController>{};
  final Map<int, FocusNode> _fieldFocusNodes = <int, FocusNode>{};
  final Map<int, GlobalKey> _fieldKeys = <int, GlobalKey>{};
  final Map<int, LayerLink> _fieldLayerLinks = <int, LayerLink>{};
  final Map<int, String> _selectedFieldValues = <int, String>{};
  int? _focusedFieldId;
  OverlayEntry? _borderlandsOverlayEntry;
  late final FocusNode _inactiveFocusNode;
  bool _loading = false;
  int _selectedSectionIndex = 0;
  final TrustdeviceProPlugin _trustdeviceProPlugin = TrustdeviceProPlugin();
  late int _scene8StartTimeSeconds;

  @override
  void initState() {
    super.initState();
    _scene8StartTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _inactiveFocusNode = FocusNode(
      debugLabel: 'bind_card_inactive_focus',
      skipTraversal: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
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

  Future<void> _loadData() async {
    final productId = widget.productId.trim();
    if (_loading || productId.isEmpty) {
      return;
    }
    _loading = true;
    EasyLoading.show();
    try {
      final response = await apiService.fetchBindCardInfo(productId: productId);
      _model = BindCardModel.fromJson(response.data);
      _selectedSectionIndex = 0;
      _syncFieldControllers(_currentFields);
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      _loading = false;
      if (mounted) {
        setState(() {});
      }
      EasyLoading.dismiss();
    }
  }

  void _syncFieldControllers(List<PersonalInformationField> fields) {
    final validIds = fields.map((field) => field.id).toSet();
    final staleIds = _fieldControllers.keys
        .where((id) => !validIds.contains(id))
        .toList(growable: false);
    for (final id in staleIds) {
      _fieldControllers.remove(id)?.dispose();
      _fieldFocusNodes.remove(id)?.dispose();
      _fieldKeys.remove(id);
      _fieldLayerLinks.remove(id);
      _selectedFieldValues.remove(id);
    }

    for (final field in fields) {
      if (field.isSelectField && field.value.isNotEmpty) {
        _selectedFieldValues[field.id] = field.value;
      }
      if (!field.isInputField) {
        continue;
      }
      final controller = _fieldControllers.putIfAbsent(
        field.id,
        () => TextEditingController(text: field.value),
      );
      if (controller.text != field.value) {
        controller.text = field.value;
      }
      _fieldKeys.putIfAbsent(field.id, GlobalKey.new);
      _fieldLayerLinks.putIfAbsent(field.id, LayerLink.new);
      _fieldFocusNodes.putIfAbsent(field.id, () {
        final focusNode = FocusNode();
        focusNode.addListener(() => _handleFieldFocusChanged(field.id));
        return focusNode;
      });
    }
  }

  void _handleFieldFocusChanged(int fieldId) {
    final focusNode = _fieldFocusNodes[fieldId];
    if (focusNode?.hasFocus != true) {
      if (_focusedFieldId == fieldId) {
        setState(() {
          _focusedFieldId = null;
        });
        _syncBorderlandsOverlay();
      }
      return;
    }
    if (_focusedFieldId != fieldId) {
      setState(() {
        _focusedFieldId = fieldId;
      });
      _syncBorderlandsOverlay();
    }
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || focusNode?.hasFocus != true) {
        return;
      }
      _adjustForKeyboardIfNeeded(fieldId);
    });
  }

  void _adjustForKeyboardIfNeeded(int fieldId) {
    final fieldContext = _fieldKeys[fieldId]?.currentContext;
    if (fieldContext == null || !_scrollController.hasClients) {
      return;
    }

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset <= 0) {
      return;
    }

    final renderObject = fieldContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final screen = context.screen;
    final fieldOffset = renderObject.localToGlobal(Offset.zero);
    final fieldBottom = fieldOffset.dy + renderObject.size.height;
    final keyboardTop =
        MediaQuery.sizeOf(context).height - keyboardInset - screen.dp(12);
    final overlap = fieldBottom - keyboardTop;
    if (overlap <= 0) {
      return;
    }

    final targetOffset = (_scrollController.offset + overlap).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    if ((targetOffset - _scrollController.offset).abs() < 1) {
      return;
    }

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _clearInputFocus() {
    for (final focusNode in _fieldFocusNodes.values) {
      focusNode.unfocus();
    }
    _focusedFieldId = null;
    _removeBorderlandsOverlay();
    FocusScope.of(context).requestFocus(_inactiveFocusNode);
  }

  List<BindCardSection> get _sections =>
      _model?.sections ?? const <BindCardSection>[];

  BindCardSection? get _currentSection {
    if (_sections.isEmpty) {
      return null;
    }
    if (_selectedSectionIndex < 0 ||
        _selectedSectionIndex >= _sections.length) {
      return _sections.first;
    }
    return _sections[_selectedSectionIndex];
  }

  List<PersonalInformationField> get _currentFields =>
      _currentSection?.fields ?? const <PersonalInformationField>[];

  Future<void> _showSelectFieldSheet(PersonalInformationField field) async {
    if (field.options.isEmpty) {
      return;
    }
    _clearInputFocus();
    final matchedOption = _matchSelectedOption(
      field.options,
      _selectedFieldValues[field.id] ?? field.value,
    );
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _SelectFieldSheet(
          options: field.options,
          selectedValue: matchedOption?.value ?? '',
        );
      },
    );
    _clearInputFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _clearInputFocus();
      }
    });
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _selectedFieldValues[field.id] = selected;
    });
  }

  PersonalInformationOption? _matchSelectedOption(
    List<PersonalInformationOption> options,
    String rawValue,
  ) {
    if (rawValue.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.value == rawValue) {
        return option;
      }
    }
    for (final option in options) {
      if (option.label == rawValue) {
        return option;
      }
    }
    return null;
  }

  String _displayValue(PersonalInformationField field) {
    if (field.isInputField) {
      return _fieldControllers[field.id]?.text ?? field.value;
    }
    if (field.isSelectField) {
      final currentValue = _selectedFieldValues[field.id] ?? field.value;
      final matchedOption = _matchSelectedOption(field.options, currentValue);
      return matchedOption?.label ?? currentValue;
    }
    return field.value;
  }

  bool _shouldShowBorderlandsBubble(PersonalInformationField field) {
    if (_focusedFieldId != field.id) {
      return false;
    }
    if (!field.isInputField || field.borderlands.isEmpty) {
      return false;
    }
    final currentValue =
        _fieldControllers[field.id]?.text.trim() ?? field.value.trim();
    return currentValue.isEmpty;
  }

  void _applyBorderlandsValues() {
    final fields = _currentFields;
    for (final field in fields) {
      if (!field.isInputField || field.borderlands.isEmpty) {
        continue;
      }
      final controller = _fieldControllers[field.id];
      final currentValue = controller?.text.trim() ?? field.value.trim();
      if (currentValue.isNotEmpty) {
        continue;
      }
      controller?.text = field.borderlands;
    }
    _syncBorderlandsOverlay();
    setState(() {});
  }

  void _removeBorderlandsOverlay() {
    _borderlandsOverlayEntry?.remove();
    _borderlandsOverlayEntry = null;
  }

  void _syncBorderlandsOverlay() {
    _removeBorderlandsOverlay();
    if (!mounted) {
      return;
    }
    final fieldId = _focusedFieldId;
    if (fieldId == null) {
      return;
    }
    PersonalInformationField? field;
    for (final item in _currentFields) {
      if (item.id == fieldId) {
        field = item;
        break;
      }
    }
    if (field == null || !_shouldShowBorderlandsBubble(field)) {
      return;
    }
    final layerLink = _fieldLayerLinks[fieldId];
    if (layerLink == null) {
      return;
    }
    final overlay = Overlay.of(context);
    final screen = context.screen;
    _borderlandsOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  CompositedTransformFollower(
                    link: layerLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.topRight,
                    followerAnchor: Alignment.topRight,
                    offset: Offset(-screen.dp(4), -screen.dp(26)),
                    child: GestureDetector(
                      onTap: _applyBorderlandsValues,
                      behavior: HitTestBehavior.opaque,
                      child: _BorderlandsBubble(text: field!.borderlands),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_borderlandsOverlayEntry!);
  }

  Map<String, dynamic> _buildSubmitFields() {
    final fields = <String, dynamic>{};
    for (final field in _currentFields) {
      final key = field.keyName.trim();
      if (key.isEmpty) {
        continue;
      }
      if (field.isSelectField) {
        fields[key] = _selectedFieldValues[field.id] ?? field.value;
        continue;
      }
      if (field.isInputField) {
        fields[key] = _fieldControllers[field.id]?.text.trim() ?? '';
      }
    }
    return fields;
  }

  Future<void> _submitBindCard() async {
    _toSubmitBindCardInfo();
  }

  Future<void> _toSubmitBindCardInfo({
    String unreminiscent = '5',
    String salivate = '',
    String attach = '',
    String unrelaxed = '',
    String pyramidal = '',
  }) async {
    _clearInputFocus();
    final submitFields = _buildSubmitFields();
    final cardType = _currentSection?.typeValue.trim() ?? '';
    if (cardType.isNotEmpty) {
      submitFields['tutorials'] = cardType;
    }
    submitFields['silken'] = widget.productId.trim();
    submitFields['unreminiscent'] = unreminiscent.trim();
    submitFields['salivate'] = salivate.trim();
    submitFields['unrelaxed'] = unrelaxed.trim();
    submitFields['pyramidal'] = pyramidal.trim();
    EasyLoading.show();
    try {
      final response = await apiService.submitBindCard(
        fields: submitFields,
        filePath: attach.isNotEmpty ? attach : null,
      );
      if (!mounted) {
        return;
      }
      if (response.code == 20000) {
        _startFaceVerification();
        return;
      }
      if (widget.isChangeBankCard) {
        final reads = response.json['reads'].stringOrNull?.trim() ?? '';
        if (reads.isEmpty || reads == '0') {
          throw const BusinessException('Missing bind card id');
        }
        final changeResponse = await apiService.changeBankCard(
          orderNo: widget.orderNo.trim(),
          bindCardId: reads,
        );
        final claviform = changeResponse.json['claviform'].stringValue.trim();
        if (!mounted) {
          return;
        }
        AppPush.pop(context, claviform);
        return;
      }

      if (response.code != 20000 && widget.productId.trim().isNotEmpty) {
        ReportManager.instance.reportRiskBehavior(
          productId: widget.productId.trim(),
          sceneType: '8',
          orderNo: widget.orderNo.trim(),
          startTimeSeconds: _scene8StartTimeSeconds,
        );
      }
      await AppPush.productDetail(context, productId: widget.productId.trim());
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _startFaceVerification() async {
    EasyLoading.show();
    try {
      final response = await apiService.fetchFaceToken(
        orderNo: widget.orderNo.trim(),
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
            await _reportFaceResult(successResultMap);
            final productId =
                ProductDetailCache.current?.productId.trim() ?? '';
            if (productId.isEmpty || !mounted) {
              return;
            }
            final livenessId =
                successResultMap['liveness_id']?.toString().trim() ?? '';
            final image = successResultMap['image']?.toString().trim() ?? '';
            await _toSubmitBindCardInfo(
              unreminiscent: '5',
              salivate: livenessId,
              attach: image,
              pyramidal: license,
            );
            return;
          },
          onFailed: (failResultMap) async {
            debugPrint('showLiveness failed: $failResultMap');
            await _reportFaceResult(failResultMap);
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

  Future<void> _reportFaceResult(Map<dynamic, dynamic> resultMap) {
    return ReportManager.instance.reportFaceResult(
      FaceReportPayload(
        livenessId: resultMap['liveness_id']?.toString().trim() ?? '',
        requestId: resultMap['sequence_id']?.toString().trim() ?? '',
        resultCode: resultMap['code']?.toString().trim() ?? '',
        resultMessage: resultMap['message']?.toString().trim() ?? '',
      ),
    );
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
        RouteNames.personalInformation,
        RouteNames.workInformation,
        RouteNames.contactInformation,
        RouteNames.bindCard,
      ],
    );
  }

  @override
  void dispose() {
    _removeBorderlandsOverlay();
    _scrollController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _fieldFocusNodes.values) {
      focusNode.dispose();
    }
    _inactiveFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final width = screen.width - screen.dp(16) * 2;
    final height = width * (32.0 / 343.0);
    final fields = _currentFields;
    final hintMessage = _model?.hint.isNotEmpty == true
        ? _model!.hint
        : ProductDetailCache.current?.temporalize.bankHint.trim() ?? '';
    final bottomHint = _model?.bottomHint.isNotEmpty == true
        ? _model!.bottomHint
        : ProductDetailCache.current?.temporalize.bankBottomHint.trim() ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        AppPush.popToHomeTabbar(context);
      },
      child: DismissKeyboard(
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                screen.dp(16),
                screen.dp(8),
                screen.dp(16),
                screen.dp(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bottomHint.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: screen.dp(16)),
                      child: Text(
                        bottomHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF908E8C),
                          fontSize: screen.dp(12),
                          height: 14 / 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screen.dp(56)),
                    child: _PrimaryButton(
                      label: 'Submit',
                      onTap: _submitBindCard,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Focus(
              focusNode: _inactiveFocusNode,
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  screen.dp(0),
                  screen.dp(15),
                  screen.dp(0),
                  screen.dp(100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            onBack: () => AppPush.popToHomeTabbar(context),
                          ),
                          SizedBox(height: screen.dp(16)),
                          VerificationHintRow(message: hintMessage),
                          SizedBox(height: screen.dp(22)),
                          Image.asset(
                            'assets/image/line/withdrawal_info_progress_bar.png',
                            width: width,
                            height: height,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screen.dp(30)),
                    _AccountTypeTabs(
                      sections: _sections,
                      selectedIndex: _selectedSectionIndex,
                      onChanged: (index) {
                        setState(() {
                          _selectedSectionIndex = index;
                          _syncFieldControllers(_currentFields);
                        });
                      },
                    ),
                    SizedBox(height: screen.dp(28)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (
                            var index = 0;
                            index < fields.length;
                            index++
                          ) ...[
                            _FieldTitle(title: fields[index].title),
                            SizedBox(height: screen.dp(10)),
                            CompositedTransformTarget(
                              link:
                                  _fieldLayerLinks[fields[index].id] ??
                                  LayerLink(),
                              child: KeyedSubtree(
                                key: _fieldKeys[fields[index].id],
                                child: _BindFieldCard(
                                  field: fields[index],
                                  value: _displayValue(fields[index]),
                                  controller:
                                      _fieldControllers[fields[index].id],
                                  focusNode: _fieldFocusNodes[fields[index].id],
                                  onTap: fields[index].isSelectField
                                      ? () =>
                                            _showSelectFieldSheet(fields[index])
                                      : null,
                                ),
                              ),
                            ),
                            if (_currentSection?.title
                                        .trim()
                                        .toLowerCase()
                                        .contains('wallet') ==
                                    true &&
                                index == 0)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: screen.dp(10),
                                  bottom: screen.dp(6),
                                ),
                                child: _WarningHintRow(
                                  message:
                                      'To avoid delays, make sure your bank or e-wallet account can receive funds without restrictions.',
                                ),
                              ),
                            SizedBox(height: screen.dp(16)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            'Withdrawal Info',
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

class _AccountTypeTabs extends StatelessWidget {
  const _AccountTypeTabs({
    required this.sections,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<BindCardSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      color: const Color(0xFFF5F5F3),
      padding: EdgeInsets.symmetric(
        horizontal: screen.dp(32),
        vertical: screen.dp(10),
      ),
      child: Row(
        children: sections
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final section = entry.value;
              final selected = index == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF281001)
                              : const Color(0xFF908E8C),
                          fontSize: screen.dp(16),
                          height: 20 / 16,
                          fontWeight: selected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: screen.dp(8)),
                      Container(
                        width: screen.dp(36),
                        height: screen.dp(2),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFF45834)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(screen.dp(1)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _FieldTitle extends StatelessWidget {
  const _FieldTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFF5F5752),
        fontSize: screen.dp(16),
        height: 20 / 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _BindFieldCard extends StatelessWidget {
  const _BindFieldCard({
    required this.field,
    required this.value,
    this.controller,
    this.focusNode,
    this.onTap,
  });

  final PersonalInformationField field;
  final String value;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    if (field.isInputField && controller != null && focusNode != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          screen.dp(16),
          screen.dp(16),
          screen.dp(16),
          screen.dp(16),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(screen.dp(10)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screen.dp(20)),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: field.isNumberKeyboard
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: field.placeholder,
              hintStyle: TextStyle(
                color: const Color(0xFF908E8C),
                fontSize: screen.dp(16),
                height: 20 / 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            style: TextStyle(
              color: const Color(0xFF281001),
              fontSize: screen.dp(16),
              height: 20 / 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    final displayValue = value.isEmpty ? field.placeholder : value;
    final valueColor = value.isEmpty
        ? const Color(0xFF908E8C)
        : const Color(0xFF281001);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          screen.dp(16),
          screen.dp(16),
          screen.dp(16),
          screen.dp(16),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(screen.dp(10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayValue,
                style: TextStyle(
                  color: valueColor,
                  fontSize: screen.dp(16),
                  height: 20 / 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (field.isSelectField)
              Icon(
                Icons.chevron_right,
                size: screen.dp(16),
                color: const Color(0xFF908E8C),
              ),
          ],
        ),
      ),
    );
  }
}

class _WarningHintRow extends StatelessWidget {
  const _WarningHintRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/image/verification/bind_warning_icon.png',
          width: screen.dp(36),
          height: screen.dp(36),
        ),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: const Color(0xFF813203),
              fontSize: screen.dp(12),
              height: 16 / 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _BorderlandsBubble extends StatelessWidget {
  const _BorderlandsBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Container(
      padding: EdgeInsets.only(
        left: screen.dp(16),
        right: screen.dp(16),
        top: screen.dp(2),
        bottom: screen.dp(6),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screen.dp(6)),
        image: DecorationImage(
          image: AssetImage(
            'assets/image/verification/bind_borderlands_bubble.png',
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: screen.dp(10),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SelectFieldSheet extends StatefulWidget {
  const _SelectFieldSheet({required this.options, required this.selectedValue});

  final List<PersonalInformationOption> options;
  final String selectedValue;

  @override
  State<_SelectFieldSheet> createState() => _SelectFieldSheetState();
}

class _SelectFieldSheetState extends State<_SelectFieldSheet> {
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
    final visibleCount = math.min(widget.options.length, 5);
    final listHeight =
        visibleCount * screen.dp(58) + (visibleCount - 1) * screen.dp(26);
    final maxHeight = screen.height * 0.45;
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.min(listHeight, maxHeight),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: screen.dp(26)),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final selected = option.value == _selectedValue;
                    return _SelectFieldOptionTile(
                      logo: option.logo,
                      label: option.label,
                      selected: selected,
                      status: option.status,
                      text: option.text,
                      onTap: () {
                        setState(() {
                          _selectedValue = option.value;
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

class _SelectFieldOptionTile extends StatelessWidget {
  const _SelectFieldOptionTile({
    required this.logo,
    required this.label,
    required this.selected,
    required this.status,
    required this.text,
    required this.onTap,
  });

  final String logo;
  final String label;
  final bool selected;
  final String status;
  final String text;
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
              horizontal: logo.isNotEmpty ? screen.dp(58) : screen.dp(16),
              vertical: screen.dp(16),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F3),
              borderRadius: BorderRadius.circular(screen.dp(10)),
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF281001)
                          : const Color(0xFF908E8C),
                      fontSize: screen.dp(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (status == '0') ...[
                    SizedBox(height: screen.dp(4)),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF281001)
                            : const Color(0xFF908E8C),
                        fontSize: screen.dp(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
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
          if (logo.isNotEmpty)
            Positioned(
              left: screen.dp(19),
              top: screen.dp(7),
              bottom: screen.dp(7),
              child: Image.network(
                logo,
                width: screen.dp(32),
                height: screen.dp(32),
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
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
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF89350), Color(0xFFF45834)],
          ),
          borderRadius: BorderRadius.circular(screen.dp(24)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(screen.dp(24)),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screen.dp(14)),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screen.dp(16),
                  height: 20 / 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
