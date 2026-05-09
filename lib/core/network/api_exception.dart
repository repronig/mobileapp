/// Normalized API failure (Laravel JSON: `message`, optional `errors` map).
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.errors});

  factory ApiException.fromDioResponse({
    required int? statusCode,
    required Object? data,
    String fallbackMessage = 'An unexpected error occurred.',
  }) {
    if (data is! Map) {
      return ApiException(message: fallbackMessage, statusCode: statusCode);
    }
    final map = Map<String, dynamic>.from(data);
    final rawMessage = map['message'] is String
        ? (map['message'] as String).trim()
        : '';
    final errors = map['errors'];
    final validation = _firstValidationError(errors);

    const generic = {
      'the given data was invalid.',
      'request failed.',
      'server error',
    };

    final useServerMessage =
        rawMessage.isNotEmpty && !generic.contains(rawMessage.toLowerCase());

    final message = useServerMessage
        ? rawMessage
        : (validation ?? rawMessage.ifEmpty(fallbackMessage));

    return ApiException(
      message: message,
      statusCode: statusCode,
      errors: errors is Map<String, dynamic> ? errors : null,
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  static String? _firstValidationError(Object? errors) {
    if (errors is! Map) return null;
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          if (item is String && item.trim().isNotEmpty) return item.trim();
        }
      }
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
