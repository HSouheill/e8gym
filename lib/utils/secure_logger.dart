import 'package:flutter/foundation.dart';

class SecureLogger {
  /// Log debug information only in debug mode
  static void debug(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      print('[DEBUG] $message');
      if (data != null) {
        print('[DEBUG DATA] $data');
      }
    }
  }

  /// Log info messages (always logged)
  static void info(String message) {
    print('[INFO] $message');
  }

  /// Log warning messages (always logged)
  static void warning(String message) {
    print('[WARNING] $message');
  }

  /// Log error messages (always logged)
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    print('[ERROR] $message');
    if (error != null) {
      print('[ERROR DETAILS] $error');
    }
    if (stackTrace != null && kDebugMode) {
      print('[STACK TRACE] $stackTrace');
    }
  }

  /// Log security events (always logged, sanitized)
  static void security(String event, {Map<String, dynamic>? details}) {
    print('[SECURITY] $event');
    if (details != null && kDebugMode) {
      // Sanitize sensitive data
      final sanitizedDetails = _sanitizeDetails(details);
      print('[SECURITY DETAILS] $sanitizedDetails');
    }
  }

  /// Log API requests (debug mode only, sanitized)
  static void apiRequest(String method, String url, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      print('[API REQUEST] $method $url');
      if (body != null) {
        final sanitizedBody = _sanitizeRequestBody(body);
        print('[API BODY] $sanitizedBody');
      }
    }
  }

  /// Log API responses (debug mode only, sanitized)
  static void apiResponse(int statusCode, String url, {String? body}) {
    if (kDebugMode) {
      print('[API RESPONSE] $statusCode $url');
      if (body != null) {
        final sanitizedBody = _sanitizeResponseBody(body);
        print('[API RESPONSE BODY] $sanitizedBody');
      }
    }
  }

  /// Sanitize request body to remove sensitive data
  static Map<String, dynamic> _sanitizeRequestBody(Map<String, dynamic> body) {
    final sanitized = Map<String, dynamic>.from(body);
    
    // Remove sensitive fields
    const sensitiveFields = [
      'password',
      'access_token',
      'refresh_token',
      'authorization',
      'token',
      'secret',
      'key',
    ];

    for (final field in sensitiveFields) {
      if (sanitized.containsKey(field)) {
        sanitized[field] = '[REDACTED]';
      }
    }

    return sanitized;
  }

  /// Sanitize response body to remove sensitive data
  static String _sanitizeResponseBody(String body) {
    // Remove sensitive patterns from response
    final patterns = [
      RegExp(r'"access_token":\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"refresh_token":\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"token":\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"password":\s*"[^"]*"', caseSensitive: false),
    ];

    String sanitized = body;
    for (final pattern in patterns) {
      sanitized = sanitized.replaceAll(pattern, '"${pattern.pattern.split('"')[1]}": "[REDACTED]"');
    }

    return sanitized;
  }

  /// Sanitize details map to remove sensitive data
  static Map<String, dynamic> _sanitizeDetails(Map<String, dynamic> details) {
    final sanitized = Map<String, dynamic>.from(details);
    
    const sensitiveKeys = [
      'password',
      'token',
      'secret',
      'key',
      'access_token',
      'refresh_token',
    ];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '[REDACTED]';
      }
    }

    return sanitized;
  }
}
