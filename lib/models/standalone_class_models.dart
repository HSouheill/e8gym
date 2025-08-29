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
      'dayOfWeek': dayOfWeek,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      dayOfWeek: json['dayOfWeek'] ?? 0,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
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
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'] ?? '',
    );
  }
}
