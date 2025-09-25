class CreateStandaloneClassRequest {
  final String name;
  final String description;
  final String instructor;
  final int capacity;
  final List<ClassSchedule> schedule;
  final int? duration;
  final List<String>? images;

  CreateStandaloneClassRequest({
    required this.name,
    required this.description,
    required this.instructor,
    required this.capacity,
    required this.schedule,
    this.duration,
    this.images,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'instructor': instructor,
      'capacity': capacity,
      'schedule': schedule.map((s) => s.toJson()).toList(),
    };
    
    if (duration != null) {
      data['duration'] = duration;
    }
    
    if (images != null) {
      data['images'] = images;
    }
    
    return data;
  }

  factory CreateStandaloneClassRequest.fromJson(Map<String, dynamic> json) {
    return CreateStandaloneClassRequest(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      instructor: json['instructor'] ?? '',
      capacity: json['capacity'] ?? 0,
      schedule: (json['schedule'] as List<dynamic>?)
          ?.map((s) => ClassSchedule.fromJson(s))
          .toList() ?? [],
      duration: json['duration'],
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => image.toString())
          .toList(),
    );
  }
}

class ClassSchedule {
  final int dayOfWeek; // 0 = Sunday, 6 = Saturday
  final DateTime date; // The actual date for this schedule
  final DateTime startTime;
  final DateTime endTime;

  ClassSchedule({
    required this.dayOfWeek,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    // For recurring schedules (placeholder date 2024-01-01), use a more appropriate date
    DateTime scheduleDate;
    if (date.year == 2024 && date.month == 1 && date.day == 1) {
      // This is a recurring schedule, use current date as base
      final now = DateTime.now();
      scheduleDate = DateTime(now.year, now.month, now.day);
    } else {
      // This is a specific date schedule
      scheduleDate = DateTime(date.year, date.month, date.day);
    }
    
    // Convert UTC times back to local times for storage
    final localStartTime = startTime.toLocal();
    final localEndTime = endTime.toLocal();
    
    // Create local DateTime objects with the correct date and time
    final startDateTime = DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day, localStartTime.hour, localStartTime.minute);
    final endDateTime = DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day, localEndTime.hour, localEndTime.minute);
    
    // Create date-only DateTime for the date field (no time component)
    final dateOnly = DateTime.utc(scheduleDate.year, scheduleDate.month, scheduleDate.day);
    
    return {
      'day_of_week': dayOfWeek,
      'date': dateOnly.toIso8601String(),
      'start_time': startDateTime.toUtc().toIso8601String(),
      'end_time': endDateTime.toUtc().toIso8601String(),
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    // Handle both formats: with day_of_week field or without
    int dayOfWeek = 0;
    if (json['day_of_week'] != null) {
      dayOfWeek = int.tryParse(json['day_of_week'].toString()) ?? 0;
    } else {
      // Calculate day of week from the date
      final date = DateTime.parse(json['date']);
      dayOfWeek = date.weekday % 7; // Convert Dart weekday (1-7) to backend format (0-6)
    }
    
    return ClassSchedule(
      dayOfWeek: dayOfWeek,
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
    );
  }
}



class StandaloneClassResponse {
  final String id;
  final String name;
  final String description;
  final String instructor;
  final int duration;
  final int capacity;
  final List<ClassSchedule> schedule;
  final List<String> images;
  final bool isActive;
  final DateTime? expiresAt;
  final bool isExpired;
  final int renewalCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  StandaloneClassResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.instructor,
    required this.duration,
    required this.capacity,
    required this.schedule,
    required this.images,
    required this.isActive,
    this.expiresAt,
    this.isExpired = false,
    this.renewalCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StandaloneClassResponse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory StandaloneClassResponse.fromJson(Map<String, dynamic> json) {
    return StandaloneClassResponse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      instructor: json['instructor'] ?? '',
      duration: json['duration'] != null ? int.tryParse(json['duration'].toString()) ?? 0 : 0,
      capacity: json['capacity'] != null ? int.tryParse(json['capacity'].toString()) ?? 0 : 0,
      schedule: (json['schedule'] as List<dynamic>?)
          ?.map((s) => ClassSchedule.fromJson(s))
          .toList() ?? [],
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => image.toString())
          .toList() ?? [],
      isActive: json['is_active'] ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      isExpired: json['is_expired'] ?? false,
      renewalCount: json['renewal_count'] != null ? int.tryParse(json['renewal_count'].toString()) ?? 0 : 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'] ?? '',
    );
  }
}

/// Update Standalone Class Request Model
class UpdateStandaloneClassRequest {
  final String? name;
  final String? description;
  final String? instructor;
  final int? capacity;
  final List<ClassSchedule>? schedule;
  final int? duration;
  final List<String>? images;
  final bool? isActive;

  UpdateStandaloneClassRequest({
    this.name,
    this.description,
    this.instructor,
    this.capacity,
    this.schedule,
    this.duration,
    this.images,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (instructor != null) data['instructor'] = instructor;
    if (capacity != null) data['capacity'] = capacity;
    if (schedule != null) data['schedule'] = schedule!.map((s) => s.toJson()).toList();
    if (duration != null) data['duration'] = duration;
    if (images != null) data['images'] = images;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}

/// Renew Class Request Model
class RenewClassRequest {
  final int weeksActive;

  RenewClassRequest({
    required this.weeksActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'weeks_active': weeksActive,
    };
  }
}

/// Standalone Class List Response Model
class StandaloneClassListResponse {
  final List<StandaloneClassResponse> classes;
  final int total;
  final int page;
  final int limit;

  StandaloneClassListResponse({
    required this.classes,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory StandaloneClassListResponse.fromJson(Map<String, dynamic> json) {
    return StandaloneClassListResponse(
      classes: (json['classes'] as List<dynamic>?)
          ?.map((classData) => StandaloneClassResponse.fromJson(classData))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}
