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
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchClassResponse.fromJson(Map<String, dynamic> json) {
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
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
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
