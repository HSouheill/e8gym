import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'models/standalone_class_models.dart';

class CreateStandaloneClassPage extends StatefulWidget {
  final String accessToken;
  
  const CreateStandaloneClassPage({
    super.key,
    required this.accessToken,
  });

  @override
  State<CreateStandaloneClassPage> createState() => _CreateStandaloneClassPageState();
}

class _CreateStandaloneClassPageState extends State<CreateStandaloneClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructorController = TextEditingController();
  final _capacityController = TextEditingController();
  
  bool _isLoading = false;
  List<ClassSchedule> _schedules = [];
  
  final List<String> _daysOfWeek = [
    'Sunday (0)', 'Monday (1)', 'Tuesday (2)', 'Wednesday (3)', 'Thursday (4)', 'Friday (5)', 'Saturday (6)'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _addSchedule() {
    setState(() {
      // Use a fixed date (e.g., next Monday) to avoid date-related validation issues
      final now = DateTime.now();
      // Monday = 1 in Dart, Monday = 1 in backend
      final nextMonday = now.add(Duration(days: (8 - now.weekday) % 7));
      
      // Ensure the date matches the day of week
      final targetDate = DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
      
      _schedules.add(ClassSchedule(
        dayOfWeek: 1, // Monday (1) in backend format
        startTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0), // 9:00 AM
        endTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 10, 0), // 10:00 AM
      ));
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  void _updateSchedule(int index, ClassSchedule schedule) {
    setState(() {
      _schedules[index] = schedule;
    });
  }

  void _updateScheduleDay(int index, int newDayOfWeek) {
    if (index >= 0 && index < _schedules.length) {
      final currentSchedule = _schedules[index];
      final now = DateTime.now();
      
      // Convert backend day format (0=Sunday, 1=Monday, ..., 6=Saturday) to Dart format (1=Monday, ..., 7=Sunday)
      int dartWeekday;
      if (newDayOfWeek == 0) {
        dartWeekday = 7; // Sunday
      } else {
        dartWeekday = newDayOfWeek; // Monday=1, Tuesday=2, etc.
      }
      
      // Find the next occurrence of the selected day
      int daysToAdd = (dartWeekday - now.weekday + 7) % 7;
      if (daysToAdd == 0) daysToAdd = 7; // If today is the selected day, go to next week
      
      final targetDate = now.add(Duration(days: daysToAdd));
      
      final newSchedule = ClassSchedule(
        dayOfWeek: newDayOfWeek,
        startTime: DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          currentSchedule.startTime.hour,
          currentSchedule.startTime.minute,
        ),
        endTime: DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          currentSchedule.endTime.hour,
          currentSchedule.endTime.minute,
        ),
      );
      
      _updateSchedule(index, newSchedule);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one schedule is provided
    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one schedule'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate that all schedules have valid times
    for (int i = 0; i < _schedules.length; i++) {
      final schedule = _schedules[i];
      if (schedule.endTime.isBefore(schedule.startTime) || schedule.endTime.isAtSameMomentAs(schedule.startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: End time must be after start time'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Validate that the date matches the day of week
      // Dart weekday: 1=Monday, 7=Sunday; Backend expects: 0=Sunday, 6=Saturday
      final dartWeekday = schedule.startTime.weekday;
      final expectedDayOfWeek = dartWeekday == 7 ? 0 : dartWeekday;
      if (expectedDayOfWeek != schedule.dayOfWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: Date does not match selected day of week'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateStandaloneClassRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        instructor: _instructorController.text.trim(),
        capacity: int.parse(_capacityController.text),
        schedule: _schedules,
      );

      print('=== Form Submission Debug ===');
      print('Schedules count: ${_schedules.length}');
      for (int i = 0; i < _schedules.length; i++) {
        final schedule = _schedules[i];
        print('Schedule $i: Day ${schedule.dayOfWeek}, Start: ${schedule.startTime}, End: ${schedule.endTime}');
      }

      final result = await ApiService.createStandaloneClass(
        request,
        widget.accessToken,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Class created successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create class'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/background.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color(0x50000000),
                BlendMode.darken,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Text(
                          'Create Standalone Class',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(18.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Class Name
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Class Name *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.fitness_center),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a class name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Instructor
                            TextFormField(
                              controller: _instructorController,
                              decoration: const InputDecoration(
                                labelText: 'Instructor *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an instructor name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Capacity Field
                            TextFormField(
                              controller: _capacityController,
                              decoration: const InputDecoration(
                                labelText: 'Capacity *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.people),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter capacity';
                                }
                                final capacity = int.tryParse(value);
                                if (capacity == null || capacity <= 0) {
                                  return 'Capacity must be greater than 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Schedule Section
                            const Text(
                              'Schedule *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'At least one schedule is required',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Add Schedule Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _addSchedule,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Schedule'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF8BB0C),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Schedule List
                            if (_schedules.isNotEmpty) ...[
                              ..._schedules.asMap().entries.map((entry) {
                                final index = entry.key;
                                final schedule = entry.value;
                                return _buildScheduleCard(index, schedule);
                              }).toList(),
                            ],

                            const SizedBox(height: 32),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF8BB0C),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      )
                                    : const Text(
                                        'Create Class',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(int index, ClassSchedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schedule ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => _removeSchedule(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Remove Schedule',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Day of Week
          DropdownButtonFormField<int>(
            value: schedule.dayOfWeek,
            decoration: const InputDecoration(
              labelText: 'Day of Week',
              border: OutlineInputBorder(),
            ),
            items: _daysOfWeek.asMap().entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateScheduleDay(index, value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Time Row
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Start Time',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      onPressed: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(schedule.startTime),
                                        );
                                        if (time != null) {
                                          // Create a new DateTime with the selected time but keep the same date
                                          final newDateTime = DateTime(
                                            schedule.startTime.year,
                                            schedule.startTime.month,
                                            schedule.startTime.day,
                                            time.hour,
                                            time.minute,
                                          );
                                          _updateSchedule(index, ClassSchedule(
                                            dayOfWeek: schedule.dayOfWeek,
                                            startTime: newDateTime,
                                            endTime: schedule.endTime,
                                          ));
                                        }
                                      },
                                      icon: const Icon(Icons.access_time),
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'End Time',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      onPressed: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(schedule.endTime),
                                        );
                                        if (time != null) {
                                          // Create a new DateTime with the selected time but keep the same date
                                          final newDateTime = DateTime(
                                            schedule.endTime.year,
                                            schedule.endTime.month,
                                            schedule.endTime.day,
                                            time.hour,
                                            time.minute,
                                          );
                                          _updateSchedule(index, ClassSchedule(
                                            dayOfWeek: schedule.dayOfWeek,
                                            startTime: schedule.startTime,
                                            endTime: newDateTime,
                                          ));
                                        }
                                      },
                                      icon: const Icon(Icons.access_time),
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                }
