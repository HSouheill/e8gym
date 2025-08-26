class ValidationUtils {
  /// Validates email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validates password strength
  static bool isValidPassword(String password, {int minLength = 8}) {
    if (password.length < minLength) return false;
    
    // Check for at least one uppercase letter, one lowercase letter, and one number
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    
    return hasUppercase && hasLowercase && hasNumber;
  }

  /// Validates phone number format
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length >= 7 && digitsOnly.length <= 15;
  }

  /// Validates country code format
  static bool isValidCountryCode(String countryCode) {
    // Check if it starts with + and has 1-4 digits
    final countryCodeRegex = RegExp(r'^\+[1-9]\d{0,3}$');
    return countryCodeRegex.hasMatch(countryCode);
  }

  /// Validates full name
  static bool isValidFullName(String fullName) {
    return fullName.length >= 2 && fullName.length <= 100;
  }

  /// Validates date of birth (user must be at least 13 years old)
  static bool isValidDateOfBirth(DateTime dateOfBirth) {
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    
    // Check if birthday has occurred this year
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      return age - 1 >= 13;
    }
    
    return age >= 13;
  }

  /// Gets validation error message for a field
  static String? getValidationError(String fieldName, String value, {DateTime? dateOfBirth}) {
    switch (fieldName.toLowerCase()) {
      case 'fullname':
        if (!isValidFullName(value)) {
          return 'Full name must be between 2 and 100 characters';
        }
        break;
      case 'email':
        if (!isValidEmail(value)) {
          return 'Please enter a valid email address';
        }
        break;
      case 'password':
        if (!isValidPassword(value)) {
          return 'Password must be at least 8 characters with uppercase, lowercase, and number';
        }
        break;
      case 'phonenumber':
        if (!isValidPhoneNumber(value)) {
          return 'Please enter a valid phone number';
        }
        break;
      case 'countrycode':
        if (!isValidCountryCode(value)) {
          return 'Please enter a valid country code (e.g., +961)';
        }
        break;
      case 'dateofbirth':
        if (dateOfBirth != null && !isValidDateOfBirth(dateOfBirth)) {
          return 'You must be at least 13 years old to register';
        }
        break;
    }
    return null;
  }
}
