class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'http://localhost:8080'; // Change this to your actual backend URL
  
  // API endpoints
  static const String signup = '/api/auth/signup';
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Rate limiting
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
