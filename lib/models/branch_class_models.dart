import 'standalone_class_models.dart';

/// Branch Class Response Model
class BranchClassResponse {
  final String id;
  final String name;
  final String description;
  final int duration;
  final int capacity;
  final List<ClassSchedule> schedule;
  final String instructor;
  final List<String> images;
  final bool isActive;
  final bool? isVisible; // Visibility flag - if false, class should be hidden from users
  final DateTime? expiresAt;
  final bool isExpired;
  final int bookedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchClassResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.capacity,
    required this.schedule,
    required this.instructor,
    this.images = const [],
    required this.isActive,
    this.isVisible,
    this.expiresAt,
    this.isExpired = false,
    this.bookedCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchClassResponse.fromJson(Map<String, dynamic> json) {
    // Parse expiration date if available
    DateTime? expiresAt;
    bool isExpired = false;
    
    if (json['expires_at'] != null && json['expires_at'].toString().isNotEmpty) {
      try {
        expiresAt = DateTime.parse(json['expires_at'].toString());
        // Check if the class has expired (end date has passed)
        final now = DateTime.now();
        final endOfDay = DateTime(expiresAt.year, expiresAt.month, expiresAt.day, 23, 59, 59);
        isExpired = now.isAfter(endOfDay);
      } catch (e) {
        // If parsing fails, ignore the expiration date
        expiresAt = null;
      }
    } else if (json['end_date'] != null && json['end_date'].toString().isNotEmpty) {
      // Also check for end_date field as an alternative
      try {
        expiresAt = DateTime.parse(json['end_date'].toString());
        final now = DateTime.now();
        final endOfDay = DateTime(expiresAt.year, expiresAt.month, expiresAt.day, 23, 59, 59);
        isExpired = now.isAfter(endOfDay);
      } catch (e) {
        expiresAt = null;
      }
    }
    
    // If is_expired is explicitly provided, use it
    if (json['is_expired'] != null) {
      isExpired = json['is_expired'] == true || json['is_expired'] == 'true';
    }

    return BranchClassResponse(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      duration: json['duration'] ?? 0,
      capacity: json['capacity'] ?? 0,
      schedule: (json['schedule'] as List<dynamic>?)
          ?.map((s) => ClassSchedule.fromJson(s))
          .toList() ?? [],
      instructor: json['instructor']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => image.toString())
          .toList() ?? [],
      isActive: json['is_active'] ?? false,
      isVisible: json['is_visible'] ?? json['IsVisible'] ?? true, // Default to true if not specified
      expiresAt: expiresAt,
      isExpired: isExpired,
      bookedCount: json['booked_count'] != null ? int.tryParse(json['booked_count'].toString()) ?? 0 : 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }
  
  /// Check if the class is expired based on expiration date
  bool get hasExpired {
    if (isExpired) return true;
    if (expiresAt == null) return false;
    final now = DateTime.now();
    final endOfDay = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day, 23, 59, 59);
    return now.isAfter(endOfDay);
  }
}

/// Branch Class List Response Model
class BranchClassListResponse {
  final List<BranchClassResponse> classes;
  final int total;
  final int page;
  final int limit;

  BranchClassListResponse({
    required this.classes,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BranchClassListResponse.fromJson(Map<String, dynamic> json) {
    return BranchClassListResponse(
      classes: (json['classes'] as List<dynamic>?)
          ?.map((classData) => BranchClassResponse.fromJson(classData))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}

/// Update Class Schedule Request Model
class UpdateClassScheduleRequest {
  final List<ClassSchedule> schedule;

  UpdateClassScheduleRequest({
    required this.schedule,
  });

  List<Map<String, dynamic>> toJson() {
    return schedule.map((s) => s.toJson()).toList();
  }
}

/// Update Class Instructor Request Model
class UpdateClassInstructorRequest {
  final String instructor;

  UpdateClassInstructorRequest({
    required this.instructor,
  });

  Map<String, dynamic> toJson() {
    return {
      'instructor': instructor,
    };
  }
}

/// Update Class with Recurring Schedule Request Model
class UpdateClassRecurringRequest {
  final int dayOfWeek; // 0-6 (Sunday=0, Monday=1, ..., Saturday=6)
  final String? newStartTime; // Format: "HH:MM:SS" or "HH:MM"
  final String? newEndTime; // Format: "HH:MM:SS" or "HH:MM"
  final bool updateRecurring;

  UpdateClassRecurringRequest({
    required this.dayOfWeek,
    this.newStartTime,
    this.newEndTime,
    this.updateRecurring = true,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'update_recurring': updateRecurring,
      'day_of_week': dayOfWeek,
    };
    
    if (newStartTime != null) {
      json['new_start_time'] = newStartTime;
    }
    
    if (newEndTime != null) {
      json['new_end_time'] = newEndTime;
    }
    
    return json;
  }
}

/// Bulk Update Class Time Request Model
class BulkUpdateClassTimeRequest {
  final String classID; // ID of the specific class to update
  final int dayOfWeek; // 0-6 (Sunday=0, Monday=1, ..., Saturday=6)
  final String newStartTime; // Format: ISO 8601 datetime string
  final String newEndTime; // Format: ISO 8601 datetime string

  BulkUpdateClassTimeRequest({
    required this.classID,
    required this.dayOfWeek,
    required this.newStartTime,
    required this.newEndTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'class_id': classID,
      'day_of_week': dayOfWeek,
      'new_start_time': newStartTime,
      'new_end_time': newEndTime,
    };
  }
}

/// Bulk Update Class Time Response Model
class BulkUpdateClassTimeResponse {
  final int updatedClassesCount;
  final int updatedSchedulesCount;
  final List<String> updatedDates;
  final String dayOfWeek;

  BulkUpdateClassTimeResponse({
    required this.updatedClassesCount,
    required this.updatedSchedulesCount,
    required this.updatedDates,
    required this.dayOfWeek,
  });

  factory BulkUpdateClassTimeResponse.fromJson(Map<String, dynamic> json) {
    return BulkUpdateClassTimeResponse(
      updatedClassesCount: json['updated_classes_count'] ?? 0,
      updatedSchedulesCount: json['updated_schedules_count'] ?? 0,
      updatedDates: (json['updated_dates'] as List<dynamic>?)
          ?.map((date) => date.toString())
          .toList() ?? [],
      dayOfWeek: json['day_of_week']?.toString() ?? '',
    );
  }
}

/// Update Class Request Model (for updating capacity, schedule, etc.)
class UpdateClassRequest {
  final int? capacity;
  final List<ClassSchedule>? schedule;
  final String? name;
  final String? description;
  final int? duration;
  final String? instructor;
  final bool? isActive;

  UpdateClassRequest({
    this.capacity,
    this.schedule,
    this.name,
    this.description,
    this.duration,
    this.instructor,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (capacity != null) {
      json['capacity'] = capacity;
    }
    
    if (schedule != null) {
      json['schedule'] = schedule!.map((s) => s.toJson()).toList();
    }
    
    if (name != null) {
      json['name'] = name;
    }
    
    if (description != null) {
      json['description'] = description;
    }
    
    if (duration != null) {
      json['duration'] = duration;
    }
    
    if (instructor != null) {
      json['instructor'] = instructor;
    }
    
    if (isActive != null) {
      json['is_active'] = isActive;
    }
    
    return json;
  }
}
