import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  final _durationController = TextEditingController();
  
  bool _isLoading = false;
  List<ClassSchedule> _schedules = [];
  
  // Multi-date selection with weekday-based time slots
  // Weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
  Map<int, Set<DateTime>> _weekdayDates = {}; // Map of weekday to set of dates
  Map<int, List<Map<String, TimeOfDay>>> _weekdayTimeSlots = {}; // Time slots for each weekday
  Map<DateTime, List<Map<String, TimeOfDay>>> _dateOverrides = {}; // Custom time slots for specific dates
  TimeOfDay _defaultStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _defaultEndTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _displayMonth = DateTime.now();
  
  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;
  

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructorController.dispose();
    _capacityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Set<DateTime> get _selectedDates {
    Set<DateTime> allDates = {};
    for (final dates in _weekdayDates.values) {
      allDates.addAll(dates);
    }
    allDates.addAll(_dateOverrides.keys);
    return allDates;
  }
  
  bool _isDateInWeekdayGroup(DateTime date) {
    final weekday = date.weekday;
    if (!_weekdayDates.containsKey(weekday)) {
      return false;
    }
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _weekdayDates[weekday]!.contains(normalizedDate);
  }

  List<DateTime> _getAllDaysOfWeekdayInMonth(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    
    List<DateTime> dates = [];
    for (int day = 1; day <= lastDay; day++) {
      final currentDate = DateTime(date.year, date.month, day);
      if (currentDate.weekday == weekday) {
        // Only include future dates or today
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final currentDateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);
        if (!currentDateOnly.isBefore(todayDate)) {
          dates.add(currentDateOnly);
        }
      }
    }
    return dates;
  }

  void _toggleDateSelection(DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final weekday = date.weekday;
      final isCurrentlySelected = _isDateInWeekdayGroup(date) || _dateOverrides.containsKey(normalizedDate);
      
      if (isCurrentlySelected) {
        // Remove this single date from the weekday group if it's in one
        if (_weekdayDates.containsKey(weekday) && _weekdayDates[weekday]!.contains(normalizedDate)) {
          _weekdayDates[weekday]!.remove(normalizedDate);
          if (_weekdayDates[weekday]!.isEmpty) {
            _weekdayDates.remove(weekday);
            _weekdayTimeSlots.remove(weekday);
          }
        }
        
        // Remove override if exists
        _dateOverrides.remove(normalizedDate);
      } else {
        // Create a date override for just this single date (not a weekday group)
        _dateOverrides[normalizedDate] = [
          {'start': _defaultStartTime, 'end': _defaultEndTime}
        ];
      }
      _generateSchedulesFromSelectedDates();
    });
  }

  void _toggleWeekdaySelection(int weekday) {
    setState(() {
      // Find the first occurrence of this weekday in the current month
      int firstWeekdayDate = 1;
      while (firstWeekdayDate <= 7) {
        final testDate = DateTime(_displayMonth.year, _displayMonth.month, firstWeekdayDate);
        if (testDate.weekday == weekday) {
          break;
        }
        firstWeekdayDate++;
      }
      
      // Get all occurrences of this weekday in the current month
      final weekdayDates = _getAllDaysOfWeekdayInMonth(
        DateTime(_displayMonth.year, _displayMonth.month, firstWeekdayDate)
      );
      
      if (weekdayDates.isEmpty) return;
      
      // Check if all dates of this weekday are already selected
      final allSelected = weekdayDates.every((d) => 
        _isDateInWeekdayGroup(d) || _dateOverrides.containsKey(d));
      
      if (allSelected) {
        // Remove all occurrences of this weekday in the month
        if (_weekdayDates.containsKey(weekday)) {
          _weekdayDates[weekday]!.removeWhere((d) => 
            d.year == _displayMonth.year && d.month == _displayMonth.month);
          if (_weekdayDates[weekday]!.isEmpty) {
            _weekdayDates.remove(weekday);
            _weekdayTimeSlots.remove(weekday);
          }
        }
        // Also remove any overrides for these dates
        for (final weekdayDate in weekdayDates) {
          _dateOverrides.remove(weekdayDate);
        }
      } else {
        // Initialize weekday group if it doesn't exist
        if (!_weekdayDates.containsKey(weekday)) {
          _weekdayDates[weekday] = {};
          _weekdayTimeSlots[weekday] = [
            {'start': _defaultStartTime, 'end': _defaultEndTime}
          ];
        }
        
        // Add all occurrences to the weekday group
        for (final weekdayDate in weekdayDates) {
          _weekdayDates[weekday]!.add(weekdayDate);
          // Remove any override for this date since it's now in the weekday group
          _dateOverrides.remove(weekdayDate);
        }
      }
      _generateSchedulesFromSelectedDates();
    });
  }

  void _addTimeSlot(DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      // If date has override, add to override
      if (_dateOverrides.containsKey(normalizedDate)) {
        _dateOverrides[normalizedDate]!.add({
          'start': _defaultStartTime,
          'end': _defaultEndTime
        });
      } else {
        // Check if date is in a weekday group
        final weekday = date.weekday;
        if (_weekdayDates.containsKey(weekday) && _weekdayDates[weekday]!.contains(normalizedDate)) {
          // Add time slot to weekday group (applies to all dates in that weekday group)
          if (!_weekdayTimeSlots.containsKey(weekday)) {
            _weekdayTimeSlots[weekday] = [
              {'start': _defaultStartTime, 'end': _defaultEndTime}
            ];
          }
          _weekdayTimeSlots[weekday]!.add({
            'start': _defaultStartTime,
            'end': _defaultEndTime
          });
        } else {
          // Create override for this specific date (not in any weekday group)
          final weekdaySlots = _weekdayTimeSlots[weekday] ?? [
            {'start': _defaultStartTime, 'end': _defaultEndTime}
          ];
          _dateOverrides[normalizedDate] = [
            for (final slot in weekdaySlots)
              {'start': (slot['start'] as TimeOfDay), 'end': (slot['end'] as TimeOfDay)},
            {'start': _defaultStartTime, 'end': _defaultEndTime}
          ];
        }
      }
      _generateSchedulesFromSelectedDates();
    });
  }

  void _removeTimeSlot(DateTime date, int index) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      if (_dateOverrides.containsKey(normalizedDate)) {
        _dateOverrides[normalizedDate]!.removeAt(index);
        if (_dateOverrides[normalizedDate]!.isEmpty) {
          _dateOverrides.remove(normalizedDate);
        }
      } else {
        // Remove from weekday slots
        final weekday = date.weekday;
        if (_weekdayTimeSlots.containsKey(weekday)) {
          _weekdayTimeSlots[weekday]!.removeAt(index);
          if (_weekdayTimeSlots[weekday]!.isEmpty) {
            _weekdayTimeSlots[weekday] = [
              {'start': _defaultStartTime, 'end': _defaultEndTime}
            ];
          }
        }
      }
      _generateSchedulesFromSelectedDates();
    });
  }

  void _updateTimeSlot(DateTime date, int index, TimeOfDay? startTime, TimeOfDay? endTime) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      if (_dateOverrides.containsKey(normalizedDate)) {
        // Update override
        if (index < _dateOverrides[normalizedDate]!.length) {
          if (startTime != null) {
            _dateOverrides[normalizedDate]![index]['start'] = startTime;
          }
          if (endTime != null) {
            _dateOverrides[normalizedDate]![index]['end'] = endTime;
          }
        }
      } else {
        // Update weekday slot (affects all dates in that weekday group)
        final weekday = date.weekday;
        if (_weekdayTimeSlots.containsKey(weekday) && 
            index < _weekdayTimeSlots[weekday]!.length) {
          if (startTime != null) {
            _weekdayTimeSlots[weekday]![index]['start'] = startTime;
          }
          if (endTime != null) {
            _weekdayTimeSlots[weekday]![index]['end'] = endTime;
          }
        }
      }
      _generateSchedulesFromSelectedDates();
    });
  }
  
  void _createDateOverride(DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final weekday = date.weekday;
      
      // Copy weekday slots to override
      final weekdaySlots = _weekdayTimeSlots[weekday] ?? [
        {'start': _defaultStartTime, 'end': _defaultEndTime}
      ];
      _dateOverrides[normalizedDate] = [
        for (final slot in weekdaySlots)
          {'start': (slot['start'] as TimeOfDay), 'end': (slot['end'] as TimeOfDay)}
      ];
      _generateSchedulesFromSelectedDates();
    });
  }
  
  void _removeDateOverride(DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _dateOverrides.remove(normalizedDate);
      _generateSchedulesFromSelectedDates();
    });
  }

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  void _generateSchedulesFromSelectedDates() {
    _schedules.clear();
    
    // Generate schedules from weekday groups
    for (final entry in _weekdayDates.entries) {
      final weekday = entry.key;
      final dates = entry.value;
      final timeSlots = _weekdayTimeSlots[weekday] ?? [];
      final backendDayOfWeek = weekday == 7 ? 0 : weekday;
      
      for (final date in dates) {
        // Skip if this date has an override (will be handled separately)
        if (_dateOverrides.containsKey(date)) continue;
        
        for (final slot in timeSlots) {
          final startTime = slot['start'] as TimeOfDay;
          final endTime = slot['end'] as TimeOfDay;
          
          _schedules.add(ClassSchedule(
            dayOfWeek: backendDayOfWeek,
            date: date,
            startTime: DateTime.utc(date.year, date.month, date.day, startTime.hour, startTime.minute),
            endTime: DateTime.utc(date.year, date.month, date.day, endTime.hour, endTime.minute),
          ));
        }
      }
    }
    
    // Generate schedules from date overrides
    for (final entry in _dateOverrides.entries) {
      final date = entry.key;
      final timeSlots = entry.value;
      final dartWeekday = date.weekday;
      final backendDayOfWeek = dartWeekday == 7 ? 0 : dartWeekday;
      
      for (final slot in timeSlots) {
        final startTime = slot['start'] as TimeOfDay;
        final endTime = slot['end'] as TimeOfDay;
        
        _schedules.add(ClassSchedule(
          dayOfWeek: backendDayOfWeek,
          date: date,
          startTime: DateTime.utc(date.year, date.month, date.day, startTime.hour, startTime.minute),
          endTime: DateTime.utc(date.year, date.month, date.day, endTime.hour, endTime.minute),
        ));
      }
    }
  }



  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one date is selected with at least one time slot
    if (_weekdayDates.isEmpty && _dateOverrides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text('Please select at least one date for the class schedule', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate that each weekday group has at least one time slot
    for (final entry in _weekdayTimeSlots.entries) {
      if (entry.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getWeekdayName(entry.key)} must have at least one time slot', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // Validate that each date override has at least one time slot
    for (final entry in _dateOverrides.entries) {
      if (entry.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Date ${_formatDateWithDay(entry.key)} must have at least one time slot', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // Validate that all schedules have valid times and dates
    for (int i = 0; i < _schedules.length; i++) {
      final schedule = _schedules[i];
      
      // Validate that the date is not in the past
      final today = DateTime.now();
      final scheduleDate = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      
      if (scheduleDate.isBefore(todayDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: Class date cannot be in the past', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Validate end time is after start time
      if (schedule.endTime.isBefore(schedule.startTime) || schedule.endTime.isAtSameMomentAs(schedule.startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: End time must be after start time', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Validate that start and end times are on the same date as the schedule date
      final startDate = DateTime(schedule.startTime.year, schedule.startTime.month, schedule.startTime.day);
      final endDate = DateTime(schedule.endTime.year, schedule.endTime.month, schedule.endTime.day);
      
      if (!startDate.isAtSameMomentAs(scheduleDate) || !endDate.isAtSameMomentAs(scheduleDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: Start and end times must be on the same date as the schedule date', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Validate that the date matches the day of week
      // Dart weekday: 1=Monday, 7=Sunday; Backend expects: 0=Sunday, 6=Saturday
      final dartWeekday = schedule.date.weekday;
      final expectedDayOfWeek = dartWeekday == 7 ? 0 : dartWeekday;
      if (expectedDayOfWeek != schedule.dayOfWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: Date does not match selected day of week', style: const TextStyle(color: Colors.black)),
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
      // Calculate duration from schedules if not provided
      int? duration;
      if (_durationController.text.isNotEmpty) {
        duration = int.parse(_durationController.text);
      } else {
        // Calculate average duration from schedules
        var totalDuration = 0;
        for (final schedule in _schedules) {
          totalDuration += schedule.endTime.difference(schedule.startTime).inMinutes;
        }
        duration = totalDuration ~/ _schedules.length;
      }

      final request = CreateStandaloneClassRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        instructor: _instructorController.text.trim().isEmpty ? 'TBD' : _instructorController.text.trim(),
        capacity: int.parse(_capacityController.text),
        schedule: _schedules,
        duration: duration,
        images: null, // Images will be uploaded as files, not URLs
        isVisible: true,
      );

      print('=== Form Submission Debug ===');
      print('Regular Schedules count: ${_schedules.length}');
      for (int i = 0; i < _schedules.length; i++) {
        final schedule = _schedules[i];
        print('Schedule $i: Day ${schedule.dayOfWeek}, Start: ${schedule.startTime}, End: ${schedule.endTime}');
      }
      print('Duration: $duration minutes');
      print('Selected images: ${_selectedImages.length}');

      // Set uploading state if images are selected
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });
      }

      final result = await ApiService.createStandaloneClass(
        request,
        widget.accessToken,
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
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
              content: Text(result['message'] ?? 'Failed to create class', style: const TextStyle(color: Colors.black)),
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
            content: Text('An error occurred: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImages = false;
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
            colors: [Colors.white, Colors.white70],
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
                              colors: [Colors.white, Colors.white70],
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
                          'Create Class',
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
                    child: GestureDetector(
                      onTap: () {
                        // Unfocus any text field when tapping outside
                        FocusScope.of(context).unfocus();
                      },
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
                                labelText: 'Instructor (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                helperText: 'Leave empty if no specific instructor',
                              ),
                              validator: (value) {
                                // No validation needed since it's optional
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
                            const SizedBox(height: 16),

                            // Duration Field
                            TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                                helperText: 'Leave empty to calculate from schedule times',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final duration = int.tryParse(value);
                                  if (duration == null || duration <= 0) {
                                    return 'Duration must be greater than 0';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Images Section
                            const Text(
                              'Class Images (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            const Text(
                              'Add images to showcase your class',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Image Selection Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImages,
                                    icon: const Icon(Icons.photo_library, size: 18),
                                    label: const Text('Select Images'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImageFromCamera,
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('Take Photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Selected Images Display
                            if (_selectedImages.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected Images (${_selectedImages.length})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey[300]!),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  _selectedImages[index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeImage(index),
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Schedule Section
                            const Text(
                              'Class Schedule *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            const Text(
                              'Select dates and set times for your class',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Multi-Date Calendar
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Dates (${_selectedDates.length} selected)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 300,
                                    child: _buildMultiDateCalendar(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Weekday Groups with Time Slots
                            ..._weekdayDates.entries.map((entry) {
                              final weekday = entry.key;
                              final dates = entry.value;
                              final timeSlots = _weekdayTimeSlots[weekday] ?? [];
                              final weekdayName = _getWeekdayName(weekday);
                              
                              // Get dates in current display month for this weekday
                              final datesInMonth = dates.where((d) => 
                                d.year == _displayMonth.year && d.month == _displayMonth.month
                              ).toList()..sort();
                              
                              if (datesInMonth.isEmpty) return const SizedBox.shrink();
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'All $weekdayName\'s',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                '${datesInMonth.length} date${datesInMonth.length > 1 ? 's' : ''} in ${_getMonthName(_displayMonth.month)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () {
                                            // Remove all dates of this weekday by toggling the weekday selection
                                            _toggleWeekdaySelection(weekday);
                                          },
                                          tooltip: 'Remove all $weekdayName\'s',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${timeSlots.length} time slot${timeSlots.length > 1 ? 's' : ''} for all $weekdayName\'s',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...timeSlots.asMap().entries.map((slotEntry) {
                                      final slotIndex = slotEntry.key;
                                      final slot = slotEntry.value;
                                      final startTime = slot['start'] as TimeOfDay;
                                      final endTime = slot['end'] as TimeOfDay;
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Slot ${slotIndex + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF926E07),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                  onPressed: timeSlots.length > 1
                                                      ? () => _removeTimeSlot(datesInMonth.first, slotIndex)
                                                      : null,
                                                  tooltip: timeSlots.length > 1
                                                      ? 'Remove time slot'
                                                      : 'At least one time slot is required',
                                                  color: timeSlots.length > 1 ? Colors.red : Colors.grey,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: _buildSimpleTimePicker(
                                                    time: startTime,
                                                    onTimeChanged: (time) {
                                                      _updateTimeSlot(datesInMonth.first, slotIndex, time, null);
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  '—',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  flex: 1,
                                                  child: _buildSimpleTimePicker(
                                                    time: endTime,
                                                    onTimeChanged: (time) {
                                                      _updateTimeSlot(datesInMonth.first, slotIndex, null, time);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _addTimeSlot(datesInMonth.first),
                                            icon: const Icon(Icons.add, size: 18),
                                            label: const Text('Add Time Slot'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            // Show dates list and allow customizing individual dates
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text('$weekdayName Dates'),
                                                content: SizedBox(
                                                  width: double.maxFinite,
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: datesInMonth.length,
                                                    itemBuilder: (context, index) {
                                                      final date = datesInMonth[index];
                                                      final hasOverride = _dateOverrides.containsKey(date);
                                                      return ListTile(
                                                        title: Text(_formatDateWithDay(date)),
                                                        trailing: hasOverride
                                                            ? const Icon(Icons.edit, color: Colors.orange)
                                                            : const Icon(Icons.arrow_forward_ios, size: 16),
                                                        onTap: () {
                                                          Navigator.pop(context);
                                                          if (!hasOverride) {
                                                            _createDateOverride(date);
                                                          }
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.tune, size: 18),
                                          label: const Text('Customize Dates'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: Colors.white),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            
                            // Date Overrides (Custom Dates)
                            if (_dateOverrides.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Custom Date Times',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._dateOverrides.entries.map((entry) {
                                final date = entry.key;
                                final timeSlots = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _formatDateWithDay(date),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: () => _removeDateOverride(date),
                                            tooltip: 'Remove custom time (use weekday default)',
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Custom time for this date',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${timeSlots.length} time slot${timeSlots.length > 1 ? 's' : ''} for this date',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...timeSlots.asMap().entries.map((slotEntry) {
                                        final slotIndex = slotEntry.key;
                                        final slot = slotEntry.value;
                                        final startTime = slot['start'] as TimeOfDay;
                                        final endTime = slot['end'] as TimeOfDay;
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'Slot ${slotIndex + 1}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                    onPressed: timeSlots.length > 1
                                                        ? () => _removeTimeSlot(date, slotIndex)
                                                        : null,
                                                    tooltip: timeSlots.length > 1
                                                        ? 'Remove time slot'
                                                        : 'At least one time slot is required',
                                                    color: timeSlots.length > 1 ? Colors.red : Colors.grey,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    flex: 1,
                                                    child: _buildSimpleTimePicker(
                                                      time: startTime,
                                                      onTimeChanged: (time) {
                                                        _updateTimeSlot(date, slotIndex, time, null);
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    '—',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    flex: 1,
                                                    child: _buildSimpleTimePicker(
                                                      time: endTime,
                                                      onTimeChanged: (time) {
                                                        _updateTimeSlot(date, slotIndex, null, time);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _addTimeSlot(date),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Add Time Slot'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
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
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading || _isUploadingImages
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _isUploadingImages ? 'Uploading Images...' : 'Creating Class...',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
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
                            const SizedBox(height: 40),
                          ],
                        ),
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

  Widget _buildMultiDateCalendar() {
    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_getMonthName(_displayMonth.month)} ${_displayMonth.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Calendar grid
        Expanded(
          child: _buildMultiDateCalendarGrid(_displayMonth),
        ),
      ],
    );
  }

  Widget _buildMultiDateCalendarGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Convert to 0-6 (Sunday = 0)
    final daysInMonth = lastDayOfMonth.day;
    
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return Column(
      children: [
        // Days of week header
        Row(
          children: days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            // Map header index to weekday: 0=Sunday(7), 1=Monday(1), 2=Tuesday(2), etc.
            final weekday = index == 0 ? 7 : index;
            
            // Find the first occurrence of this weekday in the current month
            int firstWeekdayDate = 1;
            while (firstWeekdayDate <= 7) {
              final testDate = DateTime(month.year, month.month, firstWeekdayDate);
              if (testDate.weekday == weekday) {
                break;
              }
              firstWeekdayDate++;
            }
            
            // Check if all days of this weekday in the month are selected
            final weekdayDates = _getAllDaysOfWeekdayInMonth(
              DateTime(month.year, month.month, firstWeekdayDate)
            );
            final allSelected = weekdayDates.isNotEmpty && 
              weekdayDates.every((d) => _isDateInWeekdayGroup(d) || _dateOverrides.containsKey(d));
            
            return Expanded(
              child: GestureDetector(
                onTap: () => _toggleWeekdaySelection(weekday),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: allSelected 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: allSelected 
                          ? const Color(0xFF926E07)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        // Calendar days
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayNumber = index - firstDayWeekday + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final isToday = isCurrentMonth && 
                DateTime(month.year, month.month, dayNumber).day == DateTime.now().day &&
                DateTime(month.year, month.month, dayNumber).month == DateTime.now().month &&
                DateTime(month.year, month.month, dayNumber).year == DateTime.now().year;
              final normalizedDate = DateTime(month.year, month.month, dayNumber);
              final isSelected = isCurrentMonth && 
                (_isDateInWeekdayGroup(normalizedDate) || _dateOverrides.containsKey(normalizedDate));
              final isPast = isCurrentMonth && 
                DateTime(month.year, month.month, dayNumber).isBefore(DateTime.now().subtract(const Duration(days: 1)));
              
              if (!isCurrentMonth) {
                return Container(); // Empty cell for days outside current month
              }
              
              return GestureDetector(
                onTap: isPast ? null : () {
                  final selectedDay = DateTime(month.year, month.month, dayNumber);
                  _toggleDateSelection(selectedDay);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white 
                        : isToday 
                            ? Colors.blue[50] 
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected 
                        ? Border.all(color: Colors.blue, width: 2) 
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      dayNumber.toString(),
                      style: TextStyle(
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                        color: isPast 
                            ? Colors.grey[400]
                            : isSelected 
                                ? Colors.black 
                                : isToday 
                                    ? Colors.blue 
                                    : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDateWithDay(DateTime date) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  Widget _buildSimpleTimePicker({
    required TimeOfDay time,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selectedTime != null) {
          onTimeChanged(selectedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              timeString,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

}