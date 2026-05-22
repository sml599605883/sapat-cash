import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/push/app_push.dart';
import '../../../core/push/route_names.dart';
import '../models/bank_account_list_model.dart';
import 'bind_card_page.dart';

class BankAccountListPage extends StatefulWidget {
  const BankAccountListPage({
    super.key,
    required this.productId,
    required this.orderNo,
  });

  static const routeName = '/verification/bank-account-list';

  final String productId;
  final String orderNo;

  @override
  State<BankAccountListPage> createState() => _BankAccountListPageState();
}

class _BankAccountListPageState extends State<BankAccountListPage> {
  BankAccountListModel? _model;
  String _selectedBindCardId = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (_loading) {
      return;
    }
    _loading = true;
    EasyLoading.show();
    try {
      final response = await apiService.fetchAccountList(
        productId: widget.productId.trim(),
      );
      final model = BankAccountListModel.fromJson(response.data);
      _model = model;
      if (model.allAccounts.isNotEmpty) {
        final preferred = model.allAccounts.firstWhere(
          (item) => item.isMain,
          orElse: () => model.allAccounts.first,
        );
        _selectedBindCardId = preferred.bindCardId;
      }
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      _loading = false;
      EasyLoading.dismiss();
    }
  }

  Future<void> _handleAddOtherPaymentMethods() async {
    final claviform = await AppPush.push<String>(
      context,
      page: BindCardPage(
        productId: widget.productId,
        orderNo: widget.orderNo,
        isChangeBankCard: true,
      ),
      routeName: RouteNames.bindCard,
    );
    if (!mounted) {
      return;
    }
    final normalizedUrl = claviform?.trim() ?? '';
    if (normalizedUrl.isEmpty) {
      return;
    }
    AppPush.pop(context, normalizedUrl);
  }

  Future<void> _handleConfirm() async {
    if (_selectedBindCardId.trim().isEmpty) {
      return;
    }
    EasyLoading.show();
    try {
      final response = await apiService.changeBankCard(
        orderNo: widget.orderNo.trim(),
        bindCardId: _selectedBindCardId.trim(),
      );
      final claviform = response.json['claviform'].stringValue.trim();
      if (!mounted) {
        return;
      }
      if (claviform.isEmpty) {
        EasyLoading.showToast('Missing claviform');
        return;
      }
      AppPush.pop(context, claviform);
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final groups = _model?.groups ?? const <BankAccountGroup>[];
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screen.dp(72),
            screen.dp(26),
            screen.dp(72),
            screen.dp(20),
          ),
          child: GestureDetector(
            onTap: _handleConfirm,
            child: Container(
              // width: screen.dp(232),
              height: screen.dp(48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screen.dp(24)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(248, 147, 80, 1),
                    Color.fromRGBO(244, 88, 52, 1),
                  ],
                ),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screen.dp(16),
                  fontWeight: FontWeight.w400,
                  height: 20 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: screen.dp(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screen.dp(16),
                  screen.dp(29),
                  screen.dp(15),
                  0,
                ),
                child: _LoanDetailsHeader(onBack: () => AppPush.pop(context)),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(
                  top: screen.dp(16),
                  right: screen.dp(15),
                ),
                padding: EdgeInsets.fromLTRB(
                  screen.dp(16),
                  0,
                  screen.dp(16),
                  0,
                ),
                height: screen.dp(40),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F3),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: GestureDetector(
                  onTap: _handleAddOtherPaymentMethods,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/image/bind/bind_card_add_icon.png',
                        width: screen.dp(40),
                        height: screen.dp(40),
                      ),
                      SizedBox(width: screen.dp(12)),
                      Expanded(
                        child: Text(
                          'Add other payment methods',
                          style: TextStyle(
                            color: const Color(0xFF813203),
                            fontSize: screen.dp(14),
                            fontWeight: FontWeight.w400,
                            height: 18 / 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: screen.dp(12),
                        color: const Color(0xFF908E8C),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screen.dp(26)),
              for (final group in groups) ...[
                _SectionTitle(title: group.title),
                SizedBox(height: screen.dp(15)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screen.dp(17)),
                  child: Column(
                    children: [
                      for (final account in group.accounts) ...[
                        _AccountCard(
                          item: account,
                          selected: _selectedBindCardId == account.bindCardId,
                          onTap: () {
                            setState(() {
                              _selectedBindCardId = account.bindCardId;
                            });
                          },
                        ),
                        SizedBox(height: screen.dp(16)),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: screen.dp(10)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanDetailsHeader extends StatelessWidget {
  const _LoanDetailsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return SizedBox(
      height: screen.dp(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: screen.dp(24),
              height: screen.dp(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F1E9),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/image/login_back_icon.png',
                width: screen.dp(24),
                height: screen.dp(24),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Loan details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF281001),
                fontSize: screen.dp(20),
                fontWeight: FontWeight.w500,
                height: 24 / 20,
              ),
            ),
          ),
          SizedBox(width: screen.dp(24)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
      child: Row(
        children: [
          SizedBox(
            width: screen.dp(16),
            height: screen.dp(16),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: screen.dp(16),
                    height: screen.dp(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4B640),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: screen.dp(6),
                    height: screen.dp(6),
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(228, 52, 50, 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screen.dp(12)),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF281001),
              fontSize: screen.dp(18),
              fontWeight: FontWeight.w500,
              height: 20 / 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BankAccountItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              screen.dp(16),
              screen.dp(16),
              screen.dp(16),
              screen.dp(20),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screen.dp(14)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromRGBO(122, 15, 3, 1),
                  Color.fromRGBO(250, 141, 76, 1),
                ],
                transform: GradientRotation(22 * math.pi / 180),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screen.dp(2)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BankLogo(logo: item.logo),
                    SizedBox(width: screen.dp(12)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: screen.dp(3)),
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screen.dp(18),
                            fontWeight: FontWeight.w400,
                            height: 22 / 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screen.dp(20)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    screen.dp(16),
                    screen.dp(10),
                    screen.dp(16),
                    screen.dp(10),
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.1),
                    borderRadius: BorderRadius.circular(screen.dp(10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt Account',
                        style: TextStyle(
                          color: const Color(0xFFFFC7AF),
                          fontSize: screen.dp(16),
                          fontWeight: FontWeight.w400,
                          height: 20 / 16,
                        ),
                      ),
                      SizedBox(height: screen.dp(6)),
                      Text(
                        item.primaryValue,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screen.dp(24),
                          fontWeight: FontWeight.w500,
                          height: 28 / 24,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.status != 1 && item.statusText.isNotEmpty) ...[
                  SizedBox(height: screen.dp(10)),
                  Text(
                    item.statusText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screen.dp(12),
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Image.asset(
              selected
                  ? 'assets/image/bind/bind_card_selected_icon.png'
                  : 'assets/image/bind/bind_card_corner_mask.png',
              width: selected ? screen.dp(24) : screen.dp(18),
              height: selected ? screen.dp(24) : screen.dp(18),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  const _BankLogo({required this.logo});

  final String logo;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Container(
      width: screen.dp(30),
      height: screen.dp(30),
      padding: EdgeInsets.all(screen.dp(1)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screen.dp(8)),
        border: Border.all(color: Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screen.dp(4)),
        child: logo.isNotEmpty
            ? Image.network(logo, fit: BoxFit.cover)
            : Container(color: const Color(0xFFE8EBF1)),
      ),
    );
  }
}
