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
  
  // Multi-date selection
  Set<DateTime> _selectedDates = {};
  TimeOfDay _defaultStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _defaultEndTime = const TimeOfDay(hour: 10, minute: 0);
  
  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;
  

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
    _schedules.clear();
    for (final date in _selectedDates) {
      final dartWeekday = date.weekday;
      final backendDayOfWeek = dartWeekday == 7 ? 0 : dartWeekday;
      
      _schedules.add(ClassSchedule(
        dayOfWeek: backendDayOfWeek,
        date: date,
        startTime: DateTime.utc(date.year, date.month, date.day, _defaultStartTime.hour, _defaultStartTime.minute),
        endTime: DateTime.utc(date.year, date.month, date.day, _defaultEndTime.hour, _defaultEndTime.minute),
      ));
    }
  }

  void _updateDefaultTimes() {
    setState(() {
      _generateSchedulesFromSelectedDates();
    });
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
        backgroundColor: const Color(0xFFF8BB0C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one date is selected
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one date for the class schedule'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
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
            content: Text('Schedule ${i + 1}: Class date cannot be in the past'),
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
            content: Text('Schedule ${i + 1}: End time must be after start time'),
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
            content: Text('Schedule ${i + 1}: Start and end times must be on the same date as the schedule date'),
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

      // Upload images first if any are selected
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });

        // For now, we'll create the class first and then upload images
        // In a real implementation, you might want to upload images first
        // and get URLs before creating the class
      }

      final request = CreateStandaloneClassRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        instructor: _instructorController.text.trim(),
        capacity: int.parse(_capacityController.text),
        schedule: _schedules,
        duration: duration,
        images: imageUrls.isNotEmpty ? imageUrls : null,
      );

      print('=== Form Submission Debug ===');
      print('Regular Schedules count: ${_schedules.length}');
      for (int i = 0; i < _schedules.length; i++) {
        final schedule = _schedules[i];
        print('Schedule $i: Day ${schedule.dayOfWeek}, Start: ${schedule.startTime}, End: ${schedule.endTime}');
      }
      print('Duration: $duration minutes');

      final result = await ApiService.createStandaloneClass(
        request,
        widget.accessToken,
      );

      if (result['success']) {
        // Upload images if any are selected
        if (_selectedImages.isNotEmpty) {
          final classId = result['data']['id'];
          for (final imageFile in _selectedImages) {
            try {
              final uploadResult = await ApiService.uploadStandaloneClassImage(
                imageFile,
                classId,
                widget.accessToken,
              );
              if (!uploadResult['success']) {
                print('Failed to upload image: ${uploadResult['message']}');
              }
            } catch (e) {
              print('Error uploading image: $e');
            }
          }
        }

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
                                      backgroundColor: const Color(0xFFF8BB0C),
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

                            // Default Time Settings
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
                                  const Text(
                                    'Default Times (applied to all selected dates)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
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
                                                  initialTime: _defaultStartTime,
                                                );
                                                if (time != null) {
                                                  setState(() {
                                                    _defaultStartTime = time;
                                                    _updateDefaultTimes();
                                                  });
                                                }
                                              },
                                              icon: const Icon(Icons.access_time),
                                            ),
                                          ),
                                          initialValue: '${_defaultStartTime.hour.toString().padLeft(2, '0')}:${_defaultStartTime.minute.toString().padLeft(2, '0')}',
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
                                                  initialTime: _defaultEndTime,
                                                );
                                                if (time != null) {
                                                  setState(() {
                                                    _defaultEndTime = time;
                                                    _updateDefaultTimes();
                                                  });
                                                }
                                              },
                                              icon: const Icon(Icons.access_time),
                                            ),
                                          ),
                                          initialValue: '${_defaultEndTime.hour.toString().padLeft(2, '0')}:${_defaultEndTime.minute.toString().padLeft(2, '0')}',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

                            // Selected Dates Summary
                            if (_selectedDates.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8BB0C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFF8BB0C)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Color(0xFFF8BB0C)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Selected Dates (${_selectedDates.length})',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFF8BB0C),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: _selectedDates.map((date) {
                                        return Chip(
                                          label: Text(_formatDateWithDay(date)),
                                          backgroundColor: const Color(0xFFF8BB0C),
                                          labelStyle: const TextStyle(color: Colors.black),
                                          deleteIcon: const Icon(Icons.close, color: Colors.black, size: 18),
                                          onDeleted: () => _toggleDateSelection(date),
                                        );
                                      }).toList(),
                                    ),
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
                                  backgroundColor: const Color(0xFFF8BB0C),
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
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    return StatefulBuilder(
      builder: (context, setState) {
        DateTime displayMonth = currentMonth;
        
        return Column(
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      displayMonth = DateTime(displayMonth.year, displayMonth.month - 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_getMonthName(displayMonth.month)} ${displayMonth.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      displayMonth = DateTime(displayMonth.year, displayMonth.month + 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Calendar grid
            Expanded(
              child: _buildMultiDateCalendarGrid(displayMonth),
            ),
          ],
        );
      },
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
                        ? const Color(0xFFF8BB0C) 
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