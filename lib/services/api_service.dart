import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/standalone_class_models.dart';
import '../models/branch_class_models.dart';

class ApiService {
  
  // Test connection to backend
  static Future<bool> testConnection() async {
    try {
      print('=== Testing Backend Connection ===');
      print('Testing URL: ${ApiConfig.baseUrl}');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'), // Assuming you have a health endpoint
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 10));
      
      print('Connection test response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
  
  // SuperAdmin Login
  static Future<Map<String, dynamic>> superAdminLogin(String email, String password) async {
    try {
      print('=== ApiService.superAdminLogin Debug ===');
      print('Email: $email');
      print('Password: ${password.isNotEmpty ? '[HIDDEN]' : '[EMPTY]'}');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}');
      print('Headers: ${ApiConfig.defaultHeaders}');
      
      final requestBody = {
        'email': email,
        'password': password,
      };
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.superAdminLogin}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
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
          'message': errorData['message'] ?? 'Login failed',
          'error': errorData['error'],
        };
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminLogin}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchLogin}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
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

  // Branch Logout
  static Future<Map<String, dynamic>> branchLogout(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchLogout}'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchForgotPassword}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchResetPassword}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': password,
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.branchResendOTP}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createBranch}'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(branchData),
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

  // Get Branches (SuperAdmin only)
  static Future<Map<String, dynamic>> getBranches(
    String accessToken, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBranches}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBranch}/$branchId'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranch}/$branchId'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(updateData),
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
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deleteBranch}/$branchId'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final requestBody = classData.toJson();
      print('=== CreateStandaloneClass Debug ===');
      print('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createStandaloneClass}'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
  static Future<Map<String, dynamic>> getStandaloneClasses(
    String accessToken, {
    int page = 1,
    int limit = 20,
    String? search,
    String? dateFilter,
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (dateFilter != null && dateFilter.isNotEmpty) {
        queryParams['date'] = dateFilter;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getStandaloneClasses}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getStandaloneClass}/$classId'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateStandaloneClass}/$classId'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(updateData.toJson()),
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
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deleteStandaloneClass}/$classId'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      print('=== SuperAdmin Logout Debug ===');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}');
      print('Token received: ${accessToken.substring(0, 20)}...');
      print('Token length: ${accessToken.length}');
      print('Headers: ${ApiConfig.defaultHeaders}');
      
      // Ensure token doesn't already have Bearer prefix
      final cleanToken = accessToken.startsWith('Bearer ') 
          ? accessToken.substring(7) 
          : accessToken;
      print('Clean token: ${cleanToken.substring(0, 20)}...');
      print('Authorization header: Bearer ${cleanToken.substring(0, 20)}...');
      
      // Try the main logout endpoint first
      var response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.superAdminLogout}'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $cleanToken',
        },
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
              headers: {
                ...ApiConfig.defaultHeaders,
                'Authorization': 'Bearer $cleanToken',
              },
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

  // Renew Standalone Class (SuperAdmin only)
  static Future<Map<String, dynamic>> renewClass(
    String classId,
    RenewClassRequest renewData,
    String accessToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.renewClass}/$classId/renew'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getExpiringClasses}')
          .replace(queryParameters: {'days': daysThreshold.toString()});

      final response = await http.get(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBranchClasses}')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBranchClass}/$classId'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
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
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBranchClassSchedule}/$classId/schedule'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(scheduleData.toJson()),
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
}
