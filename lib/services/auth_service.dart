import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../utils/api_config.dart';
import '../utils/secure_logger.dart';
import 'security_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _baseUrl = ApiConfig.baseUrl;
  Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // Add auth token to headers
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  // Remove auth token from headers
  void clearAuthToken() {
    _headers.remove('Authorization');
  }

  // Update headers with security features
  Future<void> _updateSecurityHeaders() async {
    final deviceId = await SecurityService.getDeviceId();
    _headers = SecurityService.getSecurityHeaders(_headers['Authorization']?.replaceFirst('Bearer ', ''));
    _headers['X-Device-ID'] = deviceId;
  }

  /// Sign up a new user
  Future<AuthResponse> signup(SignupRequest request) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(request.email) || !SecurityService.validateInput(request.password)) {
        SecurityService.logSecurityEvent('invalid_signup_input', details: {'email_length': request.email.length, 'password_length': request.password.length});
        throw AuthException(
          message: 'Invalid input data',
          statusCode: 400,
          details: 'Input validation failed',
        );
      }
      
      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(request.email);
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('$_baseUrl/api/auth/signup')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '$_baseUrl/api/auth/signup'});
        throw AuthException(
          message: 'Security validation failed',
          statusCode: 400,
          details: 'Invalid or non-production URL',
        );
      }
      
      // Update security headers
      await _updateSecurityHeaders();
      
      final sanitizedRequest = SignupRequest(
        fullName: SecurityService.sanitizeInput(request.fullName),
        email: sanitizedEmail,
        password: request.password,
        phoneNumber: request.phoneNumber != null ? SecurityService.sanitizeInput(request.phoneNumber!) : null,
        countryCode: request.countryCode != null ? SecurityService.sanitizeInput(request.countryCode!) : null,
        dateOfBirth: request.dateOfBirth,
        branchId: request.branchId,
      );
      
      final requestBody = jsonEncode(sanitizedRequest.toJson());
      SecureLogger.apiRequest('POST', '$_baseUrl/api/auth/signup', body: sanitizedRequest.toJson());
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/signup'),
        headers: _headers,
        body: requestBody,
      );

      SecureLogger.apiResponse(response.statusCode, '$_baseUrl/api/auth/signup', body: response.body);
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return AuthResponse.fromJson(responseData['data']);
      } else {
        throw AuthException(
          message: responseData['message'] ?? 'Signup failed',
          statusCode: response.statusCode,
          details: responseData['details'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Network error',
        statusCode: 0,
        details: e.toString(),
      );
    }
  }

  /// Login user
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(request.email) || !SecurityService.validateInput(request.password)) {
        SecurityService.logSecurityEvent('invalid_login_input', details: {'email_length': request.email.length, 'password_length': request.password.length});
        throw AuthException(
          message: 'Invalid input data',
          statusCode: 400,
          details: 'Input validation failed',
        );
      }
      
      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(request.email);
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('$_baseUrl/api/auth/login')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '$_baseUrl/api/auth/login'});
        throw AuthException(
          message: 'Security validation failed',
          statusCode: 400,
          details: 'Invalid or non-production URL',
        );
      }
      
      // Update security headers
      await _updateSecurityHeaders();
      
      final sanitizedRequest = LoginRequest(
        email: sanitizedEmail,
        password: request.password,
      );
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode(sanitizedRequest.toJson()),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData['data']);
      } else {
        throw AuthException(
          message: responseData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
          details: responseData['details'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Network error',
        statusCode: 0,
        details: e.toString(),
      );
    }
  }

  /// Refresh access token
  Future<RefreshTokenResponse> refreshToken(String refreshToken) async {
    try {
      // Validate input
      if (!SecurityService.validateInput(refreshToken)) {
        SecurityService.logSecurityEvent('invalid_refresh_token_input', details: {'token_length': refreshToken.length});
        throw AuthException(
          message: 'Invalid token data',
          statusCode: 400,
          details: 'Input validation failed',
        );
      }
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('$_baseUrl/api/auth/refresh')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '$_baseUrl/api/auth/refresh'});
        throw AuthException(
          message: 'Security validation failed',
          statusCode: 400,
          details: 'Invalid or non-production URL',
        );
      }
      
      // Update security headers
      await _updateSecurityHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/refresh'),
        headers: _headers,
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return RefreshTokenResponse.fromJson(responseData['data']);
      } else {
        throw AuthException(
          message: responseData['message'] ?? 'Token refresh failed',
          statusCode: response.statusCode,
          details: responseData['details'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Network error',
        statusCode: 0,
        details: e.toString(),
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Ensure token doesn't already have Bearer prefix
      final token = _headers['Authorization'] ?? '';
      final cleanToken = token.startsWith('Bearer ') 
          ? token.substring(7) 
          : token;
      
      // Validate input
      if (cleanToken.isNotEmpty && !SecurityService.validateInput(cleanToken)) {
        SecurityService.logSecurityEvent('invalid_logout_token_input', details: {'token_length': cleanToken.length});
        throw AuthException(
          message: 'Invalid token data',
          statusCode: 400,
          details: 'Input validation failed',
        );
      }
      
      // Validate production URL
      if (!SecurityService.isAllowedProductionUrl('$_baseUrl/api/auth/logout')) {
        SecurityService.logSecurityEvent('invalid_production_url', details: {'url': '$_baseUrl/api/auth/logout'});
        throw AuthException(
          message: 'Security validation failed',
          statusCode: 400,
          details: 'Invalid or non-production URL',
        );
      }
      
      if (kDebugMode) print('=== AuthService Logout Debug ===');
      if (kDebugMode) print('Original token: ${token.isNotEmpty ? token.substring(0, 20) + '...' : 'empty'}');
      if (kDebugMode) print('Clean token: ${cleanToken.isNotEmpty ? cleanToken.substring(0, 20) + '...' : 'empty'}');
      
      // Update security headers
      await _updateSecurityHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/logout'),
        headers: _headers,
      );

      if (kDebugMode) print('Logout response status: ${response.statusCode}');
      if (kDebugMode) print('Logout response body: ${response.body}');

      if (response.statusCode == 200) {
        // Success - clear auth token
        clearAuthToken();
      } else {
        final responseData = jsonDecode(response.body);
        
        // If token is expired or invalid, consider this a successful logout
        if (response.statusCode == 401 && 
            (responseData['error']?.toString().contains('expired') == true ||
             responseData['message']?.toString().contains('expired') == true ||
             responseData['error']?.toString().contains('invalid') == true ||
             responseData['message']?.toString().contains('invalid') == true)) {
          if (kDebugMode) print('Token expired or invalid, treating as successful logout');
          clearAuthToken();
          return;
        }
        
        throw AuthException(
          message: responseData['message'] ?? 'Logout failed',
          statusCode: response.statusCode,
          details: responseData['details'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      // Even if there's an error, clear the auth token to ensure logout
      if (kDebugMode) print('Logout error, but clearing auth token: $e');
      clearAuthToken();
      
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Network error',
        statusCode: 0,
        details: e.toString(),
      );
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final int statusCode;
  final String details;

  AuthException({
    required this.message,
    required this.statusCode,
    required this.details,
  });

  @override
  String toString() => 'AuthException: $message (Status: $statusCode, Details: $details)';
}
