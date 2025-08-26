class ApiConfig {
  // Base URLs for different environments
  static const String devBaseUrl = 'http://localhost:8080';
  static const String stagingBaseUrl = 'https://staging-api.e8gym.com';
  static const String productionBaseUrl = 'https://api.e8gym.com';
  
  // Current environment (change this as needed)
  static const String currentEnvironment = 'dev';
  
  // Get the appropriate base URL based on current environment
  static String get baseUrl {
    switch (currentEnvironment) {
      case 'dev':
        return devBaseUrl;
      case 'staging':
        return stagingBaseUrl;
      case 'production':
        return productionBaseUrl;
      default:
        return devBaseUrl;
    }
  }
  
  // API Endpoints
  static const String superAdminLogin = '/superadmin/login';
  static const String adminLogin = '/admin/login';
  static const String createAdmin = '/superadmin/create-admin';
  
  // Branch Authentication Endpoints
  static const String branchLogin = '/api/branch-auth/login';
  static const String branchLogout = '/api/branch-auth/logout';
  static const String branchForgotPassword = '/api/branch-auth/forgot-password';
  static const String branchResetPassword = '/api/branch-auth/reset-password';
  static const String branchResendOTP = '/api/branch-auth/resend-otp';
  
  // Branch Management Endpoints
  static const String createBranch = '/api/branches';
  static const String getBranches = '/api/branches';
  
  // Timeout settings
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
