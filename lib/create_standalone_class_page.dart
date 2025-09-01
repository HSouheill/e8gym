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
  MonthlySchedule? _monthlySchedule;
  bool _useMonthlySchedule = false;
  
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
    final schedule = _schedules[index];
    final dayName = _daysOfWeek[schedule.dayOfWeek];
    
    setState(() {
      _schedules.removeAt(index);
    });
    
    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Schedule removed for $dayName'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _schedules.add(schedule);
            });
          },
        ),
      ),
    );
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

  void _toggleScheduleMode() {
    setState(() {
      _useMonthlySchedule = !_useMonthlySchedule;
      if (_useMonthlySchedule) {
        _schedules.clear();
      } else {
        _monthlySchedule = null;
      }
    });
  }

  void _openMonthlySchedulePicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonthlySchedulePickerPage(
          initialSchedule: _monthlySchedule,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _monthlySchedule = result;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one schedule is provided
    if (!_useMonthlySchedule && _schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one schedule'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_useMonthlySchedule && _monthlySchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a monthly schedule'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate that all schedules have valid times
    if (!_useMonthlySchedule) {
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
        monthlySchedule: _monthlySchedule,
      );

      print('=== Form Submission Debug ===');
      if (_useMonthlySchedule && _monthlySchedule != null) {
        print('Monthly Schedule: ${_monthlySchedule!.month}/${_monthlySchedule!.year}');
        print('Schedules count: ${_monthlySchedule!.schedules.length}');
        for (int i = 0; i < _monthlySchedule!.schedules.length; i++) {
          final schedule = _monthlySchedule!.schedules[i];
          print('Schedule $i: Day ${schedule.dayOfWeek}, Start: ${schedule.startTime}, End: ${schedule.endTime}');
        }
      } else {
        print('Regular Schedules count: ${_schedules.length}');
        for (int i = 0; i < _schedules.length; i++) {
          final schedule = _schedules[i];
          print('Schedule $i: Day ${schedule.dayOfWeek}, Start: ${schedule.startTime}, End: ${schedule.endTime}');
        }
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

                            // Schedule Mode Toggle
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Schedule Type:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('Weekly'),
                                        selected: !_useMonthlySchedule,
                                        onSelected: (selected) {
                                          if (selected) _toggleScheduleMode();
                                        },
                                        selectedColor: const Color(0xFFF8BB0C),
                                        labelStyle: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('Monthly'),
                                        selected: _useMonthlySchedule,
                                        onSelected: (selected) {
                                          if (selected) _toggleScheduleMode();
                                        },
                                        selectedColor: const Color(0xFFF8BB0C),
                                        labelStyle: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Schedule Section
                            const Text(
                              'Schedule *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (_useMonthlySchedule) ...[
                              const Text(
                                'Select schedules for the entire month',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Monthly Schedule Picker Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openMonthlySchedulePicker,
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text(_monthlySchedule != null 
                                      ? 'Edit Monthly Schedule (${_monthlySchedule!.schedules.length} schedules)'
                                      : 'Select Monthly Schedule'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF8BB0C),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ] else ...[
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
                            ],
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

class MonthlySchedulePickerPage extends StatefulWidget {
  final MonthlySchedule? initialSchedule;
  
  const MonthlySchedulePickerPage({
    super.key,
    this.initialSchedule,
  });

  @override
  State<MonthlySchedulePickerPage> createState() => _MonthlySchedulePickerPageState();
}

class _MonthlySchedulePickerPageState extends State<MonthlySchedulePickerPage> {
  late DateTime _selectedMonth;
  late List<ClassSchedule> _schedules;
  final List<String> _daysOfWeek = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ];
  
  // Add help text and instructions
  bool _showHelp = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialSchedule != null 
        ? DateTime(widget.initialSchedule!.year, widget.initialSchedule!.month)
        : DateTime.now();
    _schedules = widget.initialSchedule?.schedules ?? [];
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    List<DateTime> days = [];
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(_selectedMonth.year, _selectedMonth.month, day));
    }
    return days;
  }

  void _addScheduleForDay(DateTime day) {
    final dayOfWeek = day.weekday % 7; // Convert to 0-6 format (Sunday=0)
    
    // Check if schedule already exists for this day
    final existingIndex = _schedules.indexWhere((s) => s.dayOfWeek == dayOfWeek);
    
    if (existingIndex != -1) {
      // Show options dialog for existing schedule
      _showScheduleOptionsDialog(existingIndex, day);
    } else {
      // Add new schedule
      _showTimePickerForNewSchedule(dayOfWeek, day);
    }
  }

  void _showScheduleOptionsDialog(int index, DateTime day) {
    final schedule = _schedules[index];
    final dayName = _daysOfWeek[schedule.dayOfWeek];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule for $dayName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current schedule:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')} - ${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showTimePickerForSchedule(index);
            },
            child: const Text('Edit Time'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeSchedule(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimePickerForNewSchedule(int dayOfWeek, DateTime day) async {
    final dayName = _daysOfWeek[dayOfWeek];
    
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Schedule for $dayName'),
        content: const Text('Would you like to add a schedule for this day of the week?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8BB0C),
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Schedule'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF8BB0C),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (startTime != null) {
      final endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFF8BB0C),
                onPrimary: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (endTime != null) {
        // Validate that end time is after start time
        if (endTime.hour < startTime.hour || 
            (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        setState(() {
          _schedules.add(ClassSchedule(
            dayOfWeek: dayOfWeek,
            startTime: DateTime(day.year, day.month, day.day, startTime.hour, startTime.minute),
            endTime: DateTime(day.year, day.month, day.day, endTime.hour, endTime.minute),
          ));
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule added for $dayName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showTimePickerForSchedule(int index) async {
    final schedule = _schedules[index];
    final dayName = _daysOfWeek[schedule.dayOfWeek];
    
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(schedule.startTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF8BB0C),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (startTime != null) {
      final endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(schedule.endTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFF8BB0C),
                onPrimary: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (endTime != null) {
        // Validate that end time is after start time
        if (endTime.hour < startTime.hour || 
            (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        setState(() {
          _schedules[index] = ClassSchedule(
            dayOfWeek: schedule.dayOfWeek,
            startTime: DateTime(schedule.startTime.year, schedule.startTime.month, schedule.startTime.day, startTime.hour, startTime.minute),
            endTime: DateTime(schedule.endTime.year, schedule.endTime.month, schedule.endTime.day, endTime.hour, endTime.minute),
          );
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule updated for $dayName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  bool _hasScheduleForDay(DateTime day) {
    final dayOfWeek = day.weekday % 7; // Convert to 0-6 format (Sunday=0)
    return _schedules.any((s) => s.dayOfWeek == dayOfWeek);
  }

  ClassSchedule? _getScheduleForDay(DateTime day) {
    final dayOfWeek = day.weekday % 7; // Convert to 0-6 format (Sunday=0)
    try {
      return _schedules.firstWhere((s) => s.dayOfWeek == dayOfWeek);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final monthName = _selectedMonth.month == DateTime.now().month && _selectedMonth.year == DateTime.now().year
        ? 'This Month'
        : '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}';
    
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
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Monthly Schedule',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap any day to add or edit schedule',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showHelp = !_showHelp;
                          });
                        },
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
                            Icons.help_outline,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Month Navigation
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.chevron_left),
                        color: Colors.black,
                      ),
                      Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Help Section
                if (_showHelp) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF8BB0C)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb, color: Color(0xFFF8BB0C)),
                            const SizedBox(width: 8),
                            const Text(
                              'How to use:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildHelpItem('📅 Tap any day to add a schedule for that day of the week'),
                        _buildHelpItem('🕒 Choose start and end times for your class'),
                        _buildHelpItem('✏️ Tap a scheduled day to edit or remove the schedule'),
                        _buildHelpItem('📱 Use the arrows to navigate between months'),
                        _buildHelpItem('💾 Save when you\'re done setting up all schedules'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Calendar Grid
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Day headers
                        Row(
                          children: _daysOfWeek.map((day) => Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                        
                        const Divider(),
                        
                        // Calendar days
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: days.length,
                            itemBuilder: (context, index) {
                              final day = days[index];
                              final hasSchedule = _hasScheduleForDay(day);
                              final schedule = _getScheduleForDay(day);
                              final isToday = day.day == DateTime.now().day && 
                                            day.month == DateTime.now().month && 
                                            day.year == DateTime.now().year;
                              
                              return GestureDetector(
                                onTap: () => _addScheduleForDay(day),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: hasSchedule 
                                        ? const Color(0xFFF8BB0C).withOpacity(0.4)
                                        : isToday
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: hasSchedule 
                                          ? const Color(0xFFF8BB0C)
                                          : isToday
                                              ? Colors.blue
                                              : Colors.grey.withOpacity(0.2),
                                      width: hasSchedule || isToday ? 2 : 1,
                                    ),
                                    boxShadow: hasSchedule ? [
                                      BoxShadow(
                                        color: const Color(0xFFF8BB0C).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            day.day.toString(),
                                            style: TextStyle(
                                              fontWeight: hasSchedule ? FontWeight.bold : FontWeight.normal,
                                              color: hasSchedule ? Colors.black : Colors.grey[700],
                                              fontSize: hasSchedule ? 16 : 14,
                                            ),
                                          ),
                                          if (hasSchedule) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.fitness_center,
                                              size: 12,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (hasSchedule && schedule != null) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Schedule Summary
                if (_schedules.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF8BB0C)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule, color: Color(0xFFF8BB0C)),
                            const SizedBox(width: 8),
                            Text(
                              'Scheduled Days (${_schedules.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _schedules.map((schedule) {
                            final dayName = _daysOfWeek[schedule.dayOfWeek];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8BB0C).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF8BB0C)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    dayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      if (_schedules.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'No schedules added yet. Tap any day to add a schedule.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Cancel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _schedules.isEmpty ? null : () {
                                final monthlySchedule = MonthlySchedule(
                                  year: _selectedMonth.year,
                                  month: _selectedMonth.month,
                                  schedules: _schedules,
                                );
                                Navigator.pop(context, monthlySchedule);
                              },
                              icon: const Icon(Icons.save),
                              label: Text('Save (${_schedules.length})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF8BB0C),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
