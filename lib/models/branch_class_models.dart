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
  final bool isActive;
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
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchClassResponse.fromJson(Map<String, dynamic> json) {
    return BranchClassResponse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      capacity: json['capacity'] ?? 0,
      schedule: (json['schedule'] as List<dynamic>?)
          ?.map((s) => ClassSchedule.fromJson(s))
          .toList() ?? [],
      instructor: json['instructor'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
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
      classes: (json['classes'] as List)
          .map((classData) => BranchClassResponse.fromJson(classData))
          .toList(),
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

  Map<String, dynamic> toJson() {
    return {
      'schedule': schedule.map((s) => s.toJson()).toList(),
    };
  }
}
