/// Full-bleed screen backgrounds (`assets/backgrounds/bg_XX.png`).
/// Add paths here and declare each file under `flutter: assets:` in [pubspec.yaml].
abstract final class ScreenBackgroundAssets {
  static const String splash = 'assets/backgrounds/bg_12.png';

  /// Onboarding [PageView] index 0 → 2 respectively.
  static const List<String> onboarding = [
    'assets/backgrounds/bg_11.png',
    'assets/backgrounds/bg_08.png',
    'assets/backgrounds/bg_09.png',
  ];
}
