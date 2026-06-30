import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sapat_cash/src/core/report/report_manager.dart';

import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/network/core/network_response.dart';
import '../../../core/push/app_push.dart';
import '../../../core/push/route_names.dart';
import '../../../core/widgets/dismiss_keyboard.dart';
import '../../product/product_detail_cache.dart';
import '../widgets/verification_hint_row.dart';

DateTime defaultIdentityBirthDate() => DateTime(2000, 1, 1);

double calculateIdentityKeyboardOverlap({
  required double fieldBottom,
  required double viewportHeight,
  required double keyboardInset,
  required double bottomSpacing,
}) {
  if (keyboardInset <= 0) {
    return 0;
  }
  final keyboardTop = viewportHeight - keyboardInset - bottomSpacing;
  final overlap = fieldBottom - keyboardTop;
  return overlap > 0 ? overlap : 0;
}

DateTime parseIdentityBirthDate(String raw, {DateTime? now}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '--') {
    return defaultIdentityBirthDate();
  }
  final normalized = trimmed.replaceAll('/', '-');
  final parsed = DateTime.tryParse(normalized);
  final resolved = parsed ?? _tryParseIdentityBirthDateParts(normalized);
  if (resolved == null) {
    return defaultIdentityBirthDate();
  }
  final current = now ?? DateTime.now();
  if (resolved.isAfter(
    DateTime(current.year, current.month, current.day, 23, 59, 59, 999, 999),
  )) {
    return defaultIdentityBirthDate();
  }
  return resolved;
}

