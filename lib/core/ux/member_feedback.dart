import 'package:flutter/material.dart';

import '../network/api_exception.dart';

/// SnackBar feedback aligned with `app.repronig/docs/UX_CONSISTENCY.md` (duration, API vs success).
abstract final class MemberFeedback {
  static const Duration snackBarDisplay = Duration(seconds: 4);

  /// Mirrors web `FILE_UPLOAD_ERROR_FALLBACK` (`mutationFeedback.ts`).
  static const String fileUploadFailed =
      'Could not upload the file. Check the file size and type, then try again.';

  static String messageFor(Object error, {String? fallback}) {
    if (error is ApiException) return error.message;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return error.toString();
  }

  static void showError(
    BuildContext context,
    Object error, {
    String? fallback,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(messageFor(error, fallback: fallback)),
        duration: snackBarDisplay,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: snackBarDisplay),
    );
  }

  /// Client-side validation or non-API notices (same duration as success/error).
  static void showInfo(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: snackBarDisplay),
    );
  }
}
