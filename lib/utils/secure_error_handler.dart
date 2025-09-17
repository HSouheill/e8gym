import 'package:flutter/foundation.dart';

class SecureErrorHandler {
  /// Sanitize error messages for production
  static String sanitizeErrorMessage(String message, {Object? error}) {
    // In debug mode, show full error details
    if (kDebugMode) {
      return message;
    }

    // In production, sanitize error messages
    final sanitizedMessage = _sanitizeMessage(message);
    
    // Log full error details for debugging (but don't show to user)
    if (error != null) {
      print('[SECURITY] Full error details logged: $error');
    }
    
    return sanitizedMessage;
  }

  /// Sanitize specific error messages
  static String _sanitizeMessage(String message) {
    // Common error patterns to sanitize
    final errorPatterns = [
      // Database errors
      RegExp(r'SQL.*error', caseSensitive: false),
      RegExp(r'database.*error', caseSensitive: false),
      RegExp(r'connection.*failed', caseSensitive: false),
      
      // File system errors
      RegExp(r'file.*not.*found', caseSensitive: false),
      RegExp(r'permission.*denied', caseSensitive: false),
      
      // Network errors
      RegExp(r'timeout', caseSensitive: false),
      RegExp(r'connection.*refused', caseSensitive: false),
      
      // Authentication errors
      RegExp(r'invalid.*token', caseSensitive: false),
      RegExp(r'authentication.*failed', caseSensitive: false),
      
      // Generic technical errors
      RegExp(r'exception.*in.*thread', caseSensitive: false),
      RegExp(r'null.*pointer', caseSensitive: false),
      RegExp(r'stack.*overflow', caseSensitive: false),
    ];

    // Check if message contains technical details
    for (final pattern in errorPatterns) {
      if (pattern.hasMatch(message)) {
        return _getGenericErrorMessage(message);
      }
    }

    // If no technical patterns found, return original message
    return message;
  }

  /// Get generic error message based on error type
  static String _getGenericErrorMessage(String originalMessage) {
    final lowerMessage = originalMessage.toLowerCase();
    
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }
    
    if (lowerMessage.contains('authentication') || lowerMessage.contains('login')) {
      return 'Authentication failed. Please log in again.';
    }
    
    if (lowerMessage.contains('permission') || lowerMessage.contains('access')) {
      return 'Access denied. Please contact support if this issue persists.';
    }
    
    if (lowerMessage.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (lowerMessage.contains('server') || lowerMessage.contains('backend')) {
      return 'Server error. Please try again later.';
    }
    
    if (lowerMessage.contains('validation') || lowerMessage.contains('invalid')) {
      return 'Invalid data provided. Please check your input and try again.';
    }
    
    // Generic fallback
    return 'An unexpected error occurred. Please try again or contact support.';
  }

  /// Create user-friendly error response
  static Map<String, dynamic> createSecureErrorResponse({
    required String userMessage,
    required String technicalMessage,
    String? errorCode,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'success': false,
      'message': kDebugMode ? technicalMessage : userMessage,
      'error': kDebugMode ? technicalMessage : 'An error occurred',
      'error_code': errorCode,
      'timestamp': DateTime.now().toIso8601String(),
      if (additionalData != null) ...additionalData,
    };
  }

  /// Handle API errors securely
  static Map<String, dynamic> handleApiError({
    required int statusCode,
    required String responseBody,
    String? originalMessage,
  }) {
    String userMessage;
    String technicalMessage = originalMessage ?? responseBody;

    switch (statusCode) {
      case 400:
        userMessage = 'Invalid request. Please check your input and try again.';
        break;
      case 401:
        userMessage = 'Authentication required. Please log in again.';
        break;
      case 403:
        userMessage = 'Access denied. You don\'t have permission to perform this action.';
        break;
      case 404:
        userMessage = 'The requested resource was not found.';
        break;
      case 409:
        userMessage = 'Conflict detected. The resource may have been modified by another user.';
        break;
      case 422:
        userMessage = 'Validation failed. Please check your input and try again.';
        break;
      case 429:
        userMessage = 'Too many requests. Please wait a moment and try again.';
        break;
      case 500:
        userMessage = 'Server error. Please try again later.';
        break;
      case 502:
      case 503:
      case 504:
        userMessage = 'Service temporarily unavailable. Please try again later.';
        break;
      default:
        userMessage = 'An unexpected error occurred. Please try again.';
    }

    return createSecureErrorResponse(
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      errorCode: statusCode.toString(),
    );
  }

  /// Handle network errors securely
  static Map<String, dynamic> handleNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    
    String userMessage;
    String technicalMessage = error.toString();

    if (errorString.contains('timeout')) {
      userMessage = 'Request timed out. Please check your connection and try again.';
    } else if (errorString.contains('connection') || errorString.contains('network')) {
      userMessage = 'Network error. Please check your internet connection and try again.';
    } else if (errorString.contains('ssl') || errorString.contains('certificate')) {
      userMessage = 'Security error. Please contact support.';
    } else {
      userMessage = 'Network error. Please try again.';
    }

    return createSecureErrorResponse(
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      errorCode: 'NETWORK_ERROR',
    );
  }

  /// Handle validation errors securely
  static Map<String, dynamic> handleValidationError({
    required String field,
    required String error,
  }) {
    final userMessage = 'Invalid $field. Please check your input and try again.';
    final technicalMessage = 'Validation error for $field: $error';

    return createSecureErrorResponse(
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      errorCode: 'VALIDATION_ERROR',
      additionalData: {'field': field},
    );
  }

  /// Log error securely (for debugging)
  static void logError({
    required String context,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      print('[ERROR] Context: $context');
      print('[ERROR] Error: $error');
      if (stackTrace != null) {
        print('[ERROR] Stack trace: $stackTrace');
      }
      if (additionalData != null) {
        print('[ERROR] Additional data: $additionalData');
      }
    } else {
      // In production, log minimal information
      print('[ERROR] Context: $context');
      print('[ERROR] Error type: ${error.runtimeType}');
    }
  }
}
