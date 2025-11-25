import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/standalone_class_models.dart';
import '../models/branch_class_models.dart';
import '../models/booking_models.dart';
import '../models/auth_models.dart';
import '../utils/secure_logger.dart';
import '../utils/secure_error_handler.dart';
import 'security_service.dart';
import '../config/api_config.dart' as cfg;

class ApiService {
  
  // Test connection to backend
  static Future<bool> testConnection() async {
    try {
      SecureLogger.debug('Testing Backend Connection', data: {'url': ApiConfig.baseUrl});
      
      // Validate production domain
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/health')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/health'});
        return false;
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(null);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'), // Assuming you have a health endpoint
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      SecureLogger.apiResponse(response.statusCode, '${ApiConfig.baseUrl}/health', body: response.body);
      
      return response.statusCode == 200;
    } catch (e) {
      SecurityService.logSecurityEvent('connection_test_failed', details: {'error': e.toString()});
      SecureLogger.error('Connection test failed', error: e);
      SecureErrorHandler.logError(
        context: 'testConnection',
        error: e,
        additionalData: {'url': ApiConfig.baseUrl},
      );
      return false;
    }
  }

  // App Settings: GET current settings
  static Future<Map<String, dynamic>> getAppSettings(String accessToken) async {
    try {
      if (!SecurityService.validateSSLCertificate('${cfg.ApiConfig.baseUrl}${cfg.ApiConfig.getAppSettings}')) {
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      final headers = SecurityService.getSecurityHeaders(accessToken);
      final response = await http.get(
        Uri.parse('${cfg.ApiConfig.baseUrl}${cfg.ApiConfig.getAppSettings}'),
        headers: headers,
      );

      SecureLogger.apiResponse(response.statusCode, '${cfg.ApiConfig.baseUrl}${cfg.ApiConfig.getAppSettings}', body: response.body);

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data['data'],
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // App Settings: Upload background image (multipart)
  static Future<Map<String, dynamic>> uploadBackgroundImage({required String accessToken, required File imageFile}) async {
    try {
      final url = Uri.parse('${cfg.ApiConfig.baseUrl}${cfg.ApiConfig.uploadBackgroundImage}');
      if (!SecurityService.validateSSLCertificate(url.toString())) {
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }

      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers.remove('Content-Type');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      SecureLogger.apiResponse(response.statusCode, url.toString(), body: response.body);

      if (response.statusCode == 413) {
        return {
          'success': false,
          'message': 'Image is too large for the server (413). Please choose a smaller image.',
          'error': 'request_entity_too_large',
        };
      }

      try {
        final data = jsonDecode(response.body);
        return {
          'success': response.statusCode == 200,
          'data': data['data'],
          'message': data['message'] ?? '',
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Upload failed. Unexpected server response.',
          'error': e.toString(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }
  
  // SuperAdmin Login
  static Future<Map<String, dynamic>> superAdminLogin(String email, String password) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(email) || !SecurityService.validateInput(password)) {
        SecurityService.logSecurityEvent('invalid_login_input', details: {'email_length': email.length, 'password_length': password.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(email);
      
      SecureLogger.debug('SuperAdmin Login', data: {
        'email': sanitizedEmail,
        'password_length': password.length,
        'url': '${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}'
      });
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(null);
      headers['X-Device-ID'] = deviceId;
      
      final requestBody = {
        'email': sanitizedEmail,
        'password': password,
        'device_id': deviceId,
      };
      SecureLogger.apiRequest('POST', '${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}', body: requestBody);
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      SecureLogger.apiResponse(response.statusCode, '${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}', body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store tokens securely if login successful
        if (data['data'] != null && data['data']['access_token'] != null) {
          await SecurityService.storeAccessToken(data['data']['access_token']);
          if (data['data']['refresh_token'] != null) {
            await SecurityService.storeRefreshToken(data['data']['refresh_token']);
          }
        }
        
        SecurityService.logSecurityEvent('login_successful', details: {'user_type': 'super_admin'});
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        SecurityService.logSecurityEvent('login_failed', details: {'status_code': response.statusCode, 'error': errorData['error']});
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      SecurityService.logSecurityEvent('login_exception', details: {'error': e.toString()});
      print('Exception in superAdminLogin: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Regular Admin Login (if you have a separate endpoint)
  static Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(email) || !SecurityService.validateInput(password)) {
        SecurityService.logSecurityEvent('invalid_login_input', details: {'email_length': email.length, 'password_length': password.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(email);
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.adminLogin}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.adminLogin}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(null);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminLogin}'),
        headers: headers,
        body: jsonEncode({
          'email': sanitizedEmail,
          'password': password,
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Branch Login
  static Future<Map<String, dynamic>> branchLogin(String email, String password) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(email) || !SecurityService.validateInput(password)) {
        SecurityService.logSecurityEvent('invalid_login_input', details: {'email_length': email.length, 'password_length': password.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(email);
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.branchLogin}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchLogin}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(null);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchLogin}'),
        headers: headers,
        body: jsonEncode({
          'email': sanitizedEmail,
          'password': password,
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        // Handle different error types based on status code
        String errorMessage = errorData['message'] ?? 'Login failed';
        
        // Map backend error messages to user-friendly messages
        if (response.statusCode == 403) {
          // Forbidden - account inactive or access denied
          if (errorData['message']?.toString().toLowerCase().contains('inactive') ?? false) {
            errorMessage = 'This account is not active. Please contact your administrator.';
          } else if (errorData['message']?.toString().toLowerCase().contains('access denied') ?? false) {
            errorMessage = 'Access denied. Only team members with admin or viewer role can login.';
          }
        } else if (response.statusCode == 401) {
          // Unauthorized - invalid credentials
          errorMessage = 'Invalid email or password. Please try again.';
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Branch Logout
  static Future<Map<String, dynamic>> branchLogout(String accessToken) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.branchLogout}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchLogout}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchLogout}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        
        // If token is expired, consider this a successful logout
        if (response.statusCode == 401 && 
            (errorData['error']?.toString().contains('expired') == true ||
             errorData['message']?.toString().contains('expired') == true)) {
          print('Token expired, treating as successful logout');
          return {
            'success': true,
            'message': 'Logged out successfully (token was expired)',
          };
        }
        
        return {
          'success': false,
          'message': errorData['message'] ?? 'Logout failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Branch Forgot Password
  static Future<Map<String, dynamic>> branchForgotPassword(String email) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(email)) {
        SecurityService.logSecurityEvent('invalid_email_input', details: {'email_length': email.length});
        return {
          'success': false,
          'message': 'Invalid email data',
          'error': 'Input validation failed',
        };
      }
      
      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(email);
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.branchForgotPassword}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchForgotPassword}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(null);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchForgotPassword}'),
        headers: headers,
        body: jsonEncode({
          'email': sanitizedEmail,
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Password reset request failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Branch Reset Password
  static Future<Map<String, dynamic>> branchResetPassword(String email, String otp, String password) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(email) || !SecurityService.validateInput(otp) || !SecurityService.validateInput(password)) {
        SecurityService.logSecurityEvent('invalid_reset_input', details: {'email_length': email.length, 'otp_length': otp.length, 'password_length': password.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(email);
      final sanitizedOtp = SecurityService.sanitizeInput(otp);
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.branchResetPassword}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchResetPassword}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(null);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchResetPassword}'),
        headers: headers,
        body: jsonEncode({
          'email': sanitizedEmail,
          'otp': sanitizedOtp,
          'password': password,
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Password reset failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Branch Resend OTP
  static Future<Map<String, dynamic>> branchResendOTP(String email) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(email)) {
        SecurityService.logSecurityEvent('invalid_email_input', details: {'email_length': email.length});
        return {
          'success': false,
          'message': 'Invalid email data',
          'error': 'Input validation failed',
        };
      }
      
      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(email);
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.branchResendOTP}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchResendOTP}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(null);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchResendOTP}'),
        headers: headers,
        body: jsonEncode({
          'email': sanitizedEmail,
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'OTP resend failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Create Branch (SuperAdmin only)
  static Future<Map<String, dynamic>> createBranch(
    Map<String, dynamic> branchData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.createBranch}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.createBranch}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      print('=== API Service Create Branch Debug ===');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.createBranch}');
      print('Request data: ${jsonEncode(branchData)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createBranch}'),
        headers: headers,
        body: jsonEncode(branchData),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Branch creation failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
      }
    }

  // Get Branches for Signup (public endpoint)
  static Future<Map<String, dynamic>> getBranchesForSignup() async {
    try {
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/auth/branches')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/auth/branches'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(null);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/branches'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branches',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Branches (SuperAdmin only)
  static Future<Map<String, dynamic>> getBranches(
    String accessToken, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      if (search != null && !SecurityService.validateInput(search)) {
        SecurityService.logSecurityEvent('invalid_search_input', details: {'search_length': search.length});
        return {
          'success': false,
          'message': 'Invalid search data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.getBranches}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBranches}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = SecurityService.sanitizeInput(search);
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBranches}')
          .replace(queryParameters: queryParams);

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branches',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Single Branch (SuperAdmin only)
  static Future<Map<String, dynamic>> getBranch(
    String branchId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_branch_input', details: {'branch_id_length': branchId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.getBranch}/$branchId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBranch}/$branchId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBranch}/$branchId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branch',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Update Branch (SuperAdmin only)
  static Future<Map<String, dynamic>> updateBranch(
    String branchId,
    Map<String, dynamic> updateData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_branch_update_input', details: {'branch_id_length': branchId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== API Service Update Branch Debug ===');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId');
      print('Request data: ${jsonEncode(updateData)}');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId'),
        headers: headers,
        body: jsonEncode(updateData),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update branch',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
      }
    }

  // Delete Branch (SuperAdmin only)
  static Future<Map<String, dynamic>> deleteBranch(
    String branchId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_branch_delete_input', details: {'branch_id_length': branchId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.deleteBranch}/$branchId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.deleteBranch}/$branchId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deleteBranch}/$branchId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete branch',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Create Standalone Class (SuperAdmin only)
  static Future<Map<String, dynamic>> createStandaloneClass(
    CreateStandaloneClassRequest classData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.createStandaloneClass}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.createStandaloneClass}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final requestBody = classData.toJson();
      print('=== CreateStandaloneClass Debug ===');
      print('Request body: ${jsonEncode(requestBody)}');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createStandaloneClass}'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Class creation failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Standalone Classes (SuperAdmin only)
  // For user-facing calls, set onlyVisible=true to filter out hidden classes
  static Future<Map<String, dynamic>> getStandaloneClasses(
    String accessToken, {
    int page = 1,
    int limit = 20,
    String? search,
    String? dateFilter,
    String? startDate,
    String? endDate,
    bool onlyVisible = false, // Filter to only show visible classes (for user-facing calls)
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      if (search != null && !SecurityService.validateInput(search)) {
        SecurityService.logSecurityEvent('invalid_search_input', details: {'search_length': search.length});
        return {
          'success': false,
          'message': 'Invalid search data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.getStandaloneClasses}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getStandaloneClasses}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = SecurityService.sanitizeInput(search);
      }
      if (dateFilter != null && dateFilter.isNotEmpty) {
        queryParams['date'] = SecurityService.sanitizeInput(dateFilter);
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = SecurityService.sanitizeInput(startDate);
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = SecurityService.sanitizeInput(endDate);
      }
      // Add visibility filter for user-facing calls
      if (onlyVisible) {
        queryParams['is_visible'] = 'true';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getStandaloneClasses}')
          .replace(queryParameters: queryParams);

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Client-side filtering as fallback if backend doesn't support is_visible parameter
        if (onlyVisible && data['data'] != null && data['data'] is Map) {
          try {
            final responseData = data['data'] as Map<String, dynamic>;
            if (responseData['classes'] != null && responseData['classes'] is List) {
              final classesList = responseData['classes'] as List<dynamic>;
              // Filter out hidden classes (isVisible == false)
              final visibleClasses = classesList.where((classJson) {
                if (classJson is Map) {
                  final isVisible = classJson['is_visible'] ?? classJson['IsVisible'] ?? true;
                  return isVisible == true;
                }
                return true; // Keep if we can't determine visibility
              }).toList();
              
              // Update the data with filtered classes
              final filteredData = {
                ...responseData,
                'classes': visibleClasses,
                'total': visibleClasses.length,
              };
              
              return {
                'success': true,
                'data': filteredData,
                'message': data['message'],
              };
            }
          } catch (e) {
            // If filtering fails, return original data
            print('Error filtering classes by visibility: $e');
          }
        }
        
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch classes',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Single Standalone Class (SuperAdmin only)
  static Future<Map<String, dynamic>> getStandaloneClass(
    String classId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_class_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.getStandaloneClass}/$classId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getStandaloneClass}/$classId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getStandaloneClass}/$classId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch class',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Update Standalone Class (SuperAdmin only)
  static Future<Map<String, dynamic>> updateStandaloneClass(
    String classId,
    UpdateStandaloneClassRequest updateData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_class_update_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final requestBody = jsonEncode(updateData.toJson());
      print('=== API Request Debug ===');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId');
      print('Headers: $headers');
      print('Request Body: $requestBody');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId'),
        headers: headers,
        body: requestBody,
      );

      print('=== API Response Debug ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update class',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Delete Standalone Class (SuperAdmin only)
  static Future<Map<String, dynamic>> deleteStandaloneClass(
    String classId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_class_delete_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.deleteStandaloneClass}/$classId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.deleteStandaloneClass}/$classId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deleteStandaloneClass}/$classId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete class',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // SuperAdmin Logout
  static Future<Map<String, dynamic>> superAdminLogout(String accessToken) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== SuperAdmin Logout Debug ===');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}');
      print('Token received: ${accessToken.substring(0, 20)}...');
      print('Token length: ${accessToken.length}');
      
      // Ensure token doesn't already have Bearer prefix
      final cleanToken = accessToken.startsWith('Bearer ') 
          ? accessToken.substring(7) 
          : accessToken;
      print('Clean token: ${cleanToken.substring(0, 20)}...');
      print('Authorization header: Bearer ${cleanToken.substring(0, 20)}...');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(cleanToken);
      headers['X-Device-ID'] = deviceId;
      print('Headers: $headers');
      
      // Try the main logout endpoint first
      var response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // If the main endpoint fails, try alternative endpoints
      if (response.statusCode != 200) {
        print('Main logout endpoint failed, trying alternatives...');
        
        // Try superadmin-specific logout endpoint
        final alternativeEndpoints = [
          '/superadmin/logout',
          '/api/superadmin/logout',
          '/api/auth/superadmin/logout',
        ];
        
        for (final endpoint in alternativeEndpoints) {
          print('Trying endpoint: $endpoint');
          try {
            response = await http.post(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
            );
            
            print('Alternative endpoint $endpoint response: ${response.statusCode}');
            if (response.statusCode == 200) {
              print('Alternative endpoint $endpoint succeeded!');
              break;
            }
          } catch (e) {
            print('Alternative endpoint $endpoint failed: $e');
          }
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('Error response: $errorData');
        
        // If token is expired, consider this a successful logout
        if (response.statusCode == 401 && 
            (errorData['error']?.toString().contains('expired') == true ||
             errorData['message']?.toString().contains('expired') == true)) {
          print('Token expired, treating as successful logout');
          return {
            'success': true,
            'message': 'Logged out successfully (token was expired)',
          };
        }
        
        return {
          'success': false,
          'message': errorData['message'] ?? 'Logout failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get SuperAdmin Users
  static Future<Map<String, dynamic>> getSuperAdminUsers(
    String accessToken, {
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? isActive,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      if (search != null && !SecurityService.validateInput(search)) {
        SecurityService.logSecurityEvent('invalid_search_input', details: {'search_length': search.length});
        return {
          'success': false,
          'message': 'Invalid search data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/superadmin/users')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/superadmin/users'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Get SuperAdmin Users Debug ===');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = SecurityService.sanitizeInput(search);
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = SecurityService.sanitizeInput(role);
      }
      if (isActive != null && isActive.isNotEmpty) {
        queryParams['is_active'] = SecurityService.sanitizeInput(isActive);
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/superadmin/users').replace(queryParameters: queryParams);
      print('URL: $uri');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      print('Headers: $headers');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to retrieve users',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in getSuperAdminUsers: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Branches With Users (SuperAdmin)
  static Future<Map<String, dynamic>> getBranchesWithUsers(
    String accessToken, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      if (search != null && !SecurityService.validateInput(search)) {
        SecurityService.logSecurityEvent('invalid_search_input', details: {'search_length': search.length});
        return {
          'success': false,
          'message': 'Invalid search data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/branches/with-users')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/branches/with-users'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Get Branches With Users Debug ===');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = SecurityService.sanitizeInput(search);
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/branches/with-users').replace(queryParameters: queryParams);
      print('URL: $uri');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      print('Headers: $headers');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to retrieve branches with users',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in getBranchesWithUsers: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Admin Bookings
  static Future<Map<String, dynamic>> getAdminBookings(
    String accessToken, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/admin/bookings/classes-with-users')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/admin/bookings/classes-with-users'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Get Admin Bookings Debug ===');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/bookings/classes-with-users').replace(queryParameters: queryParams);
      print('URL: $uri');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      print('Headers: $headers');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to retrieve bookings',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in getAdminBookings: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Renew Standalone Class (SuperAdmin only)
  static Future<Map<String, dynamic>> renewClass(
    String classId,
    RenewClassRequest renewData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_class_renew_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.renewClass}/$classId/renew')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.renewClass}/$classId/renew'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.renewClass}/$classId/renew'),
        headers: headers,
        body: jsonEncode(renewData.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to renew class',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Expiring Classes (SuperAdmin only)
  static Future<Map<String, dynamic>> getExpiringClasses(
    String accessToken, {
    int daysThreshold = 7,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.getExpiringClasses}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getExpiringClasses}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getExpiringClasses}')
          .replace(queryParameters: {'days': daysThreshold.toString()});

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch expiring classes',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Branch Class Management Methods

  // Get Branch Classes (Branch Admin only)
  static Future<Map<String, dynamic>> getBranchClasses(
    String accessToken, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.getBranchClasses}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBranchClasses}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBranchClasses}')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branch classes',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get User's Branch Classes (based on signup selection)
  static Future<Map<String, dynamic>> getUserBranchClasses(
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/auth/branch-classes')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/auth/branch-classes'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/branch-classes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch user branch classes',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Classes for Specific Branch (User)
  static Future<Map<String, dynamic>> getBranchClassesForUser(
    String branchId,
    String accessToken, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_branch_user_input', details: {'branch_id_length': branchId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/branches/$branchId/classes')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/branches/$branchId/classes'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/branches/$branchId/classes')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branch classes',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Single Branch Class (Branch Admin only)
  static Future<Map<String, dynamic>> getBranchClass(
    String classId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_branch_class_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.getBranchClass}/$classId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBranchClass}/$classId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBranchClass}/$classId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branch class',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Update Branch Class Schedule (Branch Admin only)
  static Future<Map<String, dynamic>> updateBranchClassSchedule(
    String classId,
    UpdateClassScheduleRequest scheduleData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_schedule_update_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Update Branch Class Schedule Debug ===');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule');
      print('Request body: ${jsonEncode(scheduleData.toJson())}');
      print('Schedule count: ${scheduleData.schedule.length}');
      for (int i = 0; i < scheduleData.schedule.length; i++) {
        final schedule = scheduleData.schedule[i];
        print('Schedule $i: dayOfWeek=${schedule.dayOfWeek}, date=${schedule.date}, startTime=${schedule.startTime}, endTime=${schedule.endTime}');
        print('Schedule $i JSON: ${jsonEncode(schedule.toJson())}');
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule'),
        headers: headers,
        body: jsonEncode(scheduleData.toJson()),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          print('Error message: ${errorData['message']}');
          print('Error details: ${errorData['error']}');
        } catch (e) {
          print('Failed to parse error response: $e');
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update class schedule',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Update Branch Class Instructor (Branch Admin only)
  static Future<Map<String, dynamic>> updateBranchClassInstructor(
    String classId,
    UpdateClassInstructorRequest instructorData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_instructor_update_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassInstructor}/$classId/instructor')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateBranchClassInstructor}/$classId/instructor'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Update Branch Class Instructor Debug ===');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.updateBranchClassInstructor}/$classId/instructor');
      print('Request body: ${jsonEncode(instructorData.toJson())}');
      print('Instructor: ${instructorData.instructor}');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassInstructor}/$classId/instructor'),
        headers: headers,
        body: jsonEncode(instructorData.toJson()),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          print('Error message: ${errorData['message']}');
          print('Error details: ${errorData['error']}');
        } catch (e) {
          print('Failed to parse error response: $e');
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update class instructor',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Update Branch Class with Recurring Schedule (Branch Admin only)
  static Future<Map<String, dynamic>> updateBranchClassRecurring(
    String branchId,
    String classId,
    UpdateClassRecurringRequest recurringData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || 
          !SecurityService.validateInput(classId) || 
          !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_recurring_update_input', 
          details: {
            'branch_id_length': branchId.length, 
            'class_id_length': classId.length, 
            'token_length': accessToken.length
          });
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      // Backend route: /api/branches/:branchId/classes/:classId
      final url = '${ApiConfig.baseUrl}${ApiConfig.updateBranchClass}/$branchId/classes/$classId';
      if (!SecurityService.validateSSLCertificate(url)) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Update Branch Class Recurring Schedule Debug ===');
      print('URL: $url');
      print('Request body: ${jsonEncode(recurringData.toJson())}');
      print('Day of Week: ${recurringData.dayOfWeek}');
      print('New Start Time: ${recurringData.newStartTime}');
      print('New End Time: ${recurringData.newEndTime}');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(recurringData.toJson()),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          print('Error message: ${errorData['message']}');
          print('Error details: ${errorData['error']}');
        } catch (e) {
          print('Failed to parse error response: $e');
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update recurring schedule',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Bulk Update Class Time by Day of Week (Branch Admin only)
  static Future<Map<String, dynamic>> bulkUpdateClassTime(
    BulkUpdateClassTimeRequest bulkUpdateData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken) ||
          bulkUpdateData.dayOfWeek < 0 ||
          bulkUpdateData.dayOfWeek > 6) {
        SecurityService.logSecurityEvent('invalid_bulk_update_input',
          details: {
            'day_of_week': bulkUpdateData.dayOfWeek,
            'token_length': accessToken.length,
          });
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }

      // Validate SSL certificate
      final url = '${ApiConfig.baseUrl}${ApiConfig.bulkUpdateClassTime}';
      if (!SecurityService.validateSSLCertificate(url)) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }

      print('=== Bulk Update Class Time Debug ===');
      print('URL: $url');
      print('Request body: ${jsonEncode(bulkUpdateData.toJson())}');
      print('Day of Week: ${bulkUpdateData.dayOfWeek}');
      print('New Start Time: ${bulkUpdateData.newStartTime}');
      print('New End Time: ${bulkUpdateData.newEndTime}');

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(bulkUpdateData.toJson()),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          print('Error message: ${errorData['message']}');
          print('Error details: ${errorData['error']}');
        } catch (e) {
          print('Failed to parse error response: $e');
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to bulk update class times',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Toggle Standalone Class Visibility
  static Future<Map<String, dynamic>> toggleStandaloneClassVisibility(
    String classId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_toggle_visibility_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      final url = '${ApiConfig.baseUrl}/api/standalone-classes/$classId/toggle-visibility';
      if (!SecurityService.validateSSLCertificate(url)) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to toggle class visibility',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Toggle Branch Class Visibility (for branch admin)
  static Future<Map<String, dynamic>> toggleBranchClassVisibility(
    String classId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_toggle_visibility_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      final url = '${ApiConfig.baseUrl}/api/branch/classes/$classId/toggle-visibility';
      if (!SecurityService.validateSSLCertificate(url)) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to toggle class visibility',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Toggle Branch Class Visibility (for super admin - branch ID in URL path)
  static Future<Map<String, dynamic>> toggleBranchClassVisibilityForSuperAdmin(
    String branchId,
    String classId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || !SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_toggle_visibility_input', details: {'branch_id_length': branchId.length, 'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Super admin endpoint: /api/branches/:branchId/classes/:classId/toggle-visibility
      final url = '${ApiConfig.baseUrl}/api/branches/$branchId/classes/$classId/toggle-visibility';
      
      print('=== Toggle Branch Class Visibility (Super Admin) ===');
      print('URL: $url');
      print('Branch ID: $branchId');
      print('Class ID: $classId');
      
      if (!SecurityService.validateSSLCertificate(url)) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      print('Headers: ${headers.keys}');
      print('Request method: PATCH');
      
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to toggle class visibility',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Class Schedules (User)
  static Future<Map<String, dynamic>> getClassSchedules(
    String classId,
    String classType,
    String? branchId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_class_schedules_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Build query parameters
      final queryParams = <String, String>{
        'class_type': classType,
      };
      
      if (classType == 'branch' && branchId != null) {
        queryParams['branch_id'] = branchId;
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getClassSchedules}/$classId/schedules')
          .replace(queryParameters: queryParams);
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate(uri.toString())) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': uri.toString()});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Class schedules retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get class schedules',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Create Booking (User)
  static Future<Map<String, dynamic>> createBooking(
    CreateBookingRequest request,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.createBooking}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.createBooking}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createBooking}'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create booking',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Booking (User)
  static Future<Map<String, dynamic>> getBooking(
    String bookingId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(bookingId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_booking_input', details: {'booking_id_length': bookingId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.getBooking}/$bookingId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBooking}/$bookingId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBooking}/$bookingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch booking',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get User Bookings
  static Future<Map<String, dynamic>> getUserBookings(
    String accessToken, {
    int page = 1,
    int limit = 100,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/bookings')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/bookings'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Add optional query parameters
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = SecurityService.sanitizeInput(status);
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['date_from'] = SecurityService.sanitizeInput(dateFrom);
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['date_to'] = SecurityService.sanitizeInput(dateTo);
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/bookings').replace(queryParameters: queryParams);
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch user bookings',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Cancel Booking (User)
  static Future<Map<String, dynamic>> cancelBooking(
    String bookingId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(bookingId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_booking_cancel_input', details: {'booking_id_length': bookingId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.cancelBooking}/$bookingId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.cancelBooking}/$bookingId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cancelBooking}/$bookingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to cancel booking',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // ===== BRANCH USER ENDPOINTS =====

  // Get Branch Users
  static Future<Map<String, dynamic>> getBranchUsers(
    String accessToken, {
    int page = 1,
    int limit = 10,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      if (search != null && !SecurityService.validateInput(search)) {
        SecurityService.logSecurityEvent('invalid_search_input', details: {'search_length': search.length});
        return {
          'success': false,
          'message': 'Invalid search data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/branch/users')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/branch/users'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = SecurityService.sanitizeInput(search);
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['date_from'] = SecurityService.sanitizeInput(dateFrom);
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['date_to'] = SecurityService.sanitizeInput(dateTo);
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/branch/users').replace(queryParameters: queryParams);

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branch users',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Branch User Stats
  static Future<Map<String, dynamic>> getBranchUserStats(String accessToken) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/branch/users/stats')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/branch/users/stats'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/branch/users/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branch user stats',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Branch User Detail
  static Future<Map<String, dynamic>> getBranchUserDetail(
    String userId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(userId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_user_detail_input', details: {'user_id_length': userId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/branch/users/$userId')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/branch/users/$userId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/branch/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branch user detail',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get Branch User Bookings
  static Future<Map<String, dynamic>> getBranchUserBookings(
    String userId,
    String accessToken, {
    int page = 1,
    int limit = 10,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? classDate,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(userId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_user_bookings_input', details: {'user_id_length': userId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/branch/users/$userId/bookings')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/branch/users/$userId/bookings'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = SecurityService.sanitizeInput(status);
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['date_from'] = SecurityService.sanitizeInput(dateFrom);
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['date_to'] = SecurityService.sanitizeInput(dateTo);
      }
      if (classDate != null && classDate.isNotEmpty) {
        queryParams['class_date'] = SecurityService.sanitizeInput(classDate);
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/branch/users/$userId/bookings').replace(queryParameters: queryParams);

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch branch user bookings',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Upload SuperAdmin Profile Image
  static Future<Map<String, dynamic>> uploadSuperAdminImage(
    File imageFile,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/superadmin/upload-image')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/superadmin/upload-image'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Upload SuperAdmin Image Debug ===');
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      
      // Check if file exists
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'message': 'Image file not found',
          'error': 'File does not exist',
        };
      }
      
      // Get file size
      final fileSize = await imageFile.length();
      print('File size: ${fileSize} bytes');
      
      // Validate file size (max 5MB)
      if (fileSize > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Image file too large. Maximum size is 5MB.',
          'error': 'File size exceeds limit',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/superadmin/upload-image'),
      );
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      print('Sending request to: ${request.url}');
      print('Headers: ${request.headers}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload image',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in uploadSuperAdminImage: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Upload Branch Image
  static Future<Map<String, dynamic>> uploadBranchImage(
    String branchId,
    File imageFile,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken) || !SecurityService.validateInput(branchId)) {
        SecurityService.logSecurityEvent('invalid_branch_upload_input', details: {'token_length': accessToken.length, 'branch_id_length': branchId.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/branches/$branchId/upload-image')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/branches/$branchId/upload-image'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Upload Branch Image Debug ===');
      print('Branch ID: $branchId');
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      
      // Check if file exists
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'message': 'Image file not found',
          'error': 'File does not exist',
        };
      }
      
      // Get file size
      final fileSize = await imageFile.length();
      print('File size: ${fileSize} bytes');
      
      // Validate file size (max 5MB)
      if (fileSize > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Image file too large. Maximum size is 5MB.',
          'error': 'File size exceeds limit',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/branches/$branchId/upload-image'),
      );
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'branch_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      print('Sending request to: ${request.url}');
      print('Headers: ${request.headers}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload branch image',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in uploadBranchImage: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Upload Team Member Image
  static Future<Map<String, dynamic>> uploadTeamMemberImage(
    String branchId,
    String teamMemberId,
    File imageFile,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken) || 
          !SecurityService.validateInput(branchId) || 
          !SecurityService.validateInput(teamMemberId)) {
        SecurityService.logSecurityEvent('invalid_team_member_upload_input', details: {
          'token_length': accessToken.length, 
          'branch_id_length': branchId.length,
          'team_member_id_length': teamMemberId.length
        });
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/branches/$branchId/team-members/$teamMemberId/upload-image')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/branches/$branchId/team-members/$teamMemberId/upload-image'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }
      
      print('=== Upload Team Member Image Debug ===');
      print('Branch ID: $branchId');
      print('Team Member ID: $teamMemberId');
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      
      // Check if file exists
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'message': 'Image file not found',
          'error': 'File does not exist',
        };
      }
      
      // Get file size
      final fileSize = await imageFile.length();
      print('File size: ${fileSize} bytes');
      
      // Validate file size (max 5MB)
      if (fileSize > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Image file too large. Maximum size is 5MB.',
          'error': 'File size exceeds limit',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/branches/$branchId/team-members/$teamMemberId/upload-image'),
      );
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'team_member_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      print('Sending request to: ${request.url}');
      print('Headers: ${request.headers}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload team member image',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in uploadTeamMemberImage: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Upload Standalone Class Image
  static Future<Map<String, dynamic>> uploadStandaloneClassImage(
    File imageFile,
    String classId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_class_image_input', details: {'class_id_length': classId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }

      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/standalone-classes/$classId/upload-image')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/standalone-classes/$classId/upload-image'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }

      print('=== Upload Standalone Class Image Debug ===');
      print('Class ID: $classId');
      print('Image file: ${imageFile.path}');
      print('File size: ${await imageFile.length()} bytes');

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      // Remove Content-Type header to let multipart/form-data be set automatically
      headers.remove('Content-Type');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/standalone-classes/$classId/upload-image'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add image file
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'class_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      print('=== Sending Request ===');
      print('URL: ${request.url}');
      print('Headers: ${request.headers}');
      print('Files: ${request.files.length}');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== Response Debug ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Image uploaded successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload class image',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in uploadStandaloneClassImage: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // BMI Calculation Methods
  static Future<Map<String, dynamic>> calculateBMI(
    double height,
    double weight,
  ) async {
    try {
      // Validate input
      if (height < 50 || height > 300) {
        return {
          'success': false,
          'message': 'Invalid height. Height must be between 50 and 300 cm.',
          'error': 'Height validation failed',
        };
      }

      if (weight < 20 || weight > 500) {
        return {
          'success': false,
          'message': 'Invalid weight. Weight must be between 20 and 500 kg.',
          'error': 'Weight validation failed',
        };
      }

      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/auth/calculate-bmi')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/auth/calculate-bmi'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }

      print('=== Calculate BMI Debug ===');
      print('Height: $height cm');
      print('Weight: $weight kg');

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders('');
      headers['X-Device-ID'] = deviceId;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/calculate-bmi'),
        headers: headers,
        body: jsonEncode({
          'height': height,
          'weight': weight,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to calculate BMI',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in calculateBMI: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserBMI(
    double height,
    double weight,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      if (height < 50 || height > 300) {
        return {
          'success': false,
          'message': 'Invalid height. Height must be between 50 and 300 cm.',
          'error': 'Height validation failed',
        };
      }

      if (weight < 20 || weight > 500) {
        return {
          'success': false,
          'message': 'Invalid weight. Weight must be between 20 and 500 kg.',
          'error': 'Weight validation failed',
        };
      }

      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/bmi')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/bmi'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }

      print('=== Update User BMI Debug ===');
      print('Height: $height cm');
      print('Weight: $weight kg');

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/bmi'),
        headers: headers,
        body: jsonEncode({
          'height': height,
          'weight': weight,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update BMI',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in updateUserBMI: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getUserBMI(
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/aut/bmi')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/authbmi'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }

      print('=== Get User BMI Debug ===');

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/bmi'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get BMI data',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      print('Exception in getUserBMI: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}/api/auth/profile')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}/api/auth/profile'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/profile'),
        headers: headers,
      );

      SecureLogger.apiResponse(response.statusCode, '${ApiConfig.baseUrl}/api/auth/profile', body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'User profile retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch user profile',
          'error': errorData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      SecureLogger.error('Error fetching user profile', error: e);
      SecurityService.logSecurityEvent('api_error', details: {'error': e.toString(), 'endpoint': 'get_user_profile'});
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Update user profile data
  static Future<Map<String, dynamic>> updateUserData(
    UpdateUserDataRequest request,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      // Make API call
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      // Log response for debugging
      print('Update user data response status: ${response.statusCode}');
      print('Update user data response body: ${response.body}');

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'User data updated successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update user data',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('Error updating user data: $e');
      SecurityService.logSecurityEvent('api_error', details: {'error': e.toString(), 'endpoint': 'update_user_data'});
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Change user password
  static Future<Map<String, dynamic>> changePassword(
    ChangePasswordRequest request,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      // Make API call
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      // Log response for debugging
      print('Change password response status: ${response.statusCode}');
      print('Change password response body: ${response.body}');

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password changed successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to change password',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('Error changing password: $e');
      SecurityService.logSecurityEvent('api_error', details: {'error': e.toString(), 'endpoint': 'change_password'});
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Change SuperAdmin password
  static Future<Map<String, dynamic>> changeSuperAdminPassword(
    ChangePasswordRequest request,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      // Validate SSL certificate
      if (!SecurityService.validateSSLCertificate('${ApiConfig.baseUrl}${ApiConfig.superAdminChangePassword}')) {
        SecurityService.logSecurityEvent('invalid_ssl_certificate', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.superAdminChangePassword}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid SSL certificate',
        };
      }

      // Ensure token doesn't already have Bearer prefix
      final cleanToken = accessToken.startsWith('Bearer ') 
          ? accessToken.substring(7) 
          : accessToken;
      
      print('=== Change SuperAdmin Password Debug ===');
      print('Clean token: ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(cleanToken);
      headers['X-Device-ID'] = deviceId;
      print('Headers: ${headers.keys.toList()}');

      // Make API call
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.superAdminChangePassword}'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      // Log response for debugging
      SecureLogger.apiResponse(response.statusCode, '${ApiConfig.baseUrl}${ApiConfig.superAdminChangePassword}', body: response.body);

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password changed successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to change password',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      SecureLogger.error('Error changing SuperAdmin password', error: e);
      SecurityService.logSecurityEvent('api_error', details: {'error': e.toString(), 'endpoint': 'change_superadmin_password'});
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Change user branch
  static Future<Map<String, dynamic>> changeUserBranch(
    ChangeBranchRequest request,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      // Make API call
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/change-branch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      // Log response for debugging
      print('Change branch response status: ${response.statusCode}');
      print('Change branch response body: ${response.body}');

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Branch changed successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to change branch',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('Error changing branch: $e');
      SecurityService.logSecurityEvent('api_error', details: {'error': e.toString(), 'endpoint': 'change_branch'});
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Get all branches for branch selection
  static Future<Map<String, dynamic>> getAllBranches(
    String accessToken, {
    int page = 1,
    int limit = 100,
  }) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      // Make API call
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/branches?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      // Log response for debugging
      print('Get all branches response status: ${response.statusCode}');
      print('Get all branches response body: ${response.body}');

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Branches retrieved successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to retrieve branches',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('Error getting branches: $e');
      SecurityService.logSecurityEvent('api_error', details: {'error': e.toString(), 'endpoint': 'get_all_branches'});
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }
}
