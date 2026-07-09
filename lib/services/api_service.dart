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
import 'package:flutter/foundation.dart';

class ApiService {
  
  // Test connection to backend
  static Future<bool> testConnection() async {
    try {
      SecureLogger.debug('Testing Backend Connection', data: {'url': ApiConfig.baseUrl});
      
      // Validate production domain
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/health')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/health'});
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
  static Future<Map<String, dynamic>> getAppSettings(String accessToken, {String? dashboardType}) async {
    try {
      var url = '${cfg.ApiConfig.baseUrl}${cfg.ApiConfig.getAppSettings}';
      // Add dashboard type as query parameter if provided
      if (dashboardType != null && dashboardType.isNotEmpty) {
        url += '?dashboard=$dashboardType';
      }
      final uri = Uri.parse(url);
      if (!SecurityService.isAllowedProductionUrl(uri.toString())) {
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = await SecurityService.getDeviceId();
      final response = await http.get(
        uri,
        headers: headers,
      );

      SecureLogger.apiResponse(response.statusCode, uri.toString(), body: response.body);

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
  // dashboardType: 'superadmin', 'branch', or 'user'
  static Future<Map<String, dynamic>> uploadBackgroundImage({
    required String accessToken, 
    required File imageFile,
    String? dashboardType,
  }) async {
    try {
      // Use the appropriate endpoint based on dashboard type
      String endpoint;
      switch (dashboardType) {
        case 'superadmin':
          endpoint = cfg.ApiConfig.uploadSuperAdminBackgroundImage;
          break;
        case 'branch':
          endpoint = cfg.ApiConfig.uploadBranchBackgroundImage;
          break;
        case 'user':
          endpoint = cfg.ApiConfig.uploadUserBackgroundImage;
          break;
        default:
          // Fallback to superadmin if not specified
          endpoint = cfg.ApiConfig.uploadSuperAdminBackgroundImage;
      }
      
      final url = '${cfg.ApiConfig.baseUrl}$endpoint';
      final uri = Uri.parse(url);
      if (!SecurityService.isAllowedProductionUrl(uri.toString())) {
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }

      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers.remove('Content-Type');
      headers['X-Device-ID'] = await SecurityService.getDeviceId();

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      SecureLogger.apiResponse(response.statusCode, uri.toString(), body: response.body);

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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      if (kDebugMode) print('Exception in superAdminLogin: $e');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.adminLogin}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.adminLogin}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.branchLogin}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchLogin}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.branchLogout}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchLogout}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
          if (kDebugMode) print('Token expired, treating as successful logout');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.branchForgotPassword}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchForgotPassword}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.branchResetPassword}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchResetPassword}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.branchResendOTP}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.branchResendOTP}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.createBranch}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.createBranch}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      if (kDebugMode) print('=== API Service Create Branch Debug ===');
      if (kDebugMode) print('URL: ${ApiConfig.baseUrl}${ApiConfig.createBranch}');
      if (kDebugMode) print('Request data: ${jsonEncode(branchData)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createBranch}'),
        headers: headers,
        body: jsonEncode(branchData),
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/auth/branches')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/auth/branches'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.getBranches}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBranches}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.getBranch}/$branchId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBranch}/$branchId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
    String accessToken, {
    File? imageFile,
    List<File>? imageFiles,
  }) async {
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      // If images are provided, use multipart form data
      if ((imageFile != null || (imageFiles != null && imageFiles.isNotEmpty))) {
        // Validate image files
        if (imageFile != null) {
          if (!await imageFile.exists()) {
            return {
              'success': false,
              'message': 'Image file not found',
              'error': 'File does not exist',
            };
          }
          
          // Validate file size (max 5MB)
          final fileSize = await imageFile.length();
          if (fileSize > 5 * 1024 * 1024) {
            return {
              'success': false,
              'message': 'Image file too large. Maximum size is 5MB.',
              'error': 'File size exceeds limit',
            };
          }
        }
        
        if (imageFiles != null) {
          for (final file in imageFiles) {
            if (!await file.exists()) {
              return {
                'success': false,
                'message': 'One or more image files not found',
                'error': 'File does not exist',
              };
            }
            
            // Validate file size (max 5MB per image)
            final fileSize = await file.length();
            if (fileSize > 5 * 1024 * 1024) {
              return {
                'success': false,
                'message': 'Image file too large. Maximum size is 5MB per image.',
                'error': 'File size exceeds limit',
              };
            }
          }
        }
        
        // Remove Content-Type header to let multipart/form-data be set automatically
        headers.remove('Content-Type');
        
        // Create multipart request
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId'),
        );
        
        // Add headers
        request.headers.addAll(headers);
        
        // Add form fields (only non-null values)
        if (updateData['branch_id'] != null) {
          request.fields['branch_id'] = updateData['branch_id'].toString();
        }
        if (updateData['branch_name'] != null) {
          request.fields['branch_name'] = updateData['branch_name'].toString();
        }
        if (updateData['admin_name'] != null) {
          request.fields['admin_name'] = updateData['admin_name'].toString();
        }
        if (updateData['email'] != null) {
          request.fields['email'] = updateData['email'].toString();
        }
        if (updateData['phone_number'] != null) {
          request.fields['phone_number'] = updateData['phone_number'].toString();
        }
        if (updateData['location'] != null) {
          request.fields['location'] = updateData['location'].toString();
        }
        
        // Add existing image URL if provided (not a file path)
        if (updateData['image'] != null && imageFile == null) {
          final imageValue = updateData['image'].toString();
          // Only add if it's a URL, not a file path
          if (imageValue.startsWith('http://') || imageValue.startsWith('https://') || imageValue.startsWith('/')) {
            request.fields['image_url'] = imageValue;
          }
        }
        
        // Add classes as JSON string if provided
        if (updateData['classes'] != null) {
          request.fields['classes'] = jsonEncode(updateData['classes']);
        }
        
        // Add single image file if provided
        if (imageFile != null) {
          final multipartFile = await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            filename: 'branch_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          request.files.add(multipartFile);
        }
        
        // Add multiple image files if provided
        if (imageFiles != null && imageFiles.isNotEmpty) {
          for (final file in imageFiles) {
            final multipartFile = await http.MultipartFile.fromPath(
              'images',
              file.path,
              filename: 'branch_image_${DateTime.now().millisecondsSinceEpoch}_${imageFiles.indexOf(file)}.jpg',
            );
            request.files.add(multipartFile);
          }
        }
        
        if (kDebugMode) print('=== API Service Update Branch Debug (Multipart) ===');
        if (kDebugMode) print('URL: ${request.url}');
        if (kDebugMode) print('Branch ID: $branchId');
        if (kDebugMode) print('Form fields: ${request.fields}');
        if (kDebugMode) print('Image files: ${imageFile != null ? 1 : 0} single, ${imageFiles?.length ?? 0} multiple');
        
        // Send request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (kDebugMode) print('Response status: ${response.statusCode}');
        if (kDebugMode) print('Response body: ${response.body}');
        
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
            'message': errorData['message'] ?? 'Branch update failed',
            'error': errorData['error'],
          };
        }
      } else {
        // Use JSON request (no images)
        if (kDebugMode) print('=== API Service Update Branch Debug (JSON) ===');
        if (kDebugMode) print('URL: ${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId');
        if (kDebugMode) print('Request data: ${jsonEncode(updateData)}');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId'),
        headers: headers,
        body: jsonEncode(updateData),
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
            'message': errorData['message'] ?? 'Branch update failed',
          'error': errorData['error'],
        };
        }
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.deleteBranch}/$branchId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.deleteBranch}/$branchId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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

  // Add Team Member to Branch
  static Future<Map<String, dynamic>> addTeamMember(
    String branchId,
    Map<String, dynamic> teamMemberData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || 
          !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_team_member_add_input', details: {
          'branch_id_length': branchId.length,
          'token_length': accessToken.length
        });
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate production URL
      final url = '${ApiConfig.baseUrl}/api/branches/$branchId/team-members';
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      if (kDebugMode) print('=== API Service Add Team Member Debug ===');
      if (kDebugMode) print('URL: $url');
      if (kDebugMode) print('Branch ID: $branchId');
      if (kDebugMode) print('Request data: ${jsonEncode(teamMemberData)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(teamMemberData),
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Team member added successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to add team member',
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

  // Update Team Member in Branch
  static Future<Map<String, dynamic>> updateTeamMember(
    String branchId,
    String teamMemberId,
    Map<String, dynamic> updateData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || 
          !SecurityService.validateInput(teamMemberId) || 
          !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_team_member_update_input', details: {
          'branch_id_length': branchId.length,
          'team_member_id_length': teamMemberId.length,
          'token_length': accessToken.length
        });
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate production URL
      final url = '${ApiConfig.baseUrl}/api/branches/$branchId/team-members/$teamMemberId';
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      if (kDebugMode) print('=== API Service Update Team Member Debug ===');
      if (kDebugMode) print('URL: $url');
      if (kDebugMode) print('Branch ID: $branchId');
      if (kDebugMode) print('Team Member ID: $teamMemberId');
      if (kDebugMode) print('Request data: ${jsonEncode(updateData)}');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(updateData),
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Team member updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update team member',
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

  // Delete Team Member from Branch
  static Future<Map<String, dynamic>> deleteTeamMember(
    String branchId,
    String teamMemberId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || 
          !SecurityService.validateInput(teamMemberId) || 
          !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_team_member_delete_input', details: {
          'branch_id_length': branchId.length,
          'team_member_id_length': teamMemberId.length,
          'token_length': accessToken.length
        });
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }
      
      // Validate production URL
      final url = '${ApiConfig.baseUrl}/api/branches/$branchId/team-members/$teamMemberId';
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      if (kDebugMode) print('=== API Service Delete Team Member Debug ===');
      if (kDebugMode) print('URL: $url');
      if (kDebugMode) print('Branch ID: $branchId');
      if (kDebugMode) print('Team Member ID: $teamMemberId');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Team member deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete team member',
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
    String accessToken, {
    List<File>? imageFiles,
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.createStandaloneClass}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.createStandaloneClass}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      // If images are provided, use multipart form data
      if (imageFiles != null && imageFiles.isNotEmpty) {
        // Validate image files
        for (final imageFile in imageFiles) {
          if (!await imageFile.exists()) {
            return {
              'success': false,
              'message': 'One or more image files not found',
              'error': 'File does not exist',
            };
          }
          
          // Validate file size (max 5MB per image)
          final fileSize = await imageFile.length();
          if (fileSize > 5 * 1024 * 1024) {
            return {
              'success': false,
              'message': 'Image file too large. Maximum size is 5MB per image.',
              'error': 'File size exceeds limit',
            };
          }
        }
        
        // Remove Content-Type header to let multipart/form-data be set automatically
        headers.remove('Content-Type');
        
        // Create multipart request
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createStandaloneClass}'),
        );
        
        // Add headers
        request.headers.addAll(headers);
        
        // Add form fields
        request.fields['name'] = classData.name;
        request.fields['description'] = classData.description;
        request.fields['instructor'] = classData.instructor;
        request.fields['capacity'] = classData.capacity.toString();
        
        if (classData.duration != null) {
          request.fields['duration'] = classData.duration.toString();
        }
        
        // Add schedule as JSON string
        request.fields['schedule'] = jsonEncode(
          classData.schedule.map((s) => s.toJson()).toList()
        );
        
        // Add existing image URLs if provided (comma-separated)
        if (classData.images != null && classData.images!.isNotEmpty) {
          request.fields['image_urls'] = classData.images!.join(',');
        }
        
        // Add image files
        for (final imageFile in imageFiles) {
          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            imageFile.path,
            filename: 'class_image_${DateTime.now().millisecondsSinceEpoch}_${imageFiles.indexOf(imageFile)}.jpg',
          );
          request.files.add(multipartFile);
        }
        
        if (kDebugMode) print('=== CreateStandaloneClass Debug (Multipart) ===');
        if (kDebugMode) print('Name: ${classData.name}');
        if (kDebugMode) print('Description: ${classData.description}');
        if (kDebugMode) print('Instructor: ${classData.instructor}');
        if (kDebugMode) print('Capacity: ${classData.capacity}');
        if (kDebugMode) print('Duration: ${classData.duration}');
        if (kDebugMode) print('Schedule: ${request.fields['schedule']}');
        if (kDebugMode) print('Image files: ${imageFiles.length}');
        
        // Send request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (kDebugMode) print('Response status: ${response.statusCode}');
        if (kDebugMode) print('Response body: ${response.body}');
        
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
      } else {
        // Use JSON request (no images)
        final requestBody = classData.toJson();
        if (kDebugMode) print('=== CreateStandaloneClass Debug (JSON) ===');
        if (kDebugMode) print('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createStandaloneClass}'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');
      
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.getStandaloneClasses}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getStandaloneClasses}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
            if (kDebugMode) print('Error filtering classes by visibility: $e');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.getStandaloneClass}/$classId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getStandaloneClass}/$classId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
    String accessToken, {
    List<File>? imageFiles,
  }) async {
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      // If images are provided, use multipart form data
      if (imageFiles != null && imageFiles.isNotEmpty) {
        // Validate image files
        for (final file in imageFiles) {
          if (!await file.exists()) {
            return {
              'success': false,
              'message': 'One or more image files not found',
              'error': 'File does not exist',
            };
          }
          
          // Validate file size (max 5MB per image)
          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) {
            return {
              'success': false,
              'message': 'Image file too large. Maximum size is 5MB per image.',
              'error': 'File size exceeds limit',
            };
          }
        }
        
        // Remove Content-Type header to let multipart/form-data be set automatically
        headers.remove('Content-Type');
        
        // Create multipart request
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId'),
        );
        
        // Add headers
        request.headers.addAll(headers);
        
        // Add form fields (only non-null values)
        final updateJson = updateData.toJson();
        if (updateJson['name'] != null) {
          request.fields['name'] = updateJson['name'].toString();
        }
        if (updateJson['description'] != null) {
          request.fields['description'] = updateJson['description'].toString();
        }
        if (updateJson['instructor'] != null) {
          request.fields['instructor'] = updateJson['instructor'].toString();
        }
        if (updateJson['duration'] != null) {
          request.fields['duration'] = updateJson['duration'].toString();
        }
        if (updateJson['capacity'] != null) {
          request.fields['capacity'] = updateJson['capacity'].toString();
        }
        if (updateJson['is_active'] != null) {
          request.fields['is_active'] = updateJson['is_active'].toString();
        }
        
        // Add schedule as JSON string if provided
        if (updateJson['schedule'] != null) {
          request.fields['schedule'] = jsonEncode(updateJson['schedule']);
        }
        
        // Add existing image URLs as comma-separated string if provided
        if (updateJson['images'] != null && updateJson['images'] is List) {
          final imageList = updateJson['images'] as List;
          final imageUrls = imageList.map((img) => img.toString()).where((url) => 
            url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/')
          ).join(',');
          if (imageUrls.isNotEmpty) {
            request.fields['image_urls'] = imageUrls;
          }
        }
        
        // Add image files
        for (final file in imageFiles) {
          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            file.path,
            filename: 'class_image_${DateTime.now().millisecondsSinceEpoch}_${imageFiles.indexOf(file)}.jpg',
          );
          request.files.add(multipartFile);
        }
        
        if (kDebugMode) print('=== API Service Update Standalone Class Debug (Multipart) ===');
        if (kDebugMode) print('URL: ${request.url}');
        if (kDebugMode) print('Class ID: $classId');
        if (kDebugMode) print('Form fields: ${request.fields}');
        if (kDebugMode) print('Image files: ${imageFiles.length}');
        
        // Send request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (kDebugMode) print('Response status: ${response.statusCode}');
        if (kDebugMode) print('Response body: ${response.body}');
        
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
            'message': errorData['message'] ?? 'Class update failed',
            'error': errorData['error'],
          };
        }
      } else {
        // Use JSON request (no images)
        final requestBody = jsonEncode(updateData.toJson());
        if (kDebugMode) print('=== API Request Debug (JSON) ===');
        if (kDebugMode) print('URL: ${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId');
        if (kDebugMode) print('Headers: $headers');
        if (kDebugMode) print('Request Body: $requestBody');
        
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId'),
          headers: headers,
          body: requestBody,
        );
        
        if (kDebugMode) print('=== API Response Debug ===');
        if (kDebugMode) print('Status Code: ${response.statusCode}');
        if (kDebugMode) print('Response Body: ${response.body}');

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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.deleteStandaloneClass}/$classId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.deleteStandaloneClass}/$classId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== SuperAdmin Logout Debug ===');
      if (kDebugMode) print('URL: ${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}');
      if (kDebugMode) print('Token received: ${accessToken.substring(0, 20)}...');
      if (kDebugMode) print('Token length: ${accessToken.length}');
      
      // Ensure token doesn't already have Bearer prefix
      final cleanToken = accessToken.startsWith('Bearer ') 
          ? accessToken.substring(7) 
          : accessToken;
      if (kDebugMode) print('Clean token: ${cleanToken.substring(0, 20)}...');
      if (kDebugMode) print('Authorization header: Bearer ${cleanToken.substring(0, 20)}...');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(cleanToken);
      headers['X-Device-ID'] = deviceId;
      if (kDebugMode) print('Headers: $headers');
      
      // Try the main logout endpoint first
      var response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}'),
        headers: headers,
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

      // If the main endpoint fails, try alternative endpoints
      if (response.statusCode != 200) {
        if (kDebugMode) print('Main logout endpoint failed, trying alternatives...');
        
        // Try superadmin-specific logout endpoint
        final alternativeEndpoints = [
          '/superadmin/logout',
          '/api/superadmin/logout',
          '/api/auth/superadmin/logout',
        ];
        
        for (final endpoint in alternativeEndpoints) {
          if (kDebugMode) print('Trying endpoint: $endpoint');
          try {
            response = await http.post(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
            );
            
            if (kDebugMode) print('Alternative endpoint $endpoint response: ${response.statusCode}');
            if (response.statusCode == 200) {
              if (kDebugMode) print('Alternative endpoint $endpoint succeeded!');
              break;
            }
          } catch (e) {
            if (kDebugMode) print('Alternative endpoint $endpoint failed: $e');
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
        if (kDebugMode) print('Error response: $errorData');
        
        // If token is expired, consider this a successful logout
        if (response.statusCode == 401 && 
            (errorData['error']?.toString().contains('expired') == true ||
             errorData['message']?.toString().contains('expired') == true)) {
          if (kDebugMode) print('Token expired, treating as successful logout');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/superadmin/users')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/superadmin/users'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Get SuperAdmin Users Debug ===');
      
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
      if (kDebugMode) print('URL: $uri');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      if (kDebugMode) print('Headers: $headers');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
      if (kDebugMode) print('Exception in getSuperAdminUsers: $e');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/branches/with-users')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/branches/with-users'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Get Branches With Users Debug ===');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = SecurityService.sanitizeInput(search);
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/branches/with-users').replace(queryParameters: queryParams);
      if (kDebugMode) print('URL: $uri');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      if (kDebugMode) print('Headers: $headers');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
      if (kDebugMode) print('Exception in getBranchesWithUsers: $e');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/admin/bookings/classes-with-users')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/admin/bookings/classes-with-users'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Get Admin Bookings Debug ===');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/bookings/classes-with-users').replace(queryParameters: queryParams);
      if (kDebugMode) print('URL: $uri');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      if (kDebugMode) print('Headers: $headers');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
      if (kDebugMode) print('Exception in getAdminBookings: $e');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.renewClass}/$classId/renew')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.renewClass}/$classId/renew'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.getExpiringClasses}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getExpiringClasses}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.getBranchClasses}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBranchClasses}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/auth/branch-classes')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/auth/branch-classes'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
          'statusCode': response.statusCode,
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/branches/$branchId/classes')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/branches/$branchId/classes'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.getBranchClass}/$classId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBranchClass}/$classId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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

  // Get Single Branch Class for Super Admin (uses branch ID in path)
  static Future<Map<String, dynamic>> getBranchClassForSuperAdmin(
    String branchId,
    String classId,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || !SecurityService.validateInput(classId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_branch_class_input', details: {
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
      
      // Super admin endpoint: /api/branches/:branchId/classes/:classId
      final url = '${ApiConfig.baseUrl}/api/branches/$branchId/classes/$classId';
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.get(
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Update Branch Class Schedule Debug ===');
      if (kDebugMode) print('URL: ${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule');
      if (kDebugMode) print('Request body: ${jsonEncode(scheduleData.toJson())}');
      if (kDebugMode) print('Schedule count: ${scheduleData.schedule.length}');
      for (int i = 0; i < scheduleData.schedule.length; i++) {
        final schedule = scheduleData.schedule[i];
        if (kDebugMode) print('Schedule $i: dayOfWeek=${schedule.dayOfWeek}, date=${schedule.date}, startTime=${schedule.startTime}, endTime=${schedule.endTime}');
        if (kDebugMode) print('Schedule $i JSON: ${jsonEncode(schedule.toJson())}');
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule'),
        headers: headers,
        body: jsonEncode(scheduleData.toJson()),
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        if (kDebugMode) print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          if (kDebugMode) print('Error message: ${errorData['message']}');
          if (kDebugMode) print('Error details: ${errorData['error']}');
        } catch (e) {
          if (kDebugMode) print('Failed to parse error response: $e');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassInstructor}/$classId/instructor')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateBranchClassInstructor}/$classId/instructor'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Update Branch Class Instructor Debug ===');
      if (kDebugMode) print('URL: ${ApiConfig.baseUrl}${ApiConfig.updateBranchClassInstructor}/$classId/instructor');
      if (kDebugMode) print('Request body: ${jsonEncode(instructorData.toJson())}');
      if (kDebugMode) print('Instructor: ${instructorData.instructor}');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassInstructor}/$classId/instructor'),
        headers: headers,
        body: jsonEncode(instructorData.toJson()),
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        if (kDebugMode) print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          if (kDebugMode) print('Error message: ${errorData['message']}');
          if (kDebugMode) print('Error details: ${errorData['error']}');
        } catch (e) {
          if (kDebugMode) print('Failed to parse error response: $e');
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

  // Update Branch Class (Branch Admin only) - for updating capacity, schedule, etc.
  static Future<Map<String, dynamic>> updateBranchClass(
    String branchId,
    String classId,
    UpdateClassRequest updateData,
    String accessToken,
  ) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(branchId) || 
          !SecurityService.validateInput(classId) || 
          !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_class_update_input', 
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
      
      // Validate production URL
      // Backend route: /api/branch/classes/:branchId/:classId
      final url = '${ApiConfig.baseUrl}${ApiConfig.updateBranchClass}/$branchId/$classId';
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Update Branch Class Debug ===');
      if (kDebugMode) print('URL: $url');
      if (kDebugMode) print('Request body: ${jsonEncode(updateData.toJson())}');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(updateData.toJson()),
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        if (kDebugMode) print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          if (kDebugMode) print('Error message: ${errorData['message']}');
          if (kDebugMode) print('Error details: ${errorData['error']}');
        } catch (e) {
          if (kDebugMode) print('Failed to parse error response: $e');
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
      
      // Validate production URL
      // Backend route: /api/branch/classes/:branchId/:classId
      final url = '${ApiConfig.baseUrl}${ApiConfig.updateBranchClass}/$branchId/$classId';
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Update Branch Class Recurring Schedule Debug ===');
      if (kDebugMode) print('URL: $url');
      if (kDebugMode) print('Request body: ${jsonEncode(recurringData.toJson())}');
      if (kDebugMode) print('Day of Week: ${recurringData.dayOfWeek}');
      if (kDebugMode) print('New Start Time: ${recurringData.newStartTime}');
      if (kDebugMode) print('New End Time: ${recurringData.newEndTime}');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(recurringData.toJson()),
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        if (kDebugMode) print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          if (kDebugMode) print('Error message: ${errorData['message']}');
          if (kDebugMode) print('Error details: ${errorData['error']}');
        } catch (e) {
          if (kDebugMode) print('Failed to parse error response: $e');
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

      // Validate production URL
      final url = '${ApiConfig.baseUrl}${ApiConfig.bulkUpdateClassTime}';
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }

      if (kDebugMode) print('=== Bulk Update Class Time Debug ===');
      if (kDebugMode) print('URL: $url');
      if (kDebugMode) print('Request body: ${jsonEncode(bulkUpdateData.toJson())}');
      if (kDebugMode) print('Day of Week: ${bulkUpdateData.dayOfWeek}');
      if (kDebugMode) print('New Start Time: ${bulkUpdateData.newStartTime}');
      if (kDebugMode) print('New End Time: ${bulkUpdateData.newEndTime}');

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(bulkUpdateData.toJson()),
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        if (kDebugMode) print('=== Error Details ===');
        try {
          final errorData = jsonDecode(response.body);
          if (kDebugMode) print('Error message: ${errorData['message']}');
          if (kDebugMode) print('Error details: ${errorData['error']}');
        } catch (e) {
          if (kDebugMode) print('Failed to parse error response: $e');
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
      
      // Validate production URL
      final url = '${ApiConfig.baseUrl}/api/standalone-classes/$classId/toggle-visibility';
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      final url = '${ApiConfig.baseUrl}/api/branch/classes/$classId/toggle-visibility';
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      if (kDebugMode) print('=== Toggle Branch Class Visibility (Super Admin) ===');
      if (kDebugMode) print('URL: $url');
      if (kDebugMode) print('Branch ID: $branchId');
      if (kDebugMode) print('Class ID: $classId');
      
      if (!SecurityService.isAllowedProductionUrl(url)) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': url});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;
      
      if (kDebugMode) print('Headers: ${headers.keys}');
      if (kDebugMode) print('Request method: PATCH');
      
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
      );
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl(uri.toString())) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': uri.toString()});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.createBooking}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.createBooking}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.getBooking}/$bookingId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.getBooking}/$bookingId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/bookings')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/bookings'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
          'statusCode': response.statusCode,
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

  // Update Booking (User/Admin)
  static Future<Map<String, dynamic>> updateBooking(
    String bookingId,
    UpdateBookingRequest request,
    String accessToken,
  ) async {
    try {
      // Validate identifiers
      if (!SecurityService.validateInput(bookingId) || !SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_booking_update_input', details: {'booking_id_length': bookingId.length, 'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid input data',
          'error': 'Input validation failed',
        };
      }

      final rawStatus = request.status?.trim();
      final rawNotes = request.notes?.trim();

      if ((rawStatus == null || rawStatus.isEmpty) && (rawNotes == null || rawNotes.isEmpty)) {
        return {
          'success': false,
          'message': 'No update data provided',
          'error': 'empty_update_request',
        };
      }

      String? normalizedStatus;
      if (rawStatus != null && rawStatus.isNotEmpty) {
        if (!SecurityService.validateInput(rawStatus)) {
          SecurityService.logSecurityEvent('invalid_booking_status_input', details: {'status_length': rawStatus.length});
          return {
            'success': false,
            'message': 'Invalid status data',
            'error': 'Input validation failed',
          };
        }
        normalizedStatus = rawStatus.toLowerCase();
      }

      String? normalizedNotes;
      if (rawNotes != null && rawNotes.isNotEmpty) {
        if (!SecurityService.validateInput(rawNotes)) {
          SecurityService.logSecurityEvent('invalid_booking_notes_input', details: {'notes_length': rawNotes.length});
          return {
            'success': false,
            'message': 'Invalid notes data',
            'error': 'Input validation failed',
          };
        }
        normalizedNotes = rawNotes;
      }

      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.updateBooking}/$bookingId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.updateBooking}/$bookingId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }

      final payload = <String, dynamic>{};
      if (normalizedStatus != null) {
        payload['status'] = normalizedStatus;
      }
      if (normalizedNotes != null) {
        payload['notes'] = normalizedNotes;
      }

      if (payload.isEmpty) {
        return {
          'success': false,
          'message': 'No update data provided',
          'error': 'empty_update_request',
        };
      }

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBooking}/$bookingId'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Booking updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update booking',
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
  ) {
    return updateBooking(
      bookingId,
      UpdateBookingRequest(status: 'cancelled'),
      accessToken,
    );
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/branch/users')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/branch/users'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/branch/users/stats')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/branch/users/stats'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/branch/users/$userId')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/branch/users/$userId'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/branch/users/$userId/bookings')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/branch/users/$userId/bookings'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/superadmin/upload-image')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/superadmin/upload-image'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Upload SuperAdmin Image Debug ===');
      if (kDebugMode) print('Image file path: ${imageFile.path}');
      if (kDebugMode) print('Image file exists: ${await imageFile.exists()}');
      
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
      if (kDebugMode) print('File size: ${fileSize} bytes');
      
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
      
      if (kDebugMode) print('Sending request to: ${request.url}');
      if (kDebugMode) print('Headers: ${request.headers}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');
      
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
      if (kDebugMode) print('Exception in uploadSuperAdminImage: $e');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/branches/$branchId/upload-images')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/branches/$branchId/upload-images'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Upload Branch Image Debug ===');
      if (kDebugMode) print('Branch ID: $branchId');
      if (kDebugMode) print('Image file path: ${imageFile.path}');
      if (kDebugMode) print('Image file exists: ${await imageFile.exists()}');
      
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
      if (kDebugMode) print('File size: ${fileSize} bytes');
      
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
      // Remove Content-Type header to let multipart/form-data be set automatically
      headers.remove('Content-Type');
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/branches/$branchId/upload-images'),
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
      
      if (kDebugMode) print('Sending request to: ${request.url}');
      if (kDebugMode) print('Headers: ${request.headers}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');
      
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
      if (kDebugMode) print('Exception in uploadBranchImage: $e');
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
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/branches/$branchId/team-members/$teamMemberId/upload-image')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/branches/$branchId/team-members/$teamMemberId/upload-image'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }
      
      if (kDebugMode) print('=== Upload Team Member Image Debug ===');
      if (kDebugMode) print('Branch ID: $branchId');
      if (kDebugMode) print('Team Member ID: $teamMemberId');
      if (kDebugMode) print('Image file path: ${imageFile.path}');
      if (kDebugMode) print('Image file exists: ${await imageFile.exists()}');
      
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
      if (kDebugMode) print('File size: ${fileSize} bytes');
      
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
      
      if (kDebugMode) print('Sending request to: ${request.url}');
      if (kDebugMode) print('Headers: ${request.headers}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');
      
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
      if (kDebugMode) print('Exception in uploadTeamMemberImage: $e');
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
    // Support single file for backward compatibility
    return uploadStandaloneClassImages([imageFile], classId, accessToken);
  }

  static Future<Map<String, dynamic>> uploadStandaloneClassImages(
    List<File> imageFiles,
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

      if (imageFiles.isEmpty) {
        return {
          'success': false,
          'message': 'No images provided',
          'error': 'At least one image is required',
        };
      }

      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/standalone-classes/$classId/upload-image')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/standalone-classes/$classId/upload-image'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }

      // Validate image files
      for (final file in imageFiles) {
        if (!await file.exists()) {
          return {
            'success': false,
            'message': 'One or more image files not found',
            'error': 'File does not exist',
          };
        }
        
        // Validate file size (max 5MB per image)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          return {
            'success': false,
            'message': 'Image file too large. Maximum size is 5MB per image.',
            'error': 'File size exceeds limit',
          };
        }
      }

      if (kDebugMode) print('=== Upload Standalone Class Images Debug ===');
      if (kDebugMode) print('Class ID: $classId');
      if (kDebugMode) print('Number of images: ${imageFiles.length}');

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

      // Add image files (using "images" field to match backend HandleMultipleImageUpload)
      for (final file in imageFiles) {
        final multipartFile = await http.MultipartFile.fromPath(
          'images',
          file.path,
          filename: 'class_image_${DateTime.now().millisecondsSinceEpoch}_${imageFiles.indexOf(file)}.jpg',
        );
        request.files.add(multipartFile);
      }

      if (kDebugMode) print('=== Sending Request ===');
      if (kDebugMode) print('URL: ${request.url}');
      if (kDebugMode) print('Headers: ${request.headers}');
      if (kDebugMode) print('Files: ${request.files.length}');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) print('=== Response Debug ===');
      if (kDebugMode) print('Status Code: ${response.statusCode}');
      if (kDebugMode) print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Images uploaded successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload class images',
          'error': errorData['error'],
        };
      }
    } catch (e) {
      if (kDebugMode) print('Exception in uploadStandaloneClassImages: $e');
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

      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/auth/calculate-bmi')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/auth/calculate-bmi'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }

      if (kDebugMode) print('=== Calculate BMI Debug ===');
      if (kDebugMode) print('Height: $height cm');
      if (kDebugMode) print('Weight: $weight kg');

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

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
      if (kDebugMode) print('Exception in calculateBMI: $e');
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

      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/bmi')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/bmi'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }

      if (kDebugMode) print('=== Update User BMI Debug ===');
      if (kDebugMode) print('Height: $height cm');
      if (kDebugMode) print('Weight: $weight kg');

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

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
      if (kDebugMode) print('Exception in updateUserBMI: $e');
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

      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/aut/bmi')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/authbmi'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }

      if (kDebugMode) print('=== Get User BMI Debug ===');

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/bmi'),
        headers: headers,
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');
      if (kDebugMode) print('Response body: ${response.body}');

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
      if (kDebugMode) print('Exception in getUserBMI: $e');
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

      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}/api/auth/profile')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}/api/auth/profile'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
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
          'statusCode': response.statusCode,
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

  // Delete user account
  static Future<Map<String, dynamic>> deleteAccount(String accessToken) async {
    try {
      if (!SecurityService.validateInput(accessToken)) {
        SecurityService.logSecurityEvent('invalid_token_input', details: {'token_length': accessToken.length});
        return {
          'success': false,
          'message': 'Invalid token data',
          'error': 'Input validation failed',
        };
      }

      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(accessToken);
      headers['X-Device-ID'] = deviceId;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/account'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Account deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': errorData['message'] ?? 'Failed to delete account',
          'error': errorData['error'] ?? 'Unknown error',
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
      if (kDebugMode) print('Update user data response status: ${response.statusCode}');
      if (kDebugMode) print('Update user data response body: ${response.body}');

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
      if (kDebugMode) print('Error updating user data: $e');
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
      if (kDebugMode) print('Change password response status: ${response.statusCode}');
      if (kDebugMode) print('Change password response body: ${response.body}');

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
      if (kDebugMode) print('Error changing password: $e');
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

      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('${ApiConfig.baseUrl}${ApiConfig.superAdminChangePassword}')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '${ApiConfig.baseUrl}${ApiConfig.superAdminChangePassword}'});
        return {
          'success': false,
          'message': 'Security validation failed',
          'error': 'Invalid or non-production URL',
        };
      }

      // Ensure token doesn't already have Bearer prefix
      final cleanToken = accessToken.startsWith('Bearer ') 
          ? accessToken.substring(7) 
          : accessToken;
      
      if (kDebugMode) print('=== Change SuperAdmin Password Debug ===');
      if (kDebugMode) print('Clean token: ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
      
      final deviceId = await SecurityService.getDeviceId();
      final headers = SecurityService.getSecurityHeaders(cleanToken);
      headers['X-Device-ID'] = deviceId;
      if (kDebugMode) print('Headers: ${headers.keys.toList()}');

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
      if (kDebugMode) print('Change branch response status: ${response.statusCode}');
      if (kDebugMode) print('Change branch response body: ${response.body}');

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
      if (kDebugMode) print('Error changing branch: $e');
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
      if (kDebugMode) print('Get all branches response status: ${response.statusCode}');
      if (kDebugMode) print('Get all branches response body: ${response.body}');

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
      if (kDebugMode) print('Error getting branches: $e');
      SecurityService.logSecurityEvent('api_error', details: {'error': e.toString(), 'endpoint': 'get_all_branches'});
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }
}