DateTime? _tryParseIdentityBirthDateParts(String normalized) {
  final parts = normalized
      .split('-')
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

class IdentityUploadSuccessPage extends StatefulWidget {
  const IdentityUploadSuccessPage({
    super.key,
    required this.result,
    required this.documentType,
    required this.scene3StartTimeSeconds,
  });

  static const routeName = RouteNames.identityUploadSuccess;

  final IdentityUploadSuccessResult result;
  final String documentType;
  final int scene3StartTimeSeconds;

  @override
  State<IdentityUploadSuccessPage> createState() =>
      _IdentityUploadSuccessPageState();
}

class _IdentityUploadSuccessPageState extends State<IdentityUploadSuccessPage> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _idNumberController;
  late final FocusNode _fullNameFocusNode;
  late final FocusNode _idNumberFocusNode;
  late final FocusNode _inactiveFocusNode;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _fullNameFieldKey = GlobalKey();
  final GlobalKey _idNumberFieldKey = GlobalKey();
  late DateTime _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.result.fullName);
    _idNumberController = TextEditingController(text: widget.result.idNumber);
    _fullNameFocusNode = FocusNode();
    _idNumberFocusNode = FocusNode();
    _inactiveFocusNode = FocusNode(
      debugLabel: 'identity_upload_success_inactive_focus',
      skipTraversal: true,
    );
    _selectedBirthDate = _parseBirthDate(widget.result.birthDate);
    _fullNameFocusNode.addListener(
      () => _handleInputFocusChanged(
        focusNode: _fullNameFocusNode,
        fieldKey: _fullNameFieldKey,
      ),
    );
    _idNumberFocusNode.addListener(
      () => _handleInputFocusChanged(
        focusNode: _idNumberFocusNode,
        fieldKey: _idNumberFieldKey,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _fullNameFocusNode.dispose();
    _idNumberFocusNode.dispose();
    _inactiveFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final cardWidth = screen.width - screen.dp(108);
    final cardHeight = cardWidth * 162 / 267;
    final hintMessage =
        ProductDetailCache.current?.temporalize.identitySuccessHint.trim() ??
        '';
    return PopScope(
      canPop: false,
      child: DismissKeyboard(
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                screen.dp(72),
                screen.dp(12),
                screen.dp(72),
                screen.dp(34),
              ),
              child: _PrimaryButton(
                label: 'Submit',
                onTap: _submitIdentityInfo,
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Focus(
              focusNode: _inactiveFocusNode,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  screen.dp(16),
                  screen.dp(15),
                  screen.dp(16),
                  screen.dp(24) + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SuccessHeader(),
                    SizedBox(height: screen.dp(16)),
                    VerificationHintRow(message: hintMessage),
                    SizedBox(height: screen.dp(26)),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screen.dp(10)),
                        child: widget.result.cardImageUrl.isEmpty
                            ? Image.asset(
                                'assets/image/verification/id_demo_success.png',
                                width: cardWidth,
                                height: cardHeight,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                widget.result.cardImageUrl,
                                width: cardWidth,
                                height: cardHeight,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    SizedBox(height: screen.dp(26)),
                    _EditableSuccessInfoCard(
                      key: _fullNameFieldKey,
                      label: 'Full Name',
                      controller: _fullNameController,
                      focusNode: _fullNameFocusNode,
                    ),
                    SizedBox(height: screen.dp(16)),
                    _EditableSuccessInfoCard(
                      key: _idNumberFieldKey,
                      label: 'ID No.',
                      controller: _idNumberController,
                      focusNode: _idNumberFocusNode,
                    ),
                    SizedBox(height: screen.dp(16)),
                    _DateSelectorCard(
                      label: 'Date of Birth',
                      value: _formatDate(_selectedBirthDate),
                      onTap: _showBirthDateSheet,
                    ),
                    SizedBox(height: screen.dp(24)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBirthDateSheet() async {
    _clearInputFocus();
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _BirthDatePickerSheet(initialDate: _selectedBirthDate);
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
      _selectedBirthDate = selected;
    });
  }

  DateTime _parseBirthDate(String raw) {
    return parseIdentityBirthDate(raw);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _submitIdentityInfo() async {
    _clearInputFocus();
    final productId = ProductDetailCache.current?.productId.trim() ?? '';
    EasyLoading.show();
    try {
      await apiService.saveIdentityInfo(
        birthday: _formatDate(_selectedBirthDate),
        certificateNo: _idNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),
        type: '11',
        cardType: widget.documentType,
      );
      if (!mounted) {
        return;
      }
      if (productId.isNotEmpty) {
        ReportManager.instance.reportRiskBehavior(
          productId: productId,
          sceneType: '3',
          orderNo: ProductDetailCache.current?.orderNo.trim() ?? '',
          startTimeSeconds: widget.scene3StartTimeSeconds,
        );
        await AppPush.productDetail(context, productId: productId);
      }
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  void _clearInputFocus() {
    _fullNameFocusNode.unfocus();
    _idNumberFocusNode.unfocus();
    FocusScope.of(context).requestFocus(_inactiveFocusNode);
  }

  void _handleInputFocusChanged({
    required FocusNode focusNode,
    required GlobalKey fieldKey,
  }) {
    if (!focusNode.hasFocus) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || !focusNode.hasFocus) {
        return;
      }
      _adjustForKeyboardIfNeeded(fieldKey);
    });
  }

  void _adjustForKeyboardIfNeeded(GlobalKey fieldKey) {
    final fieldContext = fieldKey.currentContext;
    if (fieldContext == null || !_scrollController.hasClients) {
      return;
    }

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final renderObject = fieldContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final screen = context.screen;
    final fieldOffset = renderObject.localToGlobal(Offset.zero);
    final overlap = calculateIdentityKeyboardOverlap(
      fieldBottom: fieldOffset.dy + renderObject.size.height,
      viewportHeight: MediaQuery.sizeOf(context).height,
      keyboardInset: keyboardInset,
      bottomSpacing: screen.dp(12),
    );
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
}

class IdentityUploadSuccessResult {
  const IdentityUploadSuccessResult({
    required this.fullName,
    required this.idNumber,
    required this.birthDate,
    required this.cardImageUrl,
  });

  factory IdentityUploadSuccessResult.fromResponse(
    NetworkResponse<dynamic> response,
  ) {
    final json = response.json;
    final birthday = json['tittie'].stringValue.trim();
    final year = json['blacker'].stringValue.trim();
    final month = json['assenter'].stringValue.trim();
    final day = json['loafs'].stringValue.trim();
    final cardImageUrl = json['oreides'].stringOrNull ?? '';
    return IdentityUploadSuccessResult(
      fullName: json['fornices'].stringValue.trimOrFallback('--'),
      idNumber: json['sketchbooks'].stringValue.trimOrFallback('--'),
      birthDate: birthday.isNotEmpty
          ? birthday
          : _joinDateParts(year, month, day),
      cardImageUrl: cardImageUrl,
    );
  }

  final String fullName;
  final String idNumber;
  final String birthDate;
  final String cardImageUrl;

  static String _joinDateParts(String year, String month, String day) {
    final parts = [year, month, day].where((item) => item.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '--';
    }
    return parts.join('-');
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return SizedBox(
      height: screen.dp(48),
      child: Center(
        child: Text(
          'ID Verification',
          style: TextStyle(
            color: const Color(0xFF281001),
            fontSize: screen.dp(20),
            height: 24 / 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EditableSuccessInfoCard extends StatelessWidget {
  const _EditableSuccessInfoCard({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screen.dp(16),
        vertical: screen.dp(16),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F3),
        borderRadius: BorderRadius.circular(screen.dp(10)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF5F5752),
              fontSize: screen.dp(14),
            ),
          ),
          Expanded(
            child: SizedBox(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color: const Color(0xFF281001),
                  fontSize: screen.dp(16),
                  height: 20 / 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelectorCard extends StatelessWidget {
  const _DateSelectorCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screen.dp(16),
          vertical: screen.dp(16),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(screen.dp(10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF5F5752),
                  fontSize: screen.dp(14),
                  height: 16 / 14,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFF281001),
                fontSize: screen.dp(16),
                height: 20 / 16,
              ),
            ),
          ],
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

class _BirthDatePickerSheet extends StatefulWidget {
  const _BirthDatePickerSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_BirthDatePickerSheet> createState() => _BirthDatePickerSheetState();
}

class _BirthDatePickerSheetState extends State<_BirthDatePickerSheet> {
  static const double _sheetDesignHeight = 462;
  static const double _selectedRowHeight = 52;
  static const double _itemExtent = 60;

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  List<int> get _years => List<int>.generate(
    DateTime.now().year - 1900 + 1,
    (index) => 1900 + index,
  );

  List<int> get _months => List<int>.generate(12, (index) => index + 1);

  List<int> get _days {
    final maxDay = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    return List<int>.generate(maxDay, (index) => index + 1);
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate.day;
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final sheetHeight = screen.dp(_sheetDesignHeight);
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screen.dp(14)),
            topRight: Radius.circular(screen.dp(14)),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          screen.dp(22),
          screen.dp(48),
          screen.dp(22),
          screen.dp(9) + screen.safeBottom,
        ),
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Container(
                        height: screen.dp(_selectedRowHeight),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(screen.dp(6)),
                          border: Border.all(
                            color: const Color(0xFFF45834),
                            width: screen.dp(2),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _DateWheel(
                            values: _days,
                            controller: _dayController,
                            selectedValue: _selectedDay,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedDay = _days[index];
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _DateWheel(
                            values: _months,
                            controller: _monthController,
                            selectedValue: _selectedMonth,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedMonth = _months[index];
                                _clampDayIfNeeded();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _DateWheel(
                            values: _years,
                            controller: _yearController,
                            selectedValue: _selectedYear,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedYear = _years[index];
                                _clampDayIfNeeded();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screen.dp(48)),
            _PrimaryButton(
              label: 'Done',
              onTap: () {
                Navigator.of(
                  context,
                ).pop(DateTime(_selectedYear, _selectedMonth, _selectedDay));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clampDayIfNeeded() {
    final maxDay = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay <= maxDay) {
      return;
    }
    _selectedDay = maxDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dayController.hasClients) {
        _dayController.jumpToItem(_selectedDay - 1);
      }
    });
  }
}

class _DateWheel extends StatelessWidget {
  const _DateWheel({
    required this.values,
    required this.controller,
    required this.selectedValue,
    required this.onSelectedItemChanged,
  });

  final List<int> values;
  final FixedExtentScrollController controller;
  final int selectedValue;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: screen.dp(_BirthDatePickerSheetState._itemExtent),
      diameterRatio: 100,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final value = values[index];
          final selected = value == selectedValue;
          return Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: selected
                    ? const Color(0xFFF45834)
                    : const Color(0xFF908E8C),
                fontSize: screen.dp(18),
                height: 24 / 18,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
}

extension on String {
  String trimOrFallback(String fallback) {
    final value = trim();
    return value.isEmpty ? fallback : value;
  }
}
