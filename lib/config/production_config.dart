import 'package:flutter/foundation.dart';

class ProductionConfig {
  /// Check if running in production mode
  static bool get isProduction => kReleaseMode;
  
  /// Check if running in debug mode
  static bool get isDebug => kDebugMode;
  
  /// Get environment-specific configuration
  static Map<String, dynamic> get config {
    if (isProduction) {
      return _productionConfig;
    } else {
      return _debugConfig;
    }
  }
  
  /// Production configuration
  static const Map<String, dynamic> _productionConfig = {
    'enable_debug_logging': false,
    'enable_error_details': false,
    'enable_network_logging': false,
    'enable_security_logging': true,
    'enable_performance_logging': false,
    'api_timeout': 30000,
    'max_retry_attempts': 3,
    'enable_certificate_pinning': true,
    'enable_biometric_auth': true,
    'session_timeout': 3600000, // 1 hour in milliseconds
  };
  
  /// Debug configuration
  static const Map<String, dynamic> _debugConfig = {
    'enable_debug_logging': true,
    'enable_error_details': true,
    'enable_network_logging': true,
    'enable_security_logging': true,
    'enable_performance_logging': true,
    'api_timeout': 60000,
    'max_retry_attempts': 1,
    'enable_certificate_pinning': false,
    'enable_biometric_auth': false,
    'session_timeout': 7200000, // 2 hours in milliseconds
  };
  
  /// Get configuration value with fallback
  static T getValue<T>(String key, T fallback) {
    final value = config[key];
    if (value is T) {
      return value;
    }
    return fallback;
  }
  
  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    return getValue('enable_$feature', false);
  }
  
  /// Get API timeout
  static int get apiTimeout => getValue('api_timeout', 30000);
  
  /// Get max retry attempts
  static int get maxRetryAttempts => getValue('max_retry_attempts', 3);
  
  /// Get session timeout
  static int get sessionTimeout => getValue('session_timeout', 3600000);
  
  /// Check if debug logging is enabled
  static bool get enableDebugLogging => getValue('enable_debug_logging', false);
  
  /// Check if error details are enabled
  static bool get enableErrorDetails => getValue('enable_error_details', false);
  
  /// Check if network logging is enabled
  static bool get enableNetworkLogging => getValue('enable_network_logging', false);
  
  /// Check if security logging is enabled
  static bool get enableSecurityLogging => getValue('enable_security_logging', true);
  
  /// Check if certificate pinning is enabled
  static bool get enableCertificatePinning => getValue('enable_certificate_pinning', true);
  
  /// Check if biometric auth is enabled
  static bool get enableBiometricAuth => getValue('enable_biometric_auth', true);
}
