import 'standalone_class_models.dart';
import 'package:flutter/foundation.dart';

/// Signup request model
class SignupRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? countryCode;
  final DateTime? dateOfBirth;
  final String? branchId;

  SignupRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.countryCode,
    this.dateOfBirth,
    this.branchId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'full_name': fullName,
      'email': email,
      'password': password,
    };
    
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      data['phone_number'] = phoneNumber;
    }
    
    if (countryCode != null && countryCode!.isNotEmpty) {
      data['country_code'] = countryCode;
    }
    
    if (dateOfBirth != null) {
      data['date_of_birth'] = dateOfBirth!.toUtc().toIso8601String();
    }
    
    if (branchId != null) {
      data['branch_id'] = branchId;
    }
    
    return data;
  }

  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    return SignupRequest(
      fullName: json['full_name'],
      email: json['email'],
      password: json['password'],
      phoneNumber: json['phone_number'],
      countryCode: json['country_code'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      branchId: json['branch_id'],
    );
  }
}

/// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'],
      password: json['password'],
    );
  }
}

/// User response model
class UserResponse {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? countryCode;
  final DateTime? dateOfBirth;
  final double? height;
  final double? weight;
  final String? branchID;
  final String? imageURL;
  final bool isActive;
  final bool isVerified;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserResponse({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.countryCode,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.branchID,
    this.imageURL,
    required this.isActive,
    required this.isVerified,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'full_name': fullName,
      'email': email,
      'is_active': isActive,
      'is_verified': isVerified,
      'role': role,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
    
    if (phoneNumber != null) {
      data['phone_number'] = phoneNumber;
    }
    
    if (countryCode != null) {
      data['country_code'] = countryCode;
    }
    
    if (dateOfBirth != null) {
      data['date_of_birth'] = dateOfBirth!.toUtc().toIso8601String();
    }
    
    if (height != null) {
      data['height'] = height;
    }
    
    if (weight != null) {
      data['weight'] = weight;
    }
    
    if (branchID != null) {
      data['branch_id'] = branchID;
    }
    
    if (imageURL != null) {
      data['image_url'] = imageURL;
    }
    
    return data;
  }

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['full_name'] ?? json['FullName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['PhoneNumber'],
      countryCode: json['country_code'] ?? json['CountryCode'],
      dateOfBirth: json['date_of_birth'] != null || json['DateOfBirth'] != null
          ? DateTime.parse(json['date_of_birth'] ?? json['DateOfBirth'])
          : null,
      height: json['height'] != null ? (json['height'] is double ? json['height'] : (json['height'] as num).toDouble()) : null,
      weight: json['weight'] != null ? (json['weight'] is double ? json['weight'] : (json['weight'] as num).toDouble()) : null,
      branchID: json['branch_id']?.toString() ?? json['BranchID']?.toString(),
      imageURL: json['image_url'] ?? json['ImageURL'],
      isActive: json['is_active'] ?? json['IsActive'] ?? false,
      isVerified: json['is_verified'] ?? json['IsVerified'] ?? false,
      role: json['role'] ?? json['Role'] ?? 'user',
      createdAt: json['created_at'] != null || json['CreatedAt'] != null
          ? DateTime.parse(json['created_at'] ?? json['CreatedAt'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null || json['UpdatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['UpdatedAt'])
          : DateTime.now(),
    );
  }
  
  UserResponse copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? countryCode,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? branchID,
    String? imageURL,
    bool? isActive,
    bool? isVerified,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserResponse(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      branchID: branchID ?? this.branchID,
      imageURL: imageURL ?? this.imageURL,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Authentication response model
class AuthResponse {
  final UserResponse user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserResponse.fromJson(json['user']),
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
    );
  }
}

/// Refresh token response model
class RefreshTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  RefreshTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
    );
  }
}

/// Branch Login Request Model
class BranchLoginRequest {
  final String email;
  final String password;

  BranchLoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory BranchLoginRequest.fromJson(Map<String, dynamic> json) {
    return BranchLoginRequest(
      email: json['email'],
      password: json['password'],
    );
  }
}

