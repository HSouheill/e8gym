class ApiConfig {
  // Base URLs for different environments
  // 
  // IMPORTANT: Choose the correct URL based on your setup:
  // 
  // 1. Android Emulator: Use 'http://10.0.2.2:8080'
  //    - 10.0.2.2 is a special IP that maps to your host machine's localhost
  //    - This works when running Flutter app on Android emulator
  // 
  // 2. iOS Simulator: Use 'http://localhost:8080'
  //    - localhost works directly on iOS simulator
  // 
  // 3. Physical Device: Use your computer's local IP address
  //    - Find your computer's IP: ifconfig (Mac/Linux) or ipconfig (Windows)
  //    - Example: 'http://192.168.1.100:8080'
  //    - Make sure your device is on the same WiFi network
  // 
  // 4. Production: Use your actual backend domain with HTTPS
  //    - Example: 'https://api.yourapp.com'
  
  // static const String devBaseUrl = 'http://10.0.2.2:8080'; // For Android emulator
  // static const String localBaseUrl = 'http://localhost:8080'; // For iOS simulator
  // static const String networkBaseUrl = 'http://192.168.0.239:8080'; // For physical device on same network
  static const String productionBaseUrl = 'https://e8gym.online'; // Production URL with HTTPS
  
  // Current environment (change this as needed)
  // Options: 'dev', 'local', 'network', 'production'
  static const String currentEnvironment = 'production';
  
  // Get the appropriate base URL based on current environment
  static String baseUrl = productionBaseUrl;
  // {
  //   switch (currentEnvironment) {
  //     case 'production':
  //       return productionBaseUrl;
  //     default:
  //       return productionBaseUrl; // Default to production for safety
  //   }
  // }
  
  // API Endpoints
  static const String superAdminLogin = '/superadmin/login';
  static const String superAdminLogout = '/api/auth/logout'; // This might need to be different
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
  static const String getBranch = '/api/branches'; // Will be appended with /:id
  static const String updateBranch = '/api/branches'; // Will be appended with /:id
  static const String deleteBranch = '/api/branches'; // Will be appended with /:id
  
  // Standalone Class Management Endpoints
  static const String createStandaloneClass = '/api/standalone-classes';
  static const String getStandaloneClasses = '/api/standalone-classes';
  static const String getStandaloneClass = '/api/standalone-classes'; // Will be appended with /:id
  static const String updateStandaloneClass = '/api/standalone-classes'; // Will be appended with /:id
  static const String deleteStandaloneClass = '/api/standalone-classes'; // Will be appended with /:id
  static const String renewClass = '/api/standalone-classes'; // Will be appended with /:id/renew
  static const String getExpiringClasses = '/api/standalone-classes/expiring';

  // App Settings Endpoints
  static const String getAppSettings = '/settings';
  static const String uploadBackgroundImage = '/settings/background';
  
  // Branch Class Management Endpoints
  static const String getBranchClasses = '/api/branch/classes';
  static const String getBranchClass = '/api/branch/classes'; // Will be appended with /:id
  static const String updateBranchClassSchedule = '/api/branch/classes'; // Will be appended with /:id/schedule
  
  // User Booking Endpoints
  static const String createBooking = '/api/bookings';
  static const String getBooking = '/api/bookings'; // Will be appended with /:id
  static const String cancelBooking = '/api/bookings'; // Will be appended with /:id
  
  // Timeout settings
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'E8Gym/1.0.0', // Add user agent for better tracking
  };
}
