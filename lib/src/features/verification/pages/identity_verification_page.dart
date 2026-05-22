import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/push/app_push.dart';
import '../../../core/push/route_names.dart';
import '../models/identity_verification_model.dart';
import 'id_upload_demo_page.dart';

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key, required this.productId});

  static const routeName = RouteNames.identityVerification;

  final String productId;

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  static const _retainPopupType = '0';
  IdentityVerificationModel? _model;
  bool _loading = false;

  Future<void> _handleRetainBack() async {
    await AppPush.showRetainPopupThen(
      context,
      productId: widget.productId,
      popupType: _retainPopupType,
      onGoBack: () => AppPush.pop(context),
    );
  }

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
    final productId = widget.productId.trim();
    if (_loading || productId.isEmpty) {
      return;
    }
    _loading = true;
    EasyLoading.show();
    try {
      final response = await apiService.fetchIdentityInfo(productId: productId);
      _model = IdentityVerificationModel.fromJson(response.data);
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

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final model = _model;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              screen.dp(16),
              screen.dp(15),
              screen.dp(16),
              screen.dp(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(title: 'ID Verification', onBack: _handleRetainBack),
                SizedBox(height: screen.dp(16)),
                _TopBanner(),
                _OptionGroup(
                  options: model?.recommendedOptions ?? const [],
                  useTopRadius: false,
                ),
                SizedBox(height: screen.dp(28)),
                const _SectionTitle(title: 'Other Options'),
                _OptionGroup(
                  options: model?.otherOptions ?? const [],
                  useTopRadius: true,
                ),
                SizedBox(height: screen.dp(24) + screen.safeBottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
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
            title,
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

class _TopBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Container(
      width: double.infinity,
      height: screen.dp(88),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.93, -0.37),
          end: Alignment(0.93, 0.37),
          colors: [Color(0xFF7A0F03), Color(0xFFFA8D4C)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFBF8E), Color(0xFFFFFBEE)],
                    ),
                  ),
                ),
              ),
            ),
            Image.asset(
              'assets/image/verification/verification_banner_bg.png',
              fit: BoxFit.cover,
            ),
            Center(
              child: Text(
                'Recommended ID Type',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screen.dp(22),
                  height: 27 / 22,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
      padding: EdgeInsets.only(left: screen.dp(1), bottom: screen.dp(17)),
      child: Row(
        children: [
          Image.asset(
            'assets/image/mine/mine_badge_dot.png',
            width: screen.dp(18),
            height: screen.dp(18),
          ),
          SizedBox(width: screen.dp(14)),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF281001),
              fontSize: screen.dp(18),
              height: 20 / 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.options, required this.useTopRadius});

  final List<IdentityDocumentOption> options;
  final bool useTopRadius;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final items = options
        .where((item) => item.name.trim().isNotEmpty)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screen.dp(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screen.dp(useTopRadius ? 14 : 0)),
          topRight: Radius.circular(screen.dp(useTopRadius ? 14 : 0)),
          bottomLeft: Radius.circular(screen.dp(14)),
          bottomRight: Radius.circular(screen.dp(14)),
        ),
      ),
      child: Column(
        children: items.isEmpty
            ? [_EmptyState(text: 'No ID options available')]
            : items
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: screen.dp(16)),
                      child: _OptionTile(option: item, options: items),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option, required this.options});

  final IdentityDocumentOption option;
  final List<IdentityDocumentOption> options;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return GestureDetector(
      onTap: () {
        AppPush.push(
          context,
          page: IdUploadDemoPage(documentType: option.name),
          routeName: RouteNames.idUploadDemo,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screen.dp(16),
          vertical: screen.dp(16),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screen.dp(10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.name,
                style: TextStyle(
                  color: const Color(0xFF331707),
                  fontSize: screen.dp(16),
                  height: 20 / 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Image.asset(
              'assets/image/verification/verification_section_badge.png',
              width: screen.dp(12),
              height: screen.dp(12),
              color: const Color(0xFF9B9B9B),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: screen.dp(32)),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF908E8C),
          fontSize: screen.dp(14),
          height: 18 / 14,
        ),
      ),
    );
  }
}
