import 'package:flutter/material.dart';

import 'app_dialog_shape.dart';

/// Returns `true` if the user confirmed they want to sign out.
Future<bool> showConfirmLogoutDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: appDialogShape(),
      title: const Text('Confirm logout'),
      content: const Text(
        'Are you sure you want to sign out?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  return result == true;
}