/// Branch Response Model
class BranchResponse {
  final String id;
  final String? branchId;
  final String branchName;
  final String adminName;
  final String email;
  final String phoneNumber;
  final String location;
  final String? image;
  final List<ClassModel> classes;
  final List<TeamMemberModel> teamMembers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  BranchResponse({
    required this.id,
    this.branchId,
    required this.branchName,
    required this.adminName,
    required this.email,
    required this.phoneNumber,
    required this.location,
    this.image,
    required this.classes,
    required this.teamMembers,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory BranchResponse.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) print('=== BranchResponse.fromJson Debug ===');
    if (kDebugMode) print('Branch Name: ${json['branch_name']}');
    if (kDebugMode) print('Branch ID: ${json['branch_id']}');
    if (kDebugMode) print('Image field: ${json['image']}');
    if (kDebugMode) print('Image URL field: ${json['image_url']}');
    if (kDebugMode) print('Image type: ${json['image'].runtimeType}');
    if (kDebugMode) print('Image is null: ${json['image'] == null}');
    if (kDebugMode) print('Image is empty: ${json['image']?.toString().isEmpty ?? true}');
    if (kDebugMode) print('====================================');
    
    // Construct full image URL from image_url field (API response field)
    String? imageUrl;
    final imageUrlValue = json['image_url'];
    
    // Check if image_url exists and is not empty
    if (imageUrlValue != null && imageUrlValue.toString().trim().isNotEmpty) {
      final imagePath = imageUrlValue.toString().trim();
      imageUrl = _normalizeImageUrl(imagePath);
      if (kDebugMode) print('=== BranchResponse Image URL ===');
      if (kDebugMode) print('API image_url field: $imagePath');
      if (kDebugMode) print('Normalized URL: $imageUrl');
      if (kDebugMode) print('================================');
    } else {
      if (kDebugMode) print('=== BranchResponse Image URL ===');
      if (kDebugMode) print('No image_url found or empty');
      if (kDebugMode) print('================================');
    }
    
    // Safely parse classes list
    List<ClassModel> classesList = [];
    if (json['classes'] != null && json['classes'] is List) {
      try {
        classesList = (json['classes'] as List<dynamic>)
            .map((c) => ClassModel.fromJson(c))
            .toList();
      } catch (e) {
        if (kDebugMode) print('Error parsing classes: $e');
        classesList = [];
      }
    }
    
    // Safely parse team members list
    List<TeamMemberModel> teamMembersList = [];
    if (json['team_members'] != null && json['team_members'] is List) {
      try {
        teamMembersList = (json['team_members'] as List<dynamic>)
            .map((t) => TeamMemberModel.fromJson(t))
            .toList();
      } catch (e) {
        if (kDebugMode) print('Error parsing team_members: $e');
        teamMembersList = [];
      }
    }
    
    return BranchResponse(
      id: json['id'] ?? '',
      branchId: json['branch_id'] ?? '',
      branchName: json['branch_name'] ?? '',
      adminName: json['admin_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      location: json['location'] ?? '',
      image: imageUrl,
      classes: classesList,
      teamMembers: teamMembersList,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'] ?? '',
    );
  }
  
  // Helper function to normalize image URLs
  static String _normalizeImageUrl(String url) {
    // If already a full URL, check if it incorrectly contains /uploads/branch/
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Remove /uploads/ from branch paths if present
      if (url.contains('/uploads/branch/')) {
        return url.replaceAll('/uploads/branch/', '/branch/');
      }
      return url;
    }
    
    // Remove /uploads/ prefix if present for branch paths
    String cleanUrl = url;
    if (cleanUrl.contains('/uploads/branch/')) {
      cleanUrl = cleanUrl.replaceAll('/uploads/branch/', 'branch/');
    } else if (cleanUrl.contains('uploads/branch/')) {
      cleanUrl = cleanUrl.replaceAll('uploads/branch/', 'branch/');
    }
    
    // Handle branch/ paths from API image_url field
    // The API returns "branch/1765219735.jpg" which should be accessed from uploads/
    if (cleanUrl.startsWith('branch/') || cleanUrl.startsWith('/branch/')) {
      final path = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
      // Access from uploads directory: uploads/branch/1765219735.jpg
      return 'https://e8gym.online/uploads/$path';
    }
    
    // Handle relative paths
    if (cleanUrl.startsWith('/app/')) {
      return 'https://e8gym.online/uploads${cleanUrl.substring(1)}';
    } else if (cleanUrl.startsWith('app/')) {
      return 'https://e8gym.online/uploads/$cleanUrl';
    } else if (cleanUrl.startsWith('/uploads/')) {
      return 'https://e8gym.online$cleanUrl';
    } else if (cleanUrl.startsWith('uploads/')) {
      return 'https://e8gym.online/$cleanUrl';
    }
    
    // Default: prepend uploads/ if not already present
    return 'https://e8gym.online/uploads/$cleanUrl';
  }
}

