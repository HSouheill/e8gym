import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/standalone_class_models.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/foundation.dart';

class _TimeSlotEntry {
  TimeOfDay startTime;
  TimeOfDay endTime;
  _TimeSlotEntry({required this.startTime, required this.endTime});
}

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
  bool _isActive = true;

  // Multi-date selection with multiple time slots per date
  Set<DateTime> _selectedDates = {};
  Map<DateTime, List<_TimeSlotEntry>> _dateTimeSlots = {};
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
    _existingImages = List.from(widget.classData.images);

    // Group schedules by date to support multiple time slots per date
    _selectedDates = {};
    _dateTimeSlots = {};
    for (final schedule in widget.classData.schedule) {
      final dateKey = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      if (!_selectedDates.contains(dateKey)) {
        _selectedDates.add(dateKey);
        _dateTimeSlots[dateKey] = [];
      }
      _dateTimeSlots[dateKey]!.add(_TimeSlotEntry(
        startTime: TimeOfDay.fromDateTime(schedule.startTime),
        endTime: TimeOfDay.fromDateTime(schedule.endTime),
      ));
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
    final dateKey = DateTime(date.year, date.month, date.day);
    setState(() {
      if (_selectedDates.any((d) => d.year == dateKey.year && d.month == dateKey.month && d.day == dateKey.day)) {
        _selectedDates.removeWhere((d) => d.year == dateKey.year && d.month == dateKey.month && d.day == dateKey.day);
        _dateTimeSlots.remove(dateKey);
      } else {
        _selectedDates.add(dateKey);
        _dateTimeSlots[dateKey] = [
          _TimeSlotEntry(startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 10, minute: 0)),
        ];
      }
    });
  }

  List<ClassSchedule> _getScheduleList() {
    final schedules = <ClassSchedule>[];
    for (final date in _dateTimeSlots.keys) {
      final slots = _dateTimeSlots[date] ?? [];
      for (final slot in slots) {
        final backendDayOfWeek = date.weekday == 7 ? 0 : date.weekday;
        schedules.add(ClassSchedule(
          dayOfWeek: backendDayOfWeek,
          date: date,
          startTime: DateTime.utc(date.year, date.month, date.day, slot.startTime.hour, slot.startTime.minute),
          endTime: DateTime.utc(date.year, date.month, date.day, slot.endTime.hour, slot.endTime.minute),
        ));
      }
    }
    return schedules;
  }

  void _addTimeSlotForDate(DateTime date) {
    setState(() {
      _dateTimeSlots[date]!.add(
        _TimeSlotEntry(startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 10, minute: 0)),
      );
    });
  }

  void _removeTimeSlotForDate(DateTime date, int slotIndex) {
    setState(() {
      _dateTimeSlots[date]!.removeAt(slotIndex);
      if (_dateTimeSlots[date]!.isEmpty) {
        _dateTimeSlots.remove(date);
        _selectedDates.removeWhere((d) => d.year == date.year && d.month == date.month && d.day == date.day);
      }
    });
  }

  void _updateTimeSlotForDate(DateTime date, int slotIndex, TimeOfDay? start, TimeOfDay? end) {
    setState(() {
      final slot = _dateTimeSlots[date]![slotIndex];
      _dateTimeSlots[date]![slotIndex] = _TimeSlotEntry(
        startTime: start ?? slot.startTime,
        endTime: end ?? slot.endTime,
      );
    });
  }

  void _changeDateForSchedule(DateTime oldDate, DateTime newDate) {
    final normalizedOld = DateTime(oldDate.year, oldDate.month, oldDate.day);
    final normalizedNew = DateTime(newDate.year, newDate.month, newDate.day);

    if (_selectedDates.any((d) => d.year == normalizedNew.year && d.month == normalizedNew.month && d.day == normalizedNew.day)) {
      _showSnackBar('This date is already selected');
      return;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (normalizedNew.isBefore(todayDate)) {
      _showSnackBar('Cannot select a date in the past');
      return;
    }

    setState(() {
      final existingSlots = _dateTimeSlots[normalizedOld] ?? [
        _TimeSlotEntry(startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 10, minute: 0)),
      ];
      _selectedDates.removeWhere((d) => d.year == normalizedOld.year && d.month == normalizedOld.month && d.day == normalizedOld.day);
      _dateTimeSlots.remove(normalizedOld);
      _selectedDates.add(normalizedNew);
      _dateTimeSlots[normalizedNew] = existingSlots;
    });
  }

  void _changeDayOfWeek(DateTime date, int targetDayIndex) {
    // targetDayIndex: 0=Sun, 1=Mon, ..., 6=Sat (matching date.weekday % 7)
    final currentDayIndex = date.weekday % 7;
    if (targetDayIndex == currentDayIndex) return;

    int diff = targetDayIndex - currentDayIndex;
    DateTime newDate = DateTime(date.year, date.month, date.day + diff);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (newDate.isBefore(todayDate)) {
      newDate = DateTime(newDate.year, newDate.month, newDate.day + 7);
    }

    _changeDateForSchedule(date, newDate);
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
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: AppColors.snackbarBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }


  bool _schedulesChanged() {
    final currentSchedules = _getScheduleList();
    if (currentSchedules.length != widget.classData.schedule.length) return true;
    final sortedCurrent = List<ClassSchedule>.from(currentSchedules)
      ..sort((a, b) {
        final dc = a.date.compareTo(b.date);
        return dc != 0 ? dc : a.startTime.compareTo(b.startTime);
      });
    final sortedOriginal = List<ClassSchedule>.from(widget.classData.schedule)
      ..sort((a, b) {
        final dc = a.date.compareTo(b.date);
        return dc != 0 ? dc : a.startTime.compareTo(b.startTime);
      });
    for (int i = 0; i < sortedCurrent.length; i++) {
      if (sortedCurrent[i].dayOfWeek != sortedOriginal[i].dayOfWeek ||
          sortedCurrent[i].date != sortedOriginal[i].date ||
          sortedCurrent[i].startTime != sortedOriginal[i].startTime ||
          sortedCurrent[i].endTime != sortedOriginal[i].endTime) {
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
          backgroundColor: AppColors.snackbarBackground,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate that all schedules have valid times
    final schedulesToSubmit = _getScheduleList();
    for (int i = 0; i < schedulesToSubmit.length; i++) {
      final schedule = schedulesToSubmit[i];
      
      // Validate that the date is not in the past (matching backend validation)
      if (schedule.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${i + 1}: Class date cannot be in the past', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
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
            backgroundColor: AppColors.snackbarBackground,
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
            backgroundColor: AppColors.snackbarBackground,
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
        schedule: _schedulesChanged() ? _getScheduleList() : null,
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
              content: Text('No changes detected. Please modify at least one field before updating.', style: TextStyle(color: Colors.black)),
              backgroundColor: AppColors.snackbarBackground,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (kDebugMode) print('=== Form Submission Debug ===');
      if (kDebugMode) print('Fields being updated:');
      if (kDebugMode) print('Name: ${request.name != null ? "Updated to: ${request.name}" : "No change"}');
      if (kDebugMode) print('Description: ${request.description != null ? "Updated to: ${request.description}" : "No change"}');
      if (kDebugMode) print('Instructor: ${request.instructor != null ? "Updated to: ${request.instructor}" : "No change"}');
      if (kDebugMode) print('Capacity: ${request.capacity != null ? "Updated to: ${request.capacity}" : "No change"}');
      if (kDebugMode) print('Duration: ${request.duration != null ? "Updated to: ${request.duration}" : "No change"}');
      if (kDebugMode) print('Schedule: ${request.schedule != null ? "Updated (${request.schedule!.length} schedules)" : "No change"}');
      if (kDebugMode) print('IsActive: ${request.isActive != null ? "Updated to: ${request.isActive}" : "No change"}');
      
      if (request.schedule != null) {
        if (kDebugMode) print('Schedule details:');
        for (int i = 0; i < request.schedule!.length; i++) {
          final schedule = request.schedule![i];
          final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
          final dayName = days[schedule.dayOfWeek];
          if (kDebugMode) print('Schedule $i: Day $dayName (${schedule.dayOfWeek}), Date: ${schedule.date.toIso8601String()}, Start: ${schedule.startTime.toIso8601String()}, End: ${schedule.endTime.toIso8601String()}');
          if (kDebugMode) print('Schedule $i JSON: ${schedule.toJson()}');
        }
      }
      
      if (kDebugMode) print('Full request JSON: ${request.toJson()}');
      if (kDebugMode) print('Selected images: ${_selectedImages.length}');

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
              content: Text(result['message'] ?? 'Class updated successfully', style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.snackbarBackground,
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
              backgroundColor: AppColors.snackbarBackground,
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
            backgroundColor: AppColors.snackbarBackground,
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
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Colors.black),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Selected Dates & Times (${_selectedDates.length})',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...(() {
                                      final sortedDates = _selectedDates.toList()..sort();
                                      return sortedDates;
                                    })().map((date) {
                                      final slots = _dateTimeSlots[date] ?? [];
                                      final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                                      final currentDayIndex = date.weekday % 7;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Date row with edit and remove
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
                                                        _changeDateForSchedule(date, selectedDate);
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.calendar_today, size: 16, color: Colors.black),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            _formatDateWithDay(date),
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                        const Icon(Icons.edit, size: 14, color: Colors.grey),
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
                                            // Day-of-week selector
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: List.generate(7, (i) {
                                                final isSelected = i == currentDayIndex;
                                                return GestureDetector(
                                                  onTap: () => _changeDayOfWeek(date, i),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isSelected ? Colors.black : Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: isSelected ? Colors.black : Colors.grey[300]!,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      dayLabels[i],
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: isSelected ? Colors.white : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 12),
                                            // Time slots
                                            ...List.generate(slots.length, (slotIndex) {
                                              final slot = slots[slotIndex];
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: Row(
                                                  children: [
                                                    // Slot number
                                                    Container(
                                                      width: 22,
                                                      height: 22,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${slotIndex + 1}',
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Start time
                                                    Expanded(
                                                      child: InkWell(
                                                        onTap: () async {
                                                          final time = await showTimePicker(
                                                            context: context,
                                                            initialTime: slot.startTime,
                                                          );
                                                          if (time != null) {
                                                            _updateTimeSlotForDate(date, slotIndex, time, null);
                                                          }
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                                          decoration: BoxDecoration(
                                                            border: Border.all(color: Colors.grey[300]!),
                                                            borderRadius: BorderRadius.circular(8),
                                                            color: Colors.grey[50],
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Icon(Icons.access_time, size: 14, color: Colors.black54),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}',
                                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                                      child: Text('–', style: TextStyle(color: Colors.grey)),
                                                    ),
                                                    // End time
                                                    Expanded(
                                                      child: InkWell(
                                                        onTap: () async {
                                                          final time = await showTimePicker(
                                                            context: context,
                                                            initialTime: slot.endTime,
                                                          );
                                                          if (time != null) {
                                                            _updateTimeSlotForDate(date, slotIndex, null, time);
                                                          }
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                                          decoration: BoxDecoration(
                                                            border: Border.all(color: Colors.grey[300]!),
                                                            borderRadius: BorderRadius.circular(8),
                                                            color: Colors.grey[50],
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Icon(Icons.access_time, size: 14, color: Colors.black54),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '${slot.endTime.hour.toString().padLeft(2, '0')}:${slot.endTime.minute.toString().padLeft(2, '0')}',
                                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    // Remove slot button (only if more than 1)
                                                    if (slots.length > 1)
                                                      GestureDetector(
                                                        onTap: () => _removeTimeSlotForDate(date, slotIndex),
                                                        child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                                      )
                                                    else
                                                      const SizedBox(width: 20),
                                                  ],
                                                ),
                                              );
                                            }),
                                            // Add time slot button
                                            TextButton.icon(
                                              onPressed: () => _addTimeSlotForDate(date),
                                              icon: const Icon(Icons.add, size: 16),
                                              label: const Text('Add Time Slot', style: TextStyle(fontSize: 13)),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.black87,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
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