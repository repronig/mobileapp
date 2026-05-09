import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

/// Label above inputs (member profile, account settings, auth forms).
class MemberFormFieldLabel extends StatelessWidget {
  const MemberFormFieldLabel({
    super.key,
    required this.text,
    this.required = false,
  });

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration memberFormInputDecoration(
  ThemeData theme, {
  String? hint,
  Widget? suffixIcon,
}) {
  final r = BorderRadius.circular(AppFormInput.borderRadius);
  final side = BorderSide(
    color: AppFormInput.outlineColor,
    width: AppFormInput.borderWidth,
  );
  final focusedSide = BorderSide(
    color: theme.colorScheme.primary,
    width: AppFormInput.borderWidth,
  );
  final errorSide = BorderSide(
    color: theme.colorScheme.error,
    width: AppFormInput.borderWidth,
  );

  return InputDecoration(
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    labelText: null,
    filled: true,
    fillColor: theme.colorScheme.surface,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(borderRadius: r, borderSide: side),
    enabledBorder: OutlineInputBorder(borderRadius: r, borderSide: side),
    disabledBorder: OutlineInputBorder(borderRadius: r, borderSide: side),
    focusedBorder: OutlineInputBorder(borderRadius: r, borderSide: focusedSide),
    errorBorder: OutlineInputBorder(borderRadius: r, borderSide: errorSide),
    focusedErrorBorder: OutlineInputBorder(borderRadius: r, borderSide: errorSide),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