/// Branch Login Response Model
class BranchLoginResponse {
  final BranchResponse branch;
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  BranchLoginResponse({
    required this.branch,
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory BranchLoginResponse.fromJson(Map<String, dynamic> json) {
    return BranchLoginResponse(
      branch: BranchResponse.fromJson(json['branch']),
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
    );
  }
}

/// Branch Password Reset Request Model
class BranchPasswordResetRequest {
  final String email;

  BranchPasswordResetRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }

  factory BranchPasswordResetRequest.fromJson(Map<String, dynamic> json) {
    return BranchPasswordResetRequest(
      email: json['email'],
    );
  }
}

/// Branch Password Reset Confirm Model
class BranchPasswordResetConfirm {
  final String email;
  final String otp;
  final String password;

  BranchPasswordResetConfirm({
    required this.email,
    required this.otp,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
      'password': password,
    };
  }

  factory BranchPasswordResetConfirm.fromJson(Map<String, dynamic> json) {
    return BranchPasswordResetConfirm(
      email: json['email'],
      otp: json['otp'],
      password: json['password'],
    );
  }
}

/// Class Model for Branch Creation
class ClassModel {
  final String? id;
  final String name;
  final String description;
  final int duration;
  final int capacity;
  final String instructor;
  final List<ClassSchedule> schedule;
  final bool? isVisible;

  ClassModel({
    this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.capacity,
    required this.instructor,
    this.schedule = const [],
    this.isVisible,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'duration': duration,
      'capacity': capacity,
      'instructor': instructor,
      'schedule': schedule.map((s) => s.toJson()).toList(),
    };
    if (id != null) data['id'] = id;
    if (isVisible != null) data['is_visible'] = isVisible;
    return data;
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      capacity: json['capacity'] ?? 0,
      instructor: json['instructor'] ?? '',
      schedule: (json['schedule'] as List<dynamic>?)
          ?.map((s) => ClassSchedule.fromJson(s))
          .toList() ?? [],
      isVisible: json['is_visible'] ?? json['IsVisible'],
    );
  }
  
  ClassModel copyWith({
    String? id,
    String? name,
    String? description,
    int? duration,
    int? capacity,
    String? instructor,
    List<ClassSchedule>? schedule,
    bool? isVisible,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      capacity: capacity ?? this.capacity,
      instructor: instructor ?? this.instructor,
      schedule: schedule ?? this.schedule,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}



/// Team Member Model for Branch Creation
class TeamMemberModel {
  final String? id; // ID from backend (null for new members)
  final String fullName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String role;
  final String password; // Required for team member creation

  TeamMemberModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.role,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    // Ensure password is always included and not empty
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty for team member');
    }
    
    // Include both lowercase and capitalized versions to ensure backend compatibility
    // Some Go structs might expect "Password" (capital P) instead of "password"
    return {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'role': role,
      'password': password, // Standard lowercase (most common)
      'Password': password, // Capitalized version (in case backend expects this)
    };
  }

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      role: json['role'] ?? '',
      password: json['password'] ?? '', // Note: password is not returned in responses for security
    );
  }
}

/// Team Member Request Model (for adding new team member)
class TeamMemberRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String role;
  final String password;

  TeamMemberRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.role,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'role': role,
      'password': password,
    };
  }
}

/// Team Member Update Request Model (for updating existing team member)
class TeamMemberUpdateRequest {
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? countryCode;
  final String? role;
  final String? password;
  final bool? isActive;

