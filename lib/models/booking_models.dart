class CreateBookingRequest {
  final String classId;
  final String classType;
  final String? branchId;
  final String? branchLocation;
  final String scheduleId;
  final DateTime classDate;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;

  CreateBookingRequest({
    required this.classId,
    required this.classType,
    this.branchId,
    this.branchLocation,
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
    // Include branch location if provided
    if (branchLocation != null && branchLocation!.isNotEmpty) {
      data['branch_location'] = branchLocation;
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
      branchLocation: json['branch_location'],
      scheduleId: json['schedule_id'],
      classDate: DateTime.parse(json['class_date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      notes: json['notes'],
    );
  }
}

class UpdateBookingRequest {
  final String? status;
  final String? notes;

  UpdateBookingRequest({
    this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (status != null && status!.trim().isNotEmpty) {
      data['status'] = status!.trim();
    }

    if (notes != null) {
      final sanitizedNotes = notes!.trim();
      if (sanitizedNotes.isNotEmpty) {
        data['notes'] = sanitizedNotes;
      }
    }

    return data;
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

class ClassScheduleAvailability {
  final String scheduleId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int bookedCount;
  final int availableSlots;
  final bool isAvailable;
  final bool isPast;

  ClassScheduleAvailability({
    required this.scheduleId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.bookedCount,
    required this.availableSlots,
    required this.isAvailable,
    required this.isPast,
  });

  factory ClassScheduleAvailability.fromJson(Map<String, dynamic> json) {
    return ClassScheduleAvailability(
      scheduleId: json['schedule_id']?.toString() ?? '',
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      bookedCount: json['booked_count'] ?? 0,
      availableSlots: json['available_slots'] ?? 0,
      isAvailable: json['is_available'] ?? false,
      isPast: json['is_past'] ?? false,
    );
  }
}

class ClassSchedulesResponse {
  final String classId;
  final String className;
  final String instructor;
  final int capacity;
  final List<ClassScheduleAvailability> schedules;
  final int totalSchedules;

  ClassSchedulesResponse({
    required this.classId,
    required this.className,
    required this.instructor,
    required this.capacity,
    required this.schedules,
    required this.totalSchedules,
  });

  factory ClassSchedulesResponse.fromJson(Map<String, dynamic> json) {
    return ClassSchedulesResponse(
      classId: json['class_id']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? '',
      capacity: json['capacity'] ?? 0,
      schedules: (json['schedules'] as List<dynamic>?)
          ?.map((schedule) => ClassScheduleAvailability.fromJson(schedule))
          .toList() ?? [],
      totalSchedules: json['total_schedules'] ?? 0,
    );
  }
}
