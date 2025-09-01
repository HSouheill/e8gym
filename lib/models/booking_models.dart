class CreateBookingRequest {
  final String classId;
  final String classType;
  final String? branchId;
  final String scheduleId;
  final DateTime classDate;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;

  CreateBookingRequest({
    required this.classId,
    required this.classType,
    this.branchId,
    required this.scheduleId,
    required this.classDate,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'class_id': classId,
      'class_type': classType,
      'schedule_id': scheduleId,
      'class_date': classDate.toUtc().toIso8601String(),
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
    };
    
    // For branch classes, branch_id is required
    if (classType == 'branch' && branchId != null) {
      data['branch_id'] = branchId;
    }
    if (notes != null) {
      data['notes'] = notes;
    }
    
    return data;
  }

  factory CreateBookingRequest.fromJson(Map<String, dynamic> json) {
    return CreateBookingRequest(
      classId: json['class_id'],
      classType: json['class_type'],
      branchId: json['branch_id'],
      scheduleId: json['schedule_id'],
      classDate: DateTime.parse(json['class_date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      notes: json['notes'],
    );
  }
}

class BookingResponse {
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

  BookingResponse({
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
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      id: json['id'],
      userId: json['user_id'],
      classId: json['class_id'],
      classType: json['class_type'],
      branchId: json['branch_id'],
      scheduleId: json['schedule_id'],
      status: json['status'],
      bookedAt: DateTime.parse(json['booked_at']),
      classDate: DateTime.parse(json['class_date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      className: json['class_name'],
      instructor: json['instructor'],
    );
  }
}

class BookingListResponse {
  final List<BookingResponse> bookings;
  final int total;
  final int page;
  final int limit;

  BookingListResponse({
    required this.bookings,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    return BookingListResponse(
      bookings: (json['bookings'] as List)
          .map((booking) => BookingResponse.fromJson(booking))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}
