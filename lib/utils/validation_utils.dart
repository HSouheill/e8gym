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

  /// Validates class schedule times
  static bool isValidScheduleTime(DateTime startTime, DateTime endTime) {
    return startTime.isBefore(endTime);
  }

  /// Validates class schedule for overlapping times on the same day
  static bool hasOverlappingSchedules(List<Map<String, dynamic>> schedules) {
    for (int i = 0; i < schedules.length; i++) {
      for (int j = i + 1; j < schedules.length; j++) {
        if (schedules[i]['dayOfWeek'] == schedules[j]['dayOfWeek']) {
          final start1 = schedules[i]['startTime'] as DateTime;
          final end1 = schedules[i]['endTime'] as DateTime;
          final start2 = schedules[j]['startTime'] as DateTime;
          final end2 = schedules[j]['endTime'] as DateTime;
          
          if (start1.isBefore(end2) && end1.isAfter(start2)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Validates class capacity
  static bool isValidClassCapacity(int capacity) {
    return capacity > 0 && capacity <= 100;
  }

  /// Validates class duration
  static bool isValidClassDuration(int duration) {
    return duration > 0 && duration <= 480; // Max 8 hours
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
