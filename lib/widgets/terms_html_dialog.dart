import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'app_dialog_shape.dart';

/// Shows terms HTML in a scrollable dialog with [kAppDialogRadius] corners.
Future<void> showTermsHtmlDialog(
  BuildContext context, {
  required String title,
  String? version,
  required String body,
}) {
  final trimmed = body.trim();
  final looksLikeHtml = RegExp(r'<[a-zA-Z][\s\S]*>').hasMatch(trimmed);
  final html = looksLikeHtml
      ? trimmed
      : '<p>${const HtmlEscape().convert(trimmed)}</p>';

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        shape: appDialogShape(),
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (version != null && version.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Version $version',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                Html(
                  data: html,
                  shrinkWrap: true,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      fontSize: FontSize(14),
                      color: theme.colorScheme.onSurface,
                    ),
                    'p': Style(
                      margin: Margins.only(bottom: 10),
                    ),
                    'h1': Style(
                      fontSize: FontSize(18),
                      fontWeight: FontWeight.w800,
                    ),
                    'h2': Style(
                      fontSize: FontSize(16),
                      fontWeight: FontWeight.w800,
                    ),
                    'li': Style(
                      margin: Margins.only(bottom: 4),
                    ),
                    'a': Style(
                      color: theme.colorScheme.primary,
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
