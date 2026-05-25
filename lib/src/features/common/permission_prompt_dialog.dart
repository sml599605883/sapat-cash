import 'package:flutter/cupertino.dart';

class PermissionPromptDialog extends StatelessWidget {
  const PermissionPromptDialog({
    super.key,
    required this.title,
    required this.content,
    required this.cancelText,
    required this.confirmText,
  });

  final String title;
  final String content;
  final String cancelText;
  final String confirmText;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(true),
          isDefaultAction: true,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