  TeamMemberUpdateRequest({
    this.fullName,
    this.email,
    this.phoneNumber,
    this.countryCode,
    this.role,
    this.password,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (countryCode != null) data['country_code'] = countryCode;
    if (role != null) data['role'] = role;
    if (password != null) data['password'] = password;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}

/// Create Branch Request Model
class CreateBranchRequest {
  final String branchID;
  final String branchName;
  final String adminName;
  final String email;
  final String password;
  final String phoneNumber;
  final String location;
  final List<ClassModel> classes;
  final List<TeamMemberModel> teamMembers;

  CreateBranchRequest({
    required this.branchID,
    required this.branchName,
    required this.adminName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.location,
    this.classes = const [],
    this.teamMembers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchID,
      'branch_name': branchName,
      'admin_name': adminName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'location': location,
      'classes': classes.map((c) => c.toJson()).toList(),
      'team_members': teamMembers.map((t) => t.toJson()).toList(),
    };
  }
}

/// Update Branch Request Model
class UpdateBranchRequest {
  final String? branchId;
  final String? branchName;
  final String? adminName;
  final String? email;
  final String? phoneNumber;
  final String? location;
  final String? image;
  final List<ClassModel>? classes;
  final List<TeamMemberModel>? teamMembers;
  final bool? isActive;

  UpdateBranchRequest({
    this.branchId,
    this.branchName,
    this.adminName,
    this.email,
    this.phoneNumber,
    this.location,
    this.image,
    this.classes,
    this.teamMembers,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (branchId != null) data['branch_id'] = branchId;
    if (branchName != null) data['branch_name'] = branchName;
    if (adminName != null) data['admin_name'] = adminName;
    if (email != null) data['email'] = email;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (location != null) data['location'] = location;
    if (image != null) data['image'] = image;
    if (classes != null) data['classes'] = classes!.map((c) => c.toJson()).toList();
    if (teamMembers != null) data['team_members'] = teamMembers!.map((t) => t.toJson()).toList();
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}

/// BMI Response Model
class BMIResponse {
  final double bmi;
  final String category;
  final String description;
  final double height;
  final double weight;
  final String healthAdvice;
  final List<String> citations;
  final String disclaimer;

  BMIResponse({
    required this.bmi,
    required this.category,
    required this.description,
    required this.height,
    required this.weight,
    required this.healthAdvice,
    this.citations = const [
      'World Health Organization (WHO) - BMI Classification Standards',
      'Centers for Disease Control and Prevention (CDC) - BMI Calculator and Information',
      'National Heart, Lung, and Blood Institute - BMI Guidelines',
    ],
    this.disclaimer = 'BMI information is for educational purposes only and should not be considered medical advice. Consult healthcare professionals for medical decisions.',
  });

  factory BMIResponse.fromJson(Map<String, dynamic> json) {
    return BMIResponse(
      bmi: (json['bmi'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      height: (json['height'] ?? 0.0).toDouble(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      healthAdvice: json['health_advice'] ?? '',
      citations: (json['citations'] as List<dynamic>?)
          ?.map((c) => c.toString())
          .toList() ?? [
        'World Health Organization (WHO) - BMI Classification Standards',
        'Centers for Disease Control and Prevention (CDC) - BMI Calculator and Information',
        'National Heart, Lung, and Blood Institute - BMI Guidelines',
      ],
      disclaimer: json['disclaimer'] ?? 'BMI information is for educational purposes only and should not be considered medical advice. Consult healthcare professionals for medical decisions.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bmi': bmi,
      'category': category,
      'description': description,
      'height': height,
      'weight': weight,
      'health_advice': healthAdvice,
      'citations': citations,
      'disclaimer': disclaimer,
    };
  }
}

/// Branch List Response Model
class BranchListResponse {
  final List<BranchResponse> branches;
  final int total;
  final int page;
  final int limit;

  BranchListResponse({
    required this.branches,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BranchListResponse.fromJson(Map<String, dynamic> json) {
    return BranchListResponse(
      branches: (json['branches'] as List?)
          ?.map((branch) => BranchResponse.fromJson(branch))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}

/// Update User Data Request Model
class UpdateUserDataRequest {
  final String? fullName;
  final String? phoneNumber;
  final String? countryCode;
  final DateTime? dateOfBirth;
  final double? height;
  final double? weight;

  UpdateUserDataRequest({
    this.fullName,
    this.phoneNumber,
    this.countryCode,
    this.dateOfBirth,
    this.height,
    this.weight,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (fullName != null) data['full_name'] = fullName;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (countryCode != null) data['country_code'] = countryCode;
    if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth!.toUtc().toIso8601String();
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    return data;
  }
}

/// Change Password Request Model
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
    };
  }
}

/// Change Branch Request Model
class ChangeBranchRequest {
  final String branchId;

  ChangeBranchRequest({
    required this.branchId,
  });

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchId,
    };
  }
}

/// Change Branch Response Model
class ChangeBranchResponse {
  final UserResponse user;
  final BranchResponse branch;

  ChangeBranchResponse({
    required this.user,
    required this.branch,
  });

  factory ChangeBranchResponse.fromJson(Map<String, dynamic> json) {
    return ChangeBranchResponse(
      user: UserResponse.fromJson(json['user']),
      branch: BranchResponse.fromJson(json['branch']),
    );
  }
}
