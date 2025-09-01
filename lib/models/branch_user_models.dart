/// Branch User Response Model
class BranchUserResponse {
  final String id;
  final String userId;
  final String branchId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final DateTime? dateOfBirth;
  final bool isActive;
  final bool isVerified;
  final DateTime? firstBooked;
  final DateTime? lastBooked;
  final int totalBookings;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchUserResponse({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    this.dateOfBirth,
    required this.isActive,
    required this.isVerified,
    this.firstBooked,
    this.lastBooked,
    required this.totalBookings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchUserResponse.fromJson(Map<String, dynamic> json) {
    return BranchUserResponse(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      branchId: json['branch_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      firstBooked: json['first_booked'] != null 
          ? DateTime.parse(json['first_booked']) 
          : null,
      lastBooked: json['last_booked'] != null 
          ? DateTime.parse(json['last_booked']) 
          : null,
      totalBookings: json['total_bookings'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Branch User List Response Model
class BranchUserListResponse {
  final List<BranchUserResponse> users;
  final int total;
  final int page;
  final int limit;

  BranchUserListResponse({
    required this.users,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BranchUserListResponse.fromJson(Map<String, dynamic> json) {
    return BranchUserListResponse(
      users: (json['users'] as List?)
          ?.map((userData) => BranchUserResponse.fromJson(userData))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}

/// Branch User Detail Response Model
class BranchUserDetailResponse {
  final BranchUserResponse user;
  final List<BranchUserBooking> bookings;

  BranchUserDetailResponse({
    required this.user,
    required this.bookings,
  });

  factory BranchUserDetailResponse.fromJson(Map<String, dynamic> json) {
    return BranchUserDetailResponse(
      user: BranchUserResponse.fromJson(json['user'] ?? {}),
      bookings: (json['bookings'] as List?)
          ?.map((bookingData) => BranchUserBooking.fromJson(bookingData))
          .toList() ?? [],
    );
  }
}

/// Branch User Booking Model
class BranchUserBooking {
  final String id;
  final String userId;
  final String classId;
  final String classType;
  final String? branchId;
  final String scheduleId;
  final String status;
  final DateTime bookedAt;
  final DateTime classDate;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String className;
  final String instructor;
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  BranchUserBooking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.classType,
    this.branchId,
    required this.scheduleId,
    required this.status,
    required this.bookedAt,
    required this.classDate,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.className,
    required this.instructor,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  factory BranchUserBooking.fromJson(Map<String, dynamic> json) {
    return BranchUserBooking(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      classId: json['class_id'] ?? '',
      classType: json['class_type'] ?? '',
      branchId: json['branch_id'],
      scheduleId: json['schedule_id'] ?? '',
      status: json['status'] ?? '',
      bookedAt: DateTime.parse(json['booked_at']),
      classDate: DateTime.parse(json['class_date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      className: json['class_name'] ?? '',
      instructor: json['instructor'] ?? '',
      userName: json['user_name'],
      userEmail: json['user_email'],
      userPhone: json['user_phone'],
    );
  }
}

/// Branch User Booking List Response Model
class BranchUserBookingListResponse {
  final List<BranchUserBooking> bookings;
  final int total;
  final int page;
  final int limit;

  BranchUserBookingListResponse({
    required this.bookings,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BranchUserBookingListResponse.fromJson(Map<String, dynamic> json) {
    return BranchUserBookingListResponse(
      bookings: (json['bookings'] as List?)
          ?.map((bookingData) => BranchUserBooking.fromJson(bookingData))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}

/// Branch User Stats Response Model
class BranchUserStatsResponse {
  final int totalUsers;
  final int activeUsers;
  final int newUsersThisMonth;
  final int totalBookings;
  final double averageBookingsPerUser;
  final Map<String, int> bookingsByStatus;
  final Map<String, int> bookingsByMonth;

  BranchUserStatsResponse({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersThisMonth,
    required this.totalBookings,
    required this.averageBookingsPerUser,
    required this.bookingsByStatus,
    required this.bookingsByMonth,
  });

  factory BranchUserStatsResponse.fromJson(Map<String, dynamic> json) {
    return BranchUserStatsResponse(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      newUsersThisMonth: json['new_users_this_month'] ?? 0,
      totalBookings: json['total_bookings'] ?? 0,
      averageBookingsPerUser: (json['average_bookings_per_user'] ?? 0.0).toDouble(),
      bookingsByStatus: Map<String, int>.from(json['bookings_by_status'] ?? {}),
      bookingsByMonth: Map<String, int>.from(json['bookings_by_month'] ?? {}),
    );
  }
}
