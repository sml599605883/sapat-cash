import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:sapat_cash/src/core/json/json.dart';

import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/push/app_push.dart';
import '../../../core/push/route_names.dart';
import '../../../core/report/report_manager.dart';
import '../../../core/widgets/dismiss_keyboard.dart';
import '../../product/product_detail_cache.dart';
import '../models/contact_information_model.dart';
import '../models/personal_information_model.dart';
import '../widgets/verification_hint_row.dart';

class ContactInformationPage extends StatefulWidget {
  const ContactInformationPage({super.key, required this.productId});

  static const routeName = RouteNames.contactInformation;

  final String productId;

  @override
  State<ContactInformationPage> createState() => _ContactInformationPageState();
}

class _ContactInformationPageState extends State<ContactInformationPage> {
  static const _retainPopupType = '4';
  ContactInformationModel? _model;
  final ScrollController _scrollController = ScrollController();
  final Map<int, TextEditingController> _fieldControllers =
      <int, TextEditingController>{};
  final Map<int, FocusNode> _fieldFocusNodes = <int, FocusNode>{};
  final Map<int, GlobalKey> _fieldKeys = <int, GlobalKey>{};
  final Map<int, String> _selectedFieldValues = <int, String>{};
  late final FocusNode _inactiveFocusNode;
  bool _loading = false;
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  late int _scene7StartTimeSeconds;

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
    _scene7StartTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _inactiveFocusNode = FocusNode(
      debugLabel: 'contact_information_inactive_focus',
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
      final response = await apiService.fetchContactInfo(productId: productId);
      _model = ContactInformationModel.fromJson(response.data);
      _syncFields(_model!.groups);
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

  void _syncFields(List<ContactInformationGroup> groups) {
    final validIds = <int>{};
    for (final group in groups) {
      for (final field in [
        group.relationshipField,
        group.nameField,
        group.phoneField,
      ]) {
        if (field == null) {
          continue;
        }
        validIds.add(field.id);
        if (field.isSelectField && field.value.isNotEmpty) {
          _selectedFieldValues[field.id] = field.value;
          continue;
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

    final staleIds = <int>{
      ..._fieldControllers.keys,
      ..._fieldFocusNodes.keys,
      ..._fieldKeys.keys,
      ..._selectedFieldValues.keys,
    }.where((item) => !validIds.contains(item)).toList(growable: false);
    for (final id in staleIds) {
      _fieldControllers.remove(id)?.dispose();
      _fieldFocusNodes.remove(id)?.dispose();
      _fieldKeys.remove(id);
      _selectedFieldValues.remove(id);
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

  void _clearInputFocus() {
    for (final focusNode in _fieldFocusNodes.values) {
      focusNode.unfocus();
    }
    FocusScope.of(context).requestFocus(_inactiveFocusNode);
  }

  Future<void> _showRelationshipSheet(PersonalInformationField field) async {
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

  String _displaySelectValue(PersonalInformationField? field) {
    if (field == null) {
      return '';
    }
    final currentValue = _selectedFieldValues[field.id] ?? field.value;
    final matchedOption = _matchSelectedOption(field.options, currentValue);
    return matchedOption?.label ?? currentValue;
  }

  Future<void> _selectContact(ContactInformationGroup group) async {
    _clearInputFocus();
    Contact? selected;
    try {
      selected = await _contactPicker.selectContact();
    } catch (error) {
      if (mounted) {
        EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
      }
      return;
    }
    final selectedName = (selected?.fullName ?? '').trim();
    final selectedPhone = _pickPrimaryPhone(selected).trim();
    if (!mounted || _model == null) {
      return;
    }
    if (selectedName.isEmpty && selectedPhone.isEmpty) {
      return;
    }

    final groups = _model!.groups
        .map((item) {
          if (item.index != group.index) {
            return item;
          }
          return item.copyWith(
            nameField: _copyFieldWithValue(item.nameField, selectedName),
            phoneField: _copyFieldWithValue(item.phoneField, selectedPhone),
          );
        })
        .toList(growable: false);

    setState(() {
      _model = _model!.copyWith(groups: groups);
      _syncFields(groups);
    });
  }

  PersonalInformationField? _copyFieldWithValue(
    PersonalInformationField? field,
    String value,
  ) {
    if (field == null) {
      return null;
    }
    return PersonalInformationField(
      id: field.id,
      title: field.title,
      placeholder: field.placeholder,
      keyName: field.keyName,
      inputType: field.inputType,
      isNumberKeyboard: field.isNumberKeyboard,
      options: field.options,
      isOptional: field.isOptional,
      isCertified: field.isCertified,
      certifiedText: field.certifiedText,
      isDisabled: field.isDisabled,
      value: value,
      chemical: field.chemical,
      borderlands: field.borderlands,
    );
  }

  String _pickPrimaryPhone(Contact? contact) {
    final selectedNumber = contact?.selectedPhoneNumber?.trim() ?? '';
    if (selectedNumber.isNotEmpty) {
      return selectedNumber;
    }
    final numbers = contact?.phoneNumbers;
    if (numbers == null || numbers.isEmpty) {
      return '';
    }
    for (final item in numbers) {
      final normalized = item.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  Future<void> _submitContactInfo() async {
    _clearInputFocus();
    final productId = widget.productId.trim();
    final contactsJson = Json(_buildSubmitContacts()).rawString();
    EasyLoading.show();
    try {
      await apiService.saveContactInfo(
        productId: productId,
        contactsJson: contactsJson,
      );
      if (!mounted) {
        return;
      }
      if (productId.isNotEmpty) {
        ReportManager.instance.reportRiskBehavior(
          productId: productId,
          sceneType: '7',
          orderNo: ProductDetailCache.current?.orderNo.trim() ?? '',
          startTimeSeconds: _scene7StartTimeSeconds,
        );
        await AppPush.productDetail(context, productId: productId);
      }
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  List<Map<String, dynamic>> _buildSubmitContacts() {
    final groups = _model?.groups ?? const <ContactInformationGroup>[];
    return groups
        .map((group) {
          final relationshipField = group.relationshipField;
          final nameField = group.nameField;
          final phoneField = group.phoneField;
          final item = <String, dynamic>{};
          if (relationshipField != null &&
              relationshipField.keyName.trim().isNotEmpty) {
            item[relationshipField.keyName] =
                _selectedFieldValues[relationshipField.id] ??
                relationshipField.value;
          }
          if (nameField != null && nameField.keyName.trim().isNotEmpty) {
            item[nameField.keyName] =
                _fieldControllers[nameField.id]?.text.trim() ?? '';
          }
          if (phoneField != null && phoneField.keyName.trim().isNotEmpty) {
            item[phoneField.keyName] =
                _fieldControllers[phoneField.id]?.text.trim() ?? '';
          }
          if (group.groupKey.trim().isNotEmpty) {
            item['paramagnetisms'] = group.groupKey;
          }
          return item;
        })
        .toList(growable: false);
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
    final model = _model;
    final groups = model?.groups ?? const <ContactInformationGroup>[];
    final hintMessage = model?.hint.isNotEmpty == true
        ? model!.hint
        : ProductDetailCache.current?.temporalize.contactHint.trim() ?? '';
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
              child: _PrimaryButton(label: 'Submit', onTap: _submitContactInfo),
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
                      'assets/image/line/contact_info_progress_bar.png',
                      width: width,
                      height: height,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screen.dp(30)),
                    for (final group in groups) ...[
                      _ContactGroupSection(
                        group: group,
                        relationshipValue: _displaySelectValue(
                          group.relationshipField,
                        ),
                        relationshipControllerField: group.relationshipField,
                        nameController: group.nameField == null
                            ? null
                            : _fieldControllers[group.nameField!.id],
                        phoneController: group.phoneField == null
                            ? null
                            : _fieldControllers[group.phoneField!.id],
                        nameFocusNode: group.nameField == null
                            ? null
                            : _fieldFocusNodes[group.nameField!.id],
                        phoneFocusNode: group.phoneField == null
                            ? null
                            : _fieldFocusNodes[group.phoneField!.id],
                        nameKey: group.nameField == null
                            ? null
                            : _fieldKeys[group.nameField!.id],
                        phoneKey: group.phoneField == null
                            ? null
                            : _fieldKeys[group.phoneField!.id],
                        onRelationshipTap: group.relationshipField == null
                            ? null
                            : () => _showRelationshipSheet(
                                group.relationshipField!,
                              ),
                        onSelectContact: () => _selectContact(group),
                      ),
                      SizedBox(height: screen.dp(28)),
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
            'Emergency Contacts',
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

class _ContactGroupSection extends StatelessWidget {
  const _ContactGroupSection({
    required this.group,
    required this.relationshipValue,
    required this.relationshipControllerField,
    required this.nameController,
    required this.phoneController,
    required this.nameFocusNode,
    required this.phoneFocusNode,
    required this.nameKey,
    required this.phoneKey,
    required this.onRelationshipTap,
    required this.onSelectContact,
  });

  final ContactInformationGroup group;
  final String relationshipValue;
  final PersonalInformationField? relationshipControllerField;
  final TextEditingController? nameController;
  final TextEditingController? phoneController;
  final FocusNode? nameFocusNode;
  final FocusNode? phoneFocusNode;
  final GlobalKey? nameKey;
  final GlobalKey? phoneKey;
  final VoidCallback? onRelationshipTap;
  final VoidCallback onSelectContact;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final relationshipField = relationshipControllerField;
    final nameField = group.nameField;
    final phoneField = group.phoneField;

    return GestureDetector(
      onTap: onSelectContact,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screen.dp(16)),
          Row(
            children: [
              Image.asset(
                'assets/image/mine/mine_badge_dot.png',
                width: screen.dp(16),
                height: screen.dp(16),
              ),
              SizedBox(width: screen.dp(14)),
              Expanded(
                child: Text(
                  group.title,
                  style: TextStyle(
                    color: const Color(0xFF281001),
                    fontSize: screen.dp(16),
                    height: 20 / 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screen.dp(16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screen.dp(16)),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F3),
              borderRadius: BorderRadius.circular(screen.dp(14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldTitle(title: relationshipField?.title ?? 'Relationship'),
                SizedBox(height: screen.dp(10)),
                _SelectCard(
                  value: relationshipValue,
                  placeholder: relationshipField?.placeholder.isNotEmpty == true
                      ? relationshipField!.placeholder
                      : 'Please select',
                  onTap: onRelationshipTap,
                ),
                SizedBox(height: screen.dp(16)),
                _FieldTitle(title: 'Contact Information'),
                SizedBox(height: screen.dp(10)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    screen.dp(16),
                    screen.dp(16),
                    screen.dp(16),
                    screen.dp(16),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screen.dp(10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nameController != null && nameFocusNode != null)
                              KeyedSubtree(
                                key: nameKey,
                                child: _ContactInput(
                                  controller: nameController!,
                                  focusNode: nameFocusNode!,
                                  placeholder:
                                      nameField?.placeholder.isNotEmpty == true
                                      ? nameField!.placeholder
                                      : 'Name',
                                  keyboardType: TextInputType.text,
                                ),
                              ),
                            if (nameController != null &&
                                phoneController != null)
                              SizedBox(height: screen.dp(10)),
                            if (phoneController != null &&
                                phoneFocusNode != null)
                              KeyedSubtree(
                                key: phoneKey,
                                child: _ContactInput(
                                  controller: phoneController!,
                                  focusNode: phoneFocusNode!,
                                  placeholder:
                                      phoneField?.placeholder.isNotEmpty == true
                                      ? phoneField!.placeholder
                                      : 'Phone Number',
                                  keyboardType:
                                      phoneField?.isNumberKeyboard == true
                                      ? TextInputType.number
                                      : TextInputType.phone,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: screen.dp(12)),
                      Image.asset(
                        'assets/image/verification/contact_phonebook_icon.png',
                        width: screen.dp(20),
                        height: screen.dp(20),
                      ),
                    ],
                  ),
                ),
              ],
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

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String value;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final displayValue = value.isEmpty ? placeholder : value;
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
          color: Colors.white,
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

class _ContactInput extends StatelessWidget {
  const _ContactInput({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: screen.dp(20)),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        enabled: false,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: placeholder,
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
