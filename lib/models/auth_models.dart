import 'dart:convert';

/// Signup request model
class SignupRequest {
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String countryCode;
  final DateTime dateOfBirth;

  SignupRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.countryCode,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'date_of_birth': dateOfBirth.toUtc().toIso8601String(),
    };
  }

  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    return SignupRequest(
      fullName: json['full_name'],
      email: json['email'],
      password: json['password'],
      phoneNumber: json['phone_number'],
      countryCode: json['country_code'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
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
  final String phoneNumber;
  final String countryCode;
  final DateTime dateOfBirth;
  final bool isActive;
  final bool isVerified;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserResponse({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.dateOfBirth,
    required this.isActive,
    required this.isVerified,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      countryCode: json['country_code'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      isActive: json['is_active'],
      isVerified: json['is_verified'],
      role: json['role'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
  final String branchName;
  final String adminName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final List<String> classes;
  final List<String> teamMembers;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  BranchResponse({
    required this.id,
    required this.branchName,
    required this.adminName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.classes,
    required this.teamMembers,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory BranchResponse.fromJson(Map<String, dynamic> json) {
    return BranchResponse(
      id: json['id'],
      branchName: json['branch_name'] ?? '',
      adminName: json['admin_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      classes: List<String>.from(json['classes'] ?? []),
      teamMembers: List<String>.from(json['team_members'] ?? []),
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'] ?? '',
    );
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

/// Class Model for Branch
class ClassModel {
  final String? id;
  final String name;
  final String description;
  final int duration;
  final int capacity;
  final List<ClassSchedule> schedule;
  final String instructor;
  final bool isActive;

  ClassModel({
    this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.capacity,
    required this.schedule,
    required this.instructor,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'capacity': capacity,
      'schedule': schedule.map((s) => s.toJson()).toList(),
      'instructor': instructor,
      'is_active': isActive,
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      capacity: json['capacity'] ?? 0,
      schedule: (json['schedule'] as List<dynamic>?)
          ?.map((s) => ClassSchedule.fromJson(s))
          .toList() ?? [],
      instructor: json['instructor'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Class Schedule Model
class ClassSchedule {
  final int dayOfWeek;
  final DateTime startTime;
  final DateTime endTime;

  ClassSchedule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      dayOfWeek: json['day_of_week'] ?? 0,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
    );
  }
}

/// Team Member Model for Branch
class TeamMemberModel {
  final String? id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String role;
  final bool isActive;

  TeamMemberModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.role,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'role': role,
      'is_active': isActive,
    };
  }

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Create Branch Request Model
class CreateBranchRequest {
  final String branchName;
  final String adminName;
  final String email;
  final String password;
  final String phoneNumber;
  final String countryCode;
  final List<ClassModel> classes;
  final List<TeamMemberModel> teamMembers;

  CreateBranchRequest({
    required this.branchName,
    required this.adminName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.countryCode,
    required this.classes,
    required this.teamMembers,
  });

  Map<String, dynamic> toJson() {
    return {
      'branch_name': branchName,
      'admin_name': adminName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'classes': classes.map((c) => c.toJson()).toList(),
      'team_members': teamMembers.map((t) => t.toJson()).toList(),
    };
  }
}
