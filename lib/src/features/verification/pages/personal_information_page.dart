import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/push/app_push.dart';
import '../../../core/push/route_names.dart';
import '../../../core/widgets/dismiss_keyboard.dart';
import '../../product/product_detail_cache.dart';
import '../address_cache.dart';
import '../models/address_region_model.dart';
import '../models/personal_information_model.dart';
import '../widgets/verification_hint_row.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key, required this.productId});

  static const routeName = RouteNames.personalInformation;

  final String productId;

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  static const _retainPopupType = '2';
  PersonalInformationModel? _model;
  final ScrollController _scrollController = ScrollController();
  final Map<int, TextEditingController> _fieldControllers =
      <int, TextEditingController>{};
  final Map<int, FocusNode> _fieldFocusNodes = <int, FocusNode>{};
  final Map<int, GlobalKey> _fieldKeys = <int, GlobalKey>{};
  final Map<int, String> _selectedFieldValues = <int, String>{};
  final Map<int, AddressSelectionResult> _selectedAddressValues =
      <int, AddressSelectionResult>{};
  late final FocusNode _inactiveFocusNode;
  bool _loading = false;

  Future<void> _handleRetainBack() async {
    await AppPush.showRetainPopupThen(
      context,
      productId: widget.productId,
      popupType: _retainPopupType,
      onGoBack: () => AppPush.popToHomeTabbar(context),
    );
  }

  @override
  void initState() {
    super.initState();
    _inactiveFocusNode = FocusNode(
      debugLabel: 'personal_information_inactive_focus',
      skipTraversal: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final productId = widget.productId.trim();
    if (_loading || productId.isEmpty) {
      return;
    }
    _loading = true;
    EasyLoading.show();
    try {
      final response = await apiService.fetchUserInfo(productId: productId);
      _model = PersonalInformationModel.fromJson(response.data);
      await _ensureAddressCache(_model!.fields);
      _syncFieldControllers(_model!.fields);
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

  Future<void> _ensureAddressCache(
    List<PersonalInformationField> fields,
  ) async {
    final needsAddressCache = fields.any((field) => field.isAddressField);
    if (!needsAddressCache || AddressCache.hasUsableRegions) {
      return;
    }
    AddressCache.clear();
    final response = await apiService.initializeAddress();
    final regions = response.data ?? const [];
    if (regions.isNotEmpty) {
      AddressCache.save(regions);
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
      _selectedFieldValues.remove(id);
      _selectedAddressValues.remove(id);
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
      return;
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

  Future<void> _showAddressFieldSheet(PersonalInformationField field) async {
    final regions = AddressCache.regions ?? const <AddressRegionModel>[];
    if (regions.isEmpty) {
      return;
    }
    _clearInputFocus();
    final selected = await showModalBottomSheet<AddressSelectionResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (sheetContext) {
        return _AddressFieldSheet(regions: regions, initialSelection: null);
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
      _selectedAddressValues[field.id] = selected;
    });
  }

  Map<String, dynamic> _buildSubmitFields() {
    final fields = <String, dynamic>{};
    for (final field in _model?.fields ?? const <PersonalInformationField>[]) {
      final key = field.keyName.trim();
      if (key.isEmpty) {
        continue;
      }
      if (field.isSelectField) {
        final value = _selectedFieldValues[field.id] ?? field.value;
        fields[key] = value;
        continue;
      }
      if (field.isInputField) {
        fields[key] = _fieldControllers[field.id]?.text.trim() ?? '';
        continue;
      }
      if (field.isAddressField) {
        fields[key] = _selectedAddressValues[field.id]?.displayText ?? '';
      }
    }
    return fields;
  }

  Future<void> _submitUserInfo() async {
    _clearInputFocus();
    final submitFields = _buildSubmitFields();
    final productId = widget.productId.trim();
    submitFields['silken'] = productId;
    EasyLoading.show();
    try {
      await apiService.saveUserInfo(fields: submitFields);
      if (!mounted) {
        return;
      }
      if (productId.isNotEmpty) {
        await AppPush.productDetail(context, productId: productId);
      }
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
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
    if (field.isAddressField) {
      return _selectedAddressValues[field.id]?.displayText ?? field.value;
    }
    return field.value;
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

  void _clearInputFocus() {
    for (final focusNode in _fieldFocusNodes.values) {
      focusNode.unfocus();
    }
    FocusScope.of(context).requestFocus(_inactiveFocusNode);
  }

  @override
  void dispose() {
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
    final hintMessage = _model?.hint.isNotEmpty == true
        ? _model!.hint
        : ProductDetailCache.current?.temporalize.personalHint.trim() ?? '';
    final fields = _model?.fields ?? const <PersonalInformationField>[];
    final width = screen.width - screen.dp(16) * 2;
    final height = width * (32.0 / 343.0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleRetainBack();
      },
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
                screen.dp(15),
              ),
              child: _PrimaryButton(label: 'Submit', onTap: _submitUserInfo),
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
                  screen.dp(16),
                  screen.dp(15),
                  screen.dp(16),
                  screen.dp(120),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onBack: _handleRetainBack),
                    SizedBox(height: screen.dp(16)),
                    VerificationHintRow(message: hintMessage),
                    SizedBox(height: screen.dp(22)),
                    Image.asset(
                      'assets/image/line/personal_info_progress_bar.png',
                      width: width,
                      height: height,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screen.dp(30)),
                    for (final field in fields) ...[
                      _FieldTitle(title: field.title),
                      SizedBox(height: screen.dp(10)),
                      KeyedSubtree(
                        key: _fieldKeys[field.id],
                        child: _FieldCard(
                          field: field,
                          value: _displayValue(field),
                          controller: _fieldControllers[field.id],
                          focusNode: _fieldFocusNodes[field.id],
                          onTap: field.isSelectField
                              ? () => _showSelectFieldSheet(field)
                              : field.isAddressField
                              ? () => _showAddressFieldSheet(field)
                              : null,
                        ),
                      ),
                      SizedBox(height: screen.dp(16)),
                    ],
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
            'Identity Information',
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

class _FieldCard extends StatelessWidget {
  const _FieldCard({
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
            // enabled: !field.isDisabled,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: screen.dp(16),
                  height: 20 / 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (field.isSelectField || field.isAddressField)
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
        // constraints: BoxConstraints(maxHeight: maxHeight),
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
                      label: option.label,
                      selected: selected,
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

class _AddressFieldSheet extends StatefulWidget {
  const _AddressFieldSheet({required this.regions, this.initialSelection});

  final List<AddressRegionModel> regions;
  final AddressSelectionResult? initialSelection;

  @override
  State<_AddressFieldSheet> createState() => _AddressFieldSheetState();
}

class _AddressFieldSheetState extends State<_AddressFieldSheet> {
  int _level = 0;
  AddressRegionModel? _selectedRegion;
  AddressRegionModel? _selectedCity;
  AddressRegionModel? _selectedArea;

  @override
  void initState() {
    super.initState();
    _restoreInitialSelection();
  }

  void _restoreInitialSelection() {
    final initial = widget.initialSelection;
    if (initial == null) {
      return;
    }
    for (final region in widget.regions) {
      if (region.sort != initial.regionSort) {
        continue;
      }
      _selectedRegion = region;
      for (final city in region.cities) {
        if (city.sort != initial.citySort) {
          continue;
        }
        _selectedCity = city;
        final areas = city.cities;
        for (final area in areas) {
          if (area.sort == initial.areaSort) {
            _selectedArea = area;
            _level = 2;
            return;
          }
        }
        _level = 1;
        return;
      }
      return;
    }
  }

  List<AddressRegionModel> get _currentOptions {
    if (_level == 0) {
      return const <AddressRegionModel>[];
    }
    if (_level == 1 && _selectedRegion != null) {
      return _selectedRegion!.cities;
    }
    if (_selectedRegion != null && _selectedCity != null) {
      return _selectedCity!.cities;
    }
    return const <AddressRegionModel>[];
  }

  bool get _hasAreaLevel {
    if (_selectedCity == null) {
      return false;
    }
    return _selectedCity!.cities.isNotEmpty;
  }

  bool get _isFinalLevel {
    if (_level == 0) {
      return false;
    }
    if (_level == 1) {
      return !_hasAreaLevel;
    }
    return true;
  }

  bool get _canContinue {
    switch (_level) {
      case 0:
        return _selectedRegion != null;
      case 1:
        return _selectedCity != null;
      case 2:
        return _selectedArea != null;
      default:
        return false;
    }
  }

  String get _actionLabel => _isFinalLevel ? 'Done' : 'Next';

  String get _titleText {
    switch (_level) {
      case 0:
        return 'Address';
      case 1:
        return _selectedRegion?.name ?? 'Address';
      case 2:
        if (_selectedRegion == null) {
          return 'Address';
        }
        if (_selectedCity == null) {
          return _selectedRegion!.name;
        }
        return '${_selectedRegion!.name}-${_selectedCity!.name}';
      default:
        return 'Address';
    }
  }

  bool get _canGoBack {
    switch (_level) {
      case 0:
        return false;
      case 1:
        return _selectedRegion != null;
      case 2:
        return _selectedCity != null;
      default:
        return false;
    }
  }

  void _handleTitleTap() {
    if (!_canGoBack) {
      return;
    }
    setState(() {
      if (_level == 2) {
        _selectedCity = null;
        _selectedArea = null;
        _level = 1;
        return;
      }
      if (_level == 1) {
        _selectedRegion = null;
        _selectedCity = null;
        _selectedArea = null;
        _level = 0;
      }
    });
  }

  void _handleContinue() {
    if (!_canContinue) {
      return;
    }
    if (_level == 0) {
      setState(() {
        _selectedCity = null;
        _selectedArea = null;
        _level = 1;
      });
      return;
    }
    if (_level == 1) {
      if (!_hasAreaLevel) {
        if (_selectedRegion == null || _selectedCity == null) {
          return;
        }
        Navigator.of(context).pop(
          AddressSelectionResult(
            regionSort: _selectedRegion!.sort,
            regionName: _selectedRegion!.name,
            citySort: _selectedCity!.sort,
            cityName: _selectedCity!.name,
            areaSort: '',
            areaName: '',
          ),
        );
        return;
      }
      setState(() {
        _selectedArea = null;
        _level = 2;
      });
      return;
    }
    if (_selectedRegion == null ||
        _selectedCity == null ||
        _selectedArea == null) {
      return;
    }
    Navigator.of(context).pop(
      AddressSelectionResult(
        regionSort: _selectedRegion!.sort,
        regionName: _selectedRegion!.name,
        citySort: _selectedCity!.sort,
        cityName: _selectedCity!.name,
        areaSort: _selectedArea!.sort,
        areaName: _selectedArea!.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final optionCount = _level == 0
        ? widget.regions.length
        : _currentOptions.length;
    final visibleCount = math.min(optionCount, 5);
    final listHeight =
        visibleCount * screen.dp(58) +
        math.max(0, visibleCount - 1) * screen.dp(26);
    final maxHeight = screen.height * 0.45;
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            width: screen.dp(24),
                            alignment: Alignment.centerLeft,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: screen.dp(14),
                                  height: screen.dp(14),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8B032),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Positioned(
                                  left: screen.dp(-2),
                                  bottom: screen.dp(-2),
                                  child: Container(
                                    width: screen.dp(8),
                                    height: screen.dp(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFE43432,
                                      ).withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _canGoBack ? _handleTitleTap : null,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              _titleText,
                              style: TextStyle(
                                color: const Color(0xFF281001),
                                fontSize: screen.dp(18),
                                height: 20 / 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screen.dp(26)),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.min(listHeight, maxHeight),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: optionCount,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: screen.dp(26)),
                        itemBuilder: (context, index) {
                          if (_level == 0) {
                            final option = widget.regions[index];
                            final selected = identical(option, _selectedRegion);
                            return _AddressOptionTile(
                              label: option.name,
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  _selectedRegion = option;
                                  _selectedCity = null;
                                  _selectedArea = null;
                                });
                              },
                            );
                          }
                          final option = _currentOptions[index];
                          final selected = _level == 1
                              ? identical(option, _selectedCity)
                              : identical(option, _selectedArea);
                          return _AddressOptionTile(
                            label: option.name,
                            selected: selected,
                            onTap: () {
                              setState(() {
                                if (_level == 1) {
                                  _selectedCity = option;
                                  _selectedArea = null;
                                } else {
                                  _selectedArea = option;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: screen.dp(26)),
                    _PrimaryButton(
                      label: _actionLabel,
                      onTap: _canContinue ? _handleContinue : null,
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

class _AddressOptionTile extends StatelessWidget {
  const _AddressOptionTile({
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
                  height: 20 / 16,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

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
