import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../utils/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _baseUrl = ApiConfig.baseUrl;
  final Map<String, String> _headers = {
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

  /// Sign up a new user
  Future<AuthResponse> signup(SignupRequest request) async {
    try {
      final requestBody = jsonEncode(request.toJson());
      print('Signup Request Body: $requestBody'); // Debug log
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/signup'),
        headers: _headers,
        body: requestBody,
      );

      print('Response Status: ${response.statusCode}'); // Debug log
      print('Response Body: ${response.body}'); // Debug log
      
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
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
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
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/logout'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw AuthException(
          message: responseData['message'] ?? 'Logout failed',
          statusCode: response.statusCode,
          details: responseData['details'] ?? 'Unknown error',
        );
      }

      // Clear auth token after successful logout
      clearAuthToken();
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
