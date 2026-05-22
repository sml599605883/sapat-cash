import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/json/json.dart';
import '../../core/layout/screen.dart';
import '../../core/push/app_push.dart';

final class FetchPopupHandler {
  const FetchPopupHandler._();

  static Future<void> showIfNeeded(BuildContext context, {required Json json}) {
    final payload = json['haem'];
    final type = json['refortification'].stringValue.trim();
    if (type.isEmpty) {
      return Future.value();
    }

    if (type == '1') {
      final version = payload['unbundling'].stringValue.trim();
      final description = payload['phis'].stringValue.trim();
      final jumpUrl = payload['oreides'].stringValue.trim();
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: const Color(0x80000000),
        builder: (dialogContext) => _UpgradePopupDialog(
          version: version,
          description: description,
          onUpdate: () async {
            final rawUrl = jumpUrl;
            final uri = Uri.tryParse(rawUrl);
            if (uri == null) {
              return;
            }
            Navigator.of(dialogContext).pop();
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      );
    }

    final imageUrl = payload['antagonist'].stringValue.trim();
    final jumpUrl = payload['oreides'].stringValue.trim();
    if (type != '3' || imageUrl.isEmpty || jumpUrl.isEmpty) {
      return Future.value();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x80000000),
      builder: (dialogContext) {
        return _MarketingPopupDialog(
          imageUrl: imageUrl,
          onJump: () {
            Navigator.of(dialogContext).pop();
            AppPush.openWebPage(dialogContext, rawUrl: jumpUrl);
          },
        );
      },
    );
  }
}

class _UpgradePopupDialog extends StatelessWidget {
  const _UpgradePopupDialog({
    required this.version,
    required this.description,
    required this.onUpdate,
  });

  final String version;
  final String description;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final dialogWidth = screen.width - screen.dp(56);
    final cardHeight = dialogWidth * (359 / 319);
    final headerHeight = dialogWidth * (112 / 319);
    final illustrationWidth = dialogWidth * (117 / 319);
    final illustrationHeight = illustrationWidth;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: dialogWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screen.dp(14)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: headerHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(screen.dp(14)),
                    topRight: Radius.circular(screen.dp(14)),
                  ),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0x33FFF4E1),
                                const Color(0x00E38C22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: screen.dp(4),
                        child: Image.asset(
                          'assets/image/popup/popup_upgrade_illustration.png',
                          width: illustrationWidth,
                          height: illustrationHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: screen.dp(21),
                  left: screen.dp(72),
                  right: screen.dp(74),
                ),
                child: Column(
                  children: [
                    Text(
                      'New version released',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF281001),
                        fontSize: screen.dp(18),
                        fontWeight: FontWeight.w500,
                        height: 22 / 18,
                      ),
                    ),
                    SizedBox(height: screen.dp(4)),
                    Text(
                      version,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF908E8C),
                        fontSize: screen.dp(14),
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: screen.dp(16),
                  left: screen.dp(40),
                  right: screen.dp(38),
                ),
                child: _UpgradeDescriptionBlock(text: description),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFE7E7E7),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onUpdate,
                child: SizedBox(
                  width: double.infinity,
                  height: screen.dp(56),
                  child: Center(
                    child: Text(
                      'Update Now',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF45834),
                        fontSize: screen.dp(18),
                        fontWeight: FontWeight.w700,
                        height: 22 / 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeDescriptionBlock extends StatelessWidget {
  const _UpgradeDescriptionBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final displayLines = lines.isEmpty ? const [''] : lines;

    return Column(
      children: displayLines
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == displayLines.length - 1
                    ? 0
                    : screen.dp(10),
              ),
              child: Text(
                entry.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5F5752),
                  fontSize: screen.dp(16),
                  fontWeight: FontWeight.w400,
                  height: 20 / 16,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MarketingPopupDialog extends StatelessWidget {
  const _MarketingPopupDialog({required this.imageUrl, required this.onJump});

  final String imageUrl;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final dialogWidth = screen.width - screen.dp(56);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: _PopupImageFrame(
          imageUrl: imageUrl,
          width: dialogWidth,
          onTap: onJump,
        ),
      ),
    );
  }
}

class _PopupImageFrame extends StatefulWidget {
  const _PopupImageFrame({
    required this.imageUrl,
    required this.width,
    required this.onTap,
  });

  final String imageUrl;
  final double width;
  final VoidCallback onTap;

  @override
  State<_PopupImageFrame> createState() => _PopupImageFrameState();
}

class _PopupImageFrameState extends State<_PopupImageFrame> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  ImageStreamListener? _imageStreamListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _PopupImageFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageInfo = null;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    final imageStreamListener = _imageStreamListener;
    if (imageStreamListener != null) {
      _imageStream?.removeListener(imageStreamListener);
    }
    super.dispose();
  }

  void _resolveImage() {
    final provider = NetworkImage(widget.imageUrl);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final imageStreamListener = _imageStreamListener;
    if (imageStreamListener != null) {
      _imageStream?.removeListener(imageStreamListener);
    }
    _imageStream = stream;
    _imageStreamListener = ImageStreamListener((info, synchronousCall) {
      if (!mounted) {
        return;
      }
      setState(() {
        _imageInfo = info;
      });
    });
    stream.addListener(_imageStreamListener!);
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final imageInfo = _imageInfo;
    final height = imageInfo == null
        ? widget.width
        : widget.width * imageInfo.image.height / imageInfo.image.width;

    return SizedBox(
      width: widget.width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screen.dp(20)),
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
