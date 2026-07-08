class ApiConfig {

  static const String productionBaseUrl = 'https://e8gym.online'; 
  

  static const String currentEnvironment = 'production';
  
  static String baseUrl = productionBaseUrl;

  
  // API Endpoints
  static const String superAdminLogin = '/superadmin/login';
  static const String superAdminLogout = '/api/auth/logout'; // This might need to be different
  static const String superAdminChangePassword = '/superadmin/change-password';
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
  static const String uploadSuperAdminBackgroundImage = '/settings/background/superadmin';
  static const String uploadBranchBackgroundImage = '/settings/background/branch';
  static const String uploadUserBackgroundImage = '/settings/background/user';
  
  // Branch Class Management Endpoints
  static const String getBranchClasses = '/api/branch/classes';
  static const String getBranchClass = '/api/branch/classes'; // Will be appended with /:id
  static const String updateBranchClassSchedule = '/api/branch/classes'; // Will be appended with /:id/schedule
  static const String updateBranchClassInstructor = '/api/branch/classes'; // Will be appended with /:id/instructor
  static const String updateBranchClass = '/api/branch/classes'; // Will be appended with /:branchId/:classId
  static const String bulkUpdateClassTime = '/api/branch/classes/bulk-update-time';
  
  // User Booking Endpoints
  static const String createBooking = '/api/bookings';
  static const String getBooking = '/api/bookings'; // Will be appended with /:id
  static const String updateBooking = '/api/bookings'; // Will be appended with /:id
  static const String cancelBooking = '/api/bookings'; // Will be appended with /:id
  static const String getClassSchedules = '/api/classes'; // Will be appended with /:classId/schedules
  
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
