import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';
import 'models/standalone_class_models.dart';
import 'utils/app_colors.dart';

class EditStandaloneClassPage extends StatefulWidget {
  final String accessToken;
  final StandaloneClassResponse classData;
  
  const EditStandaloneClassPage({
    super.key,
    required this.accessToken,
    required this.classData,
  });

  @override
  State<EditStandaloneClassPage> createState() => _EditStandaloneClassPageState();
}

class _EditStandaloneClassPageState extends State<EditStandaloneClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructorController = TextEditingController();
  final _capacityController = TextEditingController();
  final _durationController = TextEditingController();
  
  bool _isLoading = false;
  List<ClassSchedule> _schedules = [];
  bool _isActive = true;
  
  // Multi-date selection
  Set<DateTime> _selectedDates = {};
  TimeOfDay _defaultStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _defaultEndTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _displayMonth = DateTime.now();
  
  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  List<String> _existingImages = [];
  

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.classData.name;
    _descriptionController.text = widget.classData.description;
    _instructorController.text = widget.classData.instructor;
    _capacityController.text = widget.classData.capacity.toString();
    _durationController.text = widget.classData.duration.toString();
    _isActive = widget.classData.isActive;
    
    // Initialize existing images
    _existingImages = List.from(widget.classData.images);
    
    // Initialize schedules
    if (widget.classData.schedule.isNotEmpty) {
      _schedules = List.from(widget.classData.schedule);
      // Populate selected dates from existing schedules
      _selectedDates = _schedules.map((schedule) => schedule.date).toSet();
      // Set default times from first schedule
      if (_schedules.isNotEmpty) {
        _defaultStartTime = TimeOfDay.fromDateTime(_schedules.first.startTime);
        _defaultEndTime = TimeOfDay.fromDateTime(_schedules.first.endTime);
      }
    }
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

  void _toggleDateSelection(DateTime date) {
    setState(() {
      if (_selectedDates.contains(date)) {
        _selectedDates.remove(date);
      } else {
        _selectedDates.add(date);
      }
      _generateSchedulesFromSelectedDates();
    });
  }

  void _generateSchedulesFromSelectedDates() {
    // Store existing custom times before regenerating
    final Map<DateTime, ClassSchedule> existingSchedules = {};
    for (final schedule in _schedules) {
      final dateKey = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      existingSchedules[dateKey] = schedule;
    }
    
    _schedules.clear();
    for (final date in _selectedDates) {
      final dartWeekday = date.weekday;
      final backendDayOfWeek = dartWeekday == 7 ? 0 : dartWeekday;
      
      final dateKey = DateTime(date.year, date.month, date.day);
      final existingSchedule = existingSchedules[dateKey];
      
      // Use existing schedule times if available, otherwise use default times
      final startTime = existingSchedule != null
          ? existingSchedule.startTime
          : DateTime.utc(date.year, date.month, date.day, _defaultStartTime.hour, _defaultStartTime.minute);
      final endTime = existingSchedule != null
          ? existingSchedule.endTime
          : DateTime.utc(date.year, date.month, date.day, _defaultEndTime.hour, _defaultEndTime.minute);
      
      _schedules.add(ClassSchedule(
        dayOfWeek: backendDayOfWeek,
        date: date,
        startTime: startTime,
        endTime: endTime,
      ));
    }
  }

  void _updateScheduleTime(DateTime date, TimeOfDay? startTime, TimeOfDay? endTime) {
    setState(() {
      final scheduleIndex = _schedules.indexWhere((s) => 
        s.date.year == date.year && 
        s.date.month == date.month && 
        s.date.day == date.day
      );
      
      if (scheduleIndex != -1) {
        final schedule = _schedules[scheduleIndex];
        final updatedStartTime = startTime != null
            ? DateTime.utc(date.year, date.month, date.day, startTime.hour, startTime.minute)
            : schedule.startTime;
        final updatedEndTime = endTime != null
            ? DateTime.utc(date.year, date.month, date.day, endTime.hour, endTime.minute)
            : schedule.endTime;
        
        _schedules[scheduleIndex] = ClassSchedule(
          dayOfWeek: schedule.dayOfWeek,
          date: schedule.date,
          startTime: updatedStartTime,
          endTime: updatedEndTime,
        );
      }
    });
  }

  void _changeDate(DateTime oldDate, DateTime newDate) {
    setState(() {
      // Normalize dates
      final normalizedOldDate = DateTime(oldDate.year, oldDate.month, oldDate.day);
      final normalizedNewDate = DateTime(newDate.year, newDate.month, newDate.day);
      
      // Check if new date is already selected
      final isNewDateAlreadySelected = _selectedDates.any((d) => 
        d.year == normalizedNewDate.year && 
        d.month == normalizedNewDate.month && 
        d.day == normalizedNewDate.day
      );
      
      if (isNewDateAlreadySelected) {
        _showSnackBar('This date is already selected');
        return;
      }
      
      // Check if new date is in the past
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      if (normalizedNewDate.isBefore(todayDate)) {
        _showSnackBar('Cannot select a date in the past');
        return;
      }
      
      // Get the schedule for the old date to preserve times
      final scheduleIndex = _schedules.indexWhere((s) => 
        s.date.year == normalizedOldDate.year && 
        s.date.month == normalizedOldDate.month && 
        s.date.day == normalizedOldDate.day
      );
      
      TimeOfDay? preservedStartTime;
      TimeOfDay? preservedEndTime;
      
      if (scheduleIndex != -1) {
        final schedule = _schedules[scheduleIndex];
        preservedStartTime = TimeOfDay.fromDateTime(schedule.startTime);
        preservedEndTime = TimeOfDay.fromDateTime(schedule.endTime);
      }
      
      // Find and remove the exact old date from the set
      _selectedDates.removeWhere((d) => 
        d.year == normalizedOldDate.year && 
        d.month == normalizedOldDate.month && 
        d.day == normalizedOldDate.day
      );
      
      // Remove old schedule
      if (scheduleIndex != -1) {
        _schedules.removeAt(scheduleIndex);
      }
      
      // Add new date
      _selectedDates.add(normalizedNewDate);
      
      // Create new schedule with preserved times or default times
      final dartWeekday = normalizedNewDate.weekday;
      final backendDayOfWeek = dartWeekday == 7 ? 0 : dartWeekday;
      
      final newStartTime = preservedStartTime != null
          ? DateTime.utc(normalizedNewDate.year, normalizedNewDate.month, normalizedNewDate.day, 
                        preservedStartTime.hour, preservedStartTime.minute)
          : DateTime.utc(normalizedNewDate.year, normalizedNewDate.month, normalizedNewDate.day, 
                        _defaultStartTime.hour, _defaultStartTime.minute);
      
      final newEndTime = preservedEndTime != null
          ? DateTime.utc(normalizedNewDate.year, normalizedNewDate.month, normalizedNewDate.day, 
                        preservedEndTime.hour, preservedEndTime.minute)
          : DateTime.utc(normalizedNewDate.year, normalizedNewDate.month, normalizedNewDate.day, 
                        _defaultEndTime.hour, _defaultEndTime.minute);
      
      _schedules.add(ClassSchedule(
        dayOfWeek: backendDayOfWeek,
        date: normalizedNewDate,
        startTime: newStartTime,
        endTime: newEndTime,
      ));
    });
  }

  TimeOfDay _getStartTimeForDate(DateTime date) {
    final schedule = _schedules.firstWhere(
      (s) => s.date.year == date.year && 
             s.date.month == date.month && 
             s.date.day == date.day,
      orElse: () => ClassSchedule(
        dayOfWeek: date.weekday % 7,
        date: date,
        startTime: DateTime.utc(date.year, date.month, date.day, _defaultStartTime.hour, _defaultStartTime.minute),
        endTime: DateTime.utc(date.year, date.month, date.day, _defaultEndTime.hour, _defaultEndTime.minute),
      ),
    );
    return TimeOfDay.fromDateTime(schedule.startTime);
  }

  TimeOfDay _getEndTimeForDate(DateTime date) {
    final schedule = _schedules.firstWhere(
      (s) => s.date.year == date.year && 
             s.date.month == date.month && 
             s.date.day == date.day,
      orElse: () => ClassSchedule(
        dayOfWeek: date.weekday % 7,
        date: date,
        startTime: DateTime.utc(date.year, date.month, date.day, _defaultStartTime.hour, _defaultStartTime.minute),
        endTime: DateTime.utc(date.year, date.month, date.day, _defaultEndTime.hour, _defaultEndTime.minute),
      ),
    );
    return TimeOfDay.fromDateTime(schedule.endTime);
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
          _selectedImages.addAll(images.map((image) => File(image.path)));
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

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }


  bool _schedulesChanged() {
    if (_schedules.length != widget.classData.schedule.length) {
      return true;
    }
    
    for (int i = 0; i < _schedules.length; i++) {
      final currentSchedule = _schedules[i];
      final originalSchedule = widget.classData.schedule[i];
      
      if (currentSchedule.dayOfWeek != originalSchedule.dayOfWeek ||
          currentSchedule.date != originalSchedule.date ||
          currentSchedule.startTime != originalSchedule.startTime ||
          currentSchedule.endTime != originalSchedule.endTime) {
        return true;
      }
    }
    
    return false;
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one date is selected
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text('Please select at least one date for the class schedule', style: TextStyle(color: Colors.black)),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate that all schedules have valid times
    for (int i = 0; i < _schedules.length; i++) {
      final schedule = _schedules[i];
      
      // Validate that the date is not in the past (matching backend validation)
      if (schedule.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: Class date cannot be in the past', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.gold,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Validate that end time is after start time
      if (schedule.endTime.isBefore(schedule.startTime) || schedule.endTime.isAtSameMomentAs(schedule.startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: End time must be after start time', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.gold,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Validate that start and end times are on the same date as the schedule date
      final scheduleDate = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      final startDate = DateTime(schedule.startTime.year, schedule.startTime.month, schedule.startTime.day);
      final endDate = DateTime(schedule.endTime.year, schedule.endTime.month, schedule.endTime.day);
      if (!startDate.isAtSameMomentAs(scheduleDate) || !endDate.isAtSameMomentAs(scheduleDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: Start and end times must be on the same date as the schedule date', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.gold,
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
      // Check if images have changed
      final imagesChanged = _existingImages.length != widget.classData.images.length ||
          !_existingImages.every((image) => widget.classData.images.contains(image)) ||
          _selectedImages.isNotEmpty;

      // Only include fields that have changed
      final request = UpdateStandaloneClassRequest(
        name: _nameController.text.trim() != widget.classData.name ? _nameController.text.trim() : null,
        description: _descriptionController.text.trim() != widget.classData.description ? _descriptionController.text.trim() : null,
        instructor: _instructorController.text.trim() != widget.classData.instructor ? _instructorController.text.trim() : null,
        capacity: int.parse(_capacityController.text) != widget.classData.capacity ? int.parse(_capacityController.text) : null,
        duration: int.parse(_durationController.text) != widget.classData.duration ? int.parse(_durationController.text) : null,
        schedule: _schedulesChanged() ? _schedules : null,
        images: imagesChanged ? _existingImages : null,
        isActive: _isActive != widget.classData.isActive ? _isActive : null,
      );

      // Check if any fields have been changed
      final hasChanges = request.name != null ||
          request.description != null ||
          request.instructor != null ||
          request.capacity != null ||
          request.duration != null ||
          request.schedule != null ||
          request.images != null ||
          request.isActive != null;

      if (!hasChanges) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No changes detected. Please modify at least one field before updating.'),
              backgroundColor: AppColors.gold,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('=== Form Submission Debug ===');
      print('Fields being updated:');
      print('Name: ${request.name != null ? "Updated to: ${request.name}" : "No change"}');
      print('Description: ${request.description != null ? "Updated to: ${request.description}" : "No change"}');
      print('Instructor: ${request.instructor != null ? "Updated to: ${request.instructor}" : "No change"}');
      print('Capacity: ${request.capacity != null ? "Updated to: ${request.capacity}" : "No change"}');
      print('Duration: ${request.duration != null ? "Updated to: ${request.duration}" : "No change"}');
      print('Schedule: ${request.schedule != null ? "Updated (${request.schedule!.length} schedules)" : "No change"}');
      print('IsActive: ${request.isActive != null ? "Updated to: ${request.isActive}" : "No change"}');
      
      if (request.schedule != null) {
        print('Schedule details:');
        for (int i = 0; i < request.schedule!.length; i++) {
          final schedule = request.schedule![i];
          final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
          final dayName = days[schedule.dayOfWeek];
          print('Schedule $i: Day $dayName (${schedule.dayOfWeek}), Date: ${schedule.date.toIso8601String()}, Start: ${schedule.startTime.toIso8601String()}, End: ${schedule.endTime.toIso8601String()}');
          print('Schedule $i JSON: ${schedule.toJson()}');
        }
      }
      
      print('Full request JSON: ${request.toJson()}');
      print('Selected images: ${_selectedImages.length}');

      // Call API to update class with image files if provided
      final result = await ApiService.updateStandaloneClass(
        widget.classData.id,
        request,
        widget.accessToken,
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Class updated successfully'),
              backgroundColor: AppColors.gold,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update class', style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.gold,
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
            backgroundColor: AppColors.gold,
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
            colors: [Colors.white, Colors.white70],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/E8Logos/admin_dashboard_background.jpeg'),
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
                          'Edit Standalone Class',
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
                            const SizedBox(height: 16),

                            // Duration Field
                            TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter duration';
                                }
                                final duration = int.tryParse(value);
                                if (duration == null || duration <= 0) {
                                  return 'Duration must be greater than 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Active Status
                            Row(
                              children: [
                                const Text(
                                  'Active Status:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Switch(
                                  value: _isActive,
                                  onChanged: (value) {
                                    setState(() {
                                      _isActive = value;
                                    });
                                  },
                                  activeColor: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: _isActive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Images Section
                            const Text(
                              'Class Images',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            const Text(
                              'Manage existing images and add new ones',
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
                                    label: const Text('Add Images'),
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

                            // Existing Images Display
                            if (_existingImages.isNotEmpty) ...[
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
                                      'Existing Images (${_existingImages.length})',
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
                                      itemCount: _existingImages.length,
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
                                                child: Image.network(
                                                  _existingImages[index],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeExistingImage(index),
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

                            // New Images Display
                            if (_selectedImages.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New Images (${_selectedImages.length})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
                                                border: Border.all(color: Colors.white),
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
                                                onTap: () => _removeNewImage(index),
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

                            // Selected Dates Summary with Editable Times
                            if (_selectedDates.isNotEmpty) ...[
                              Container(
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
                                        Text(
                                          'Selected Dates & Times (${_selectedDates.length})',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...(() {
                                      final sortedDates = _selectedDates.toList();
                                      sortedDates.sort();
                                      return sortedDates;
                                    })().map((date) {
                                      final startTime = _getStartTimeForDate(date);
                                      final endTime = _getEndTimeForDate(date);
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
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
                                              children: [
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final selectedDate = await showDatePicker(
                                                        context: context,
                                                        initialDate: date,
                                                        firstDate: DateTime.now(),
                                                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                                      );
                                                      if (selectedDate != null) {
                                                        _changeDate(date, selectedDate);
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.calendar_today,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            _formatDateWithDay(date),
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.edit,
                                                          size: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.close, size: 18),
                                                  color: Colors.red,
                                                  onPressed: () => _toggleDateSelection(date),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Tap to edit time',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final time = await showTimePicker(
                                                        context: context,
                                                        initialTime: startTime,
                                                      );
                                                      if (time != null) {
                                                        _updateScheduleTime(date, time, null);
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(color: Colors.white, width: 1.5),
                                                        borderRadius: BorderRadius.circular(8),
                                                        color: Colors.white,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(Icons.access_time, size: 18, color: Colors.white),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          const Icon(Icons.edit, size: 14, color: Colors.grey),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'to',
                                                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final time = await showTimePicker(
                                                        context: context,
                                                        initialTime: endTime,
                                                      );
                                                      if (time != null) {
                                                        _updateScheduleTime(date, null, time);
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(color: Colors.white, width: 1.5),
                                                        borderRadius: BorderRadius.circular(8),
                                                        color: Colors.white,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(Icons.access_time, size: 18, color: Colors.white),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          const Icon(Icons.edit, size: 14, color: Colors.grey),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                child: _isLoading
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
                                          const Text(
                                            'Updating Class...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Update Class',
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
          children: days.map((day) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          )).toList(),
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
              final isSelected = isCurrentMonth && 
                _selectedDates.contains(DateTime(month.year, month.month, dayNumber));
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
}