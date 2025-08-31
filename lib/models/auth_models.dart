

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
  final String location;
  final List<ClassModel> classes;
  final List<TeamMemberModel> teamMembers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  BranchResponse({
    required this.id,
    required this.branchName,
    required this.adminName,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.classes,
    required this.teamMembers,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory BranchResponse.fromJson(Map<String, dynamic> json) {
    return BranchResponse(
      id: json['id'] ?? '',
      branchName: json['branch_name'] ?? '',
      adminName: json['admin_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      location: json['location'] ?? '',
      classes: (json['classes'] as List<dynamic>?)
          ?.map((c) => ClassModel.fromJson(c))
          .toList() ?? [],
      teamMembers: (json['team_members'] as List<dynamic>?)
          ?.map((t) => TeamMemberModel.fromJson(t))
          .toList() ?? [],
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

/// Class Model for Branch Creation
class ClassModel {
  final String name;
  final String description;
  final int duration;
  final int capacity;
  final String instructor;

  ClassModel({
    required this.name,
    required this.description,
    required this.duration,
    required this.capacity,
    required this.instructor,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'duration': duration,
      'capacity': capacity,
      'instructor': instructor,
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      capacity: json['capacity'] ?? 0,
      instructor: json['instructor'] ?? '',
    );
  }
}



/// Team Member Model for Branch Creation
class TeamMemberModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String role;

  TeamMemberModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'role': role,
    };
  }

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      role: json['role'] ?? '',
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
  final String location;
  final List<ClassModel> classes;
  final List<TeamMemberModel> teamMembers;

  CreateBranchRequest({
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
  final String? branchName;
  final String? adminName;
  final String? email;
  final String? phoneNumber;
  final String? location;
  final List<ClassModel>? classes;
  final List<TeamMemberModel>? teamMembers;
  final bool? isActive;

  UpdateBranchRequest({
    this.branchName,
    this.adminName,
    this.email,
    this.phoneNumber,
    this.location,
    this.classes,
    this.teamMembers,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (branchName != null) data['branch_name'] = branchName;
    if (adminName != null) data['admin_name'] = adminName;
    if (email != null) data['email'] = email;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (location != null) data['location'] = location;
    if (classes != null) data['classes'] = classes!.map((c) => c.toJson()).toList();
    if (teamMembers != null) data['team_members'] = teamMembers!.map((t) => t.toJson()).toList();
    if (isActive != null) data['is_active'] = isActive;
    return data;
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
      branches: (json['branches'] as List)
          .map((branch) => BranchResponse.fromJson(branch))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}
