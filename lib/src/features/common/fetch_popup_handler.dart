import 'package:flutter/material.dart';

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
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: const Color(0x80000000),
        builder: (_) => const _UpgradePopupDialog(),
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
  const _UpgradePopupDialog();

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final dialogWidth = screen.width - screen.dp(56);
    const imageWidth = 390.0;
    const imageHeight = 378.0;
    final dialogHeight = dialogWidth * (imageHeight / imageWidth);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(screen.dp(20)),
            child: Image.asset(
              'assets/image/popup/photo_02@3x.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
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
