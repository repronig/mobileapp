/// Compile-time configuration (no secrets).
///
/// Override the API root when needed, for example:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1`
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.repronig.org/api/v1',
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'REPRONIG',
  );

  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'd1775bbc-72df-47af-98a2-c02ad442161f',
  );
}
