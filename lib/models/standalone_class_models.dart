class CreateStandaloneClassRequest {
  final String name;
  final String description;
  final String instructor;
  final int capacity;
  final List<ClassSchedule> schedule;

  CreateStandaloneClassRequest({
    required this.name,
    required this.description,
    required this.instructor,
    required this.capacity,
    required this.schedule,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'instructor': instructor,
      'capacity': capacity,
      'schedule': schedule.map((s) => s.toJson()).toList(),
    };
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
    );
  }
}

class ClassSchedule {
  final int dayOfWeek; // 0 = Sunday, 6 = Saturday
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
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
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

class StandaloneClassResponse {
  final String id;
  final String name;
  final String description;
  final String instructor;
  final int capacity;
  final List<ClassSchedule> schedule;
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
    required this.capacity,
    required this.schedule,
    required this.isActive,
    this.expiresAt,
    this.isExpired = false,
    this.renewalCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory StandaloneClassResponse.fromJson(Map<String, dynamic> json) {
    return StandaloneClassResponse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      instructor: json['instructor'] ?? '',
      capacity: json['capacity'] ?? 0,
      schedule: (json['schedule'] as List<dynamic>?)
          ?.map((s) => ClassSchedule.fromJson(s))
          .toList() ?? [],
      isActive: json['is_active'] ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      isExpired: json['is_expired'] ?? false,
      renewalCount: json['renewal_count'] ?? 0,
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
  final bool? isActive;

  UpdateStandaloneClassRequest({
    this.name,
    this.description,
    this.instructor,
    this.capacity,
    this.schedule,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (instructor != null) data['instructor'] = instructor;
    if (capacity != null) data['capacity'] = capacity;
    if (schedule != null) data['schedule'] = schedule!.map((s) => s.toJson()).toList();
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
      classes: (json['classes'] as List)
          .map((classData) => StandaloneClassResponse.fromJson(classData))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}
