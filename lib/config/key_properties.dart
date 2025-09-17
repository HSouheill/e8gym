import 'dart:io';

class KeyProperties {
  // Secure keystore configuration
  // These should be set as environment variables in production
  static const String _defaultKeystorePassword = '9Z9ZE8gym';
  static const String _defaultKeyPassword = '9Z9ZE8gym';
  static const String _defaultKeyAlias = 'e8gym-key-alias';
  static const String _defaultStoreFile = 'e8gym-release-key.keystore';

  /// Get keystore password from environment variable or use default
  static String get keystorePassword {
    return Platform.environment['KEYSTORE_PASSWORD'] ?? _defaultKeystorePassword;
  }

  /// Get key password from environment variable or use default
  static String get keyPassword {
    return Platform.environment['KEY_ALIAS_PASSWORD'] ?? _defaultKeyPassword;
  }

  /// Get key alias
  static String get keyAlias {
    return Platform.environment['KEY_ALIAS'] ?? _defaultKeyAlias;
  }

  /// Get store file name
  static String get storeFile {
    return Platform.environment['STORE_FILE'] ?? _defaultStoreFile;
  }

  /// Check if using secure environment variables
  static bool get isUsingSecureConfig {
    return Platform.environment.containsKey('KEYSTORE_PASSWORD') &&
           Platform.environment.containsKey('KEY_ALIAS_PASSWORD');
  }

  /// Get security warning if not using secure config
  static String? get securityWarning {
    if (!isUsingSecureConfig) {
      return 'WARNING: Using default keystore passwords. Set KEYSTORE_PASSWORD and KEY_ALIAS_PASSWORD environment variables for production.';
    }
    return null;
  }
}