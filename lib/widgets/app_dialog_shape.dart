import 'package:flutter/material.dart';

/// Standard corner radius for app dialogs (5pt).
const double kAppDialogRadius = 5;

ShapeBorder appDialogShape() {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kAppDialogRadius),
  );
}
