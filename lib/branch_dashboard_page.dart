import 'package:flutter/material.dart';
import 'dart:convert';
import 'services/api_service.dart';
import 'models/branch_class_models.dart';
import 'models/standalone_class_models.dart';
import 'branch_users_page.dart';

class BranchDashboardPage extends StatefulWidget {
  final Map<String, dynamic> branchData;
  final String accessToken;
  final bool canEdit;
  
  const BranchDashboardPage({
    super.key,
    required this.branchData,
    required this.accessToken,
    this.canEdit = true, // Default to true for backward compatibility
  });

  @override
  State<BranchDashboardPage> createState() => _BranchDashboardPageState();
}

class _BranchDashboardPageState extends State<BranchDashboardPage> {
  bool _isLoading = false;
  bool _isLoadingClasses = false;
  late final String accessToken;
  List<BranchClassResponse> _classes = [];
  String? _errorMessage;
  int _currentTab = 0; // 0 = Dashboard, 1 = Classes, 2 = Users

  @override
  void initState() {
    super.initState();
    accessToken = widget.accessToken;
    
    // Debug logging
    print('BranchDashboardPage initialized');
    print('Branch data keys: ${widget.branchData.keys}');
    if (widget.branchData['branch'] != null) {
      print('Branch data keys: ${(widget.branchData['branch'] as Map).keys}');
    }
    
    // Load classes on initialization
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoadingClasses = true;
      _errorMessage = null;
    });

    try {
      print('=== Loading Branch Classes ===');
      final result = await ApiService.getBranchClasses(accessToken);
      print('Branch classes API response: $result');
      
      if (result['success']) {
        final data = result['data'];
        print('Branch classes data: $data');
        
        // Check if data contains classes field
        if (data != null) {
          print('Data keys: ${data.keys}');
          print('Classes field exists: ${data.containsKey('classes')}');
          print('Classes field value: ${data['classes']}');
          
          if (data['classes'] != null) {
            final classListResponse = BranchClassListResponse.fromJson(data);
            setState(() {
              _classes = classListResponse.classes;
              _isLoadingClasses = false;
            });
            print('Successfully loaded ${_classes.length} classes');
          } else {
            print('Classes field is null, setting empty list');
            setState(() {
              _classes = [];
              _isLoadingClasses = false;
            });
          }
        } else {
          print('Data is null');
          setState(() {
            _classes = [];
            _isLoadingClasses = false;
          });
        }
      } else {
        print('API returned error: ${result['message']}');
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load classes';
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      print('Error loading classes: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoadingClasses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have valid branch data
    final branchData = widget.branchData['branch'] ?? {};
    
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 30),
              child: Column(
                children: [
                  // Header with back button and logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      
                      GestureDetector(
                        onTap: () async {
                          await _handleLogout();
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
                            Icons.logout,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Welcome message
                  Text(
                    'Welcome, ${branchData['admin_name'] ?? 'Admin'}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    branchData['branch_name'] ?? 'Branch',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (!widget.canEdit) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'View Only Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  // Tab buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'Dashboard',
                          isSelected: _currentTab == 0,
                          onTap: () => setState(() => _currentTab = 0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTabButton(
                          title: 'Classes (${_classes.length})',
                          isSelected: _currentTab == 1,
                          onTap: () => setState(() => _currentTab = 1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTabButton(
                          title: 'Users',
                          isSelected: _currentTab == 2,
                          onTap: () => setState(() => _currentTab = 2),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Content based on selected tab
                  Expanded(
                    child: _currentTab == 0 
                        ? _buildDashboardContent(branchData) 
                        : _currentTab == 1 
                            ? _buildClassesContent()
                            : _buildUsersContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF926E07) : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDashboardContent(Map<String, dynamic> branchData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Branch info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Branch Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Admin Name', branchData['admin_name'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Email', branchData['email'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Phone', '${branchData['country_code'] ?? ''} ${branchData['phone_number'] ?? 'N/A'}'),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.people,
                  title: 'Team Members',
                  subtitle: '${(branchData['team_members'] as List?)?.length ?? 0} members',
                  onTap: () {
                    _showTeamMembersDialog(branchData);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.fitness_center,
                  title: 'Classes',
                  subtitle: '${_classes.length} classes',
                  onTap: () {
                    setState(() => _currentTab = 1);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.person,
                  title: 'Users',
                  subtitle: 'View branch users',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BranchUsersPage(
                          accessToken: accessToken,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(), // Empty space for future action
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
        
          
        
        ],
      ),
    );
  }

  Widget _buildUsersContent() {
    return Column(
      children: [
        // Users header
        Row(
          children: [
            const Expanded(
              child: Text(
                'Branch Users',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BranchUsersPage(
                      accessToken: accessToken,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Users content placeholder
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'User Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the users icon to view and manage\nbranch users and their bookings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BranchUsersPage(
                          accessToken: accessToken,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF926E07),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Users'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassesContent() {
    return Column(
      children: [
        // Classes header with refresh button
        Row(
          children: [
            const Expanded(
              child: Text(
                'Branch Classes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: _loadClasses,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Classes list
        Expanded(
          child: _isLoadingClasses
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadClasses,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF926E07),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _classes.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: Colors.white,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No classes found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Classes will appear here once they are created',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _classes.length,
                          itemBuilder: (context, index) {
                            return _buildClassCard(_classes[index]);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildClassCard(BranchClassResponse classData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    classData.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: classData.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    classData.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              classData.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow('Instructor', classData.instructor),
            _buildInfoRow('Capacity', '${classData.capacity} students'),
            _buildInfoRow('Duration', '${classData.duration} minutes'),
            
            const SizedBox(height: 16),
            
            if (classData.schedule.isNotEmpty) ...[
              const Text(
                'Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._getSortedSchedules(classData.schedule).map((schedule) => _buildScheduleItem(schedule)),
              const SizedBox(height: 16),
            ],
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewClassDetails(classData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                if (widget.canEdit) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _editSchedule(classData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8BB0C),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit Schedule'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _editInstructor(classData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit Instructor'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<ClassSchedule> _getSortedSchedules(List<ClassSchedule> schedules) {
    // Separate recurring schedules from specific date schedules
    final recurringSchedules = <ClassSchedule>[];
    final specificDateSchedules = <ClassSchedule>[];
    
    for (final schedule in schedules) {
      final isRecurring = schedule.date.year == 2024 && 
                         schedule.date.month == 1 && 
                         schedule.date.day == 1;
      if (isRecurring) {
        recurringSchedules.add(schedule);
      } else {
        specificDateSchedules.add(schedule);
      }
    }
    
    // Sort specific date schedules by date, then by start time
    specificDateSchedules.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      // If dates are the same, sort by start time
      return a.startTime.compareTo(b.startTime);
    });
    
    // Sort recurring schedules by day of week, then by start time
    recurringSchedules.sort((a, b) {
      final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCompare != 0) return dayCompare;
      // If same day, sort by start time
      return a.startTime.compareTo(b.startTime);
    });
    
    // Return specific date schedules first, then recurring schedules
    return [...specificDateSchedules, ...recurringSchedules];
  }

  Widget _buildScheduleItem(ClassSchedule schedule) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayName = days[schedule.dayOfWeek];
    // Display UTC times directly without timezone conversion
    final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
    
    // Check if this is a next week schedule (recurring schedules have date == DateTime(2024, 1, 1))
    final isRecurring = schedule.date.year == 2024 && schedule.date.month == 1 && schedule.date.day == 1;
    final isNextWeekSchedule = !isRecurring;
    
    String scheduleText;
    if (isNextWeekSchedule) {
      final date = schedule.date;
      scheduleText = '${date.day}/${date.month}/${date.year} ($dayName): $startTime - $endTime';
    } else {
      scheduleText = '$dayName: $startTime - $endTime';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isNextWeekSchedule 
            ? const Color(0xFFF8BB0C).withOpacity(0.2) // Different color for next week schedules
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: isNextWeekSchedule 
            ? Border.all(color: const Color(0xFFF8BB0C), width: 1)
            : null,
      ),
      child: Row(
        children: [
          if (isNextWeekSchedule) 
            const Icon(Icons.event, color: Color(0xFFF8BB0C), size: 12),
          if (isNextWeekSchedule) 
            const SizedBox(width: 4),
          Expanded(
            child: Text(
              scheduleText,
              style: TextStyle(
                color: isNextWeekSchedule ? const Color(0xFFF8BB0C) : Colors.white,
                fontSize: 12,
                fontWeight: isNextWeekSchedule ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewClassDetails(BranchClassResponse classData) {
    _showClassDetailsDialog(classData);
  }

  void _editSchedule(BranchClassResponse classData) {
    if (!widget.canEdit) {
      _showSnackBar('You do not have permission to edit schedules');
      return;
    }
    _showEditScheduleDialog(classData);
  }

  void _editInstructor(BranchClassResponse classData) {
    if (!widget.canEdit) {
      _showSnackBar('You do not have permission to edit instructors');
      return;
    }
    _showEditInstructorDialog(classData);
  }

  void _showClassDetailsDialog(BranchClassResponse classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Class Details - ${classData.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${classData.description}'),
              const SizedBox(height: 8),
              Text('Instructor: ${classData.instructor}'),
              const SizedBox(height: 8),
              Text('Capacity: ${classData.capacity} students'),
              const SizedBox(height: 8),
              Text('Duration: ${classData.duration} minutes'),
              const SizedBox(height: 8),
              Text('Status: ${classData.isActive ? 'Active' : 'Inactive'}'),
              const SizedBox(height: 8),
              Text('Created: ${_formatDate(classData.createdAt)}'),
              const SizedBox(height: 8),
              Text('Updated: ${_formatDate(classData.updatedAt)}'),
              if (classData.schedule.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._getSortedSchedules(classData.schedule).map((schedule) {
                  final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                  final dayName = days[schedule.dayOfWeek];
                  // Display UTC times directly without timezone conversion
                  final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
                  final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
                  
                  // Check if this is a next week schedule (recurring schedules have date == DateTime(2024, 1, 1))
                  final isRecurring = schedule.date.year == 2024 && schedule.date.month == 1 && schedule.date.day == 1;
                  final isNextWeekSchedule = !isRecurring;
                  
                  if (isNextWeekSchedule) {
                    final date = schedule.date;
                    return Text('${date.day}/${date.month}/${date.year} ($dayName): $startTime - $endTime');
                  } else {
                    return Text('$dayName: $startTime - $endTime');
                  }
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(BranchClassResponse classData) {
    List<ClassSchedule> schedules = List.from(classData.schedule);
    final List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Edit Schedule - ${classData.name}'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Current schedules
                  if (schedules.isNotEmpty) ...[
                    const Text('Current Schedules:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...schedules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final schedule = entry.value;
                    final dayName = days[schedule.dayOfWeek];
                    // Display UTC times directly without timezone conversion
                    final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
                    final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
                    
                    // Check if this is a next week schedule (recurring schedules have date == DateTime(2024, 1, 1))
                    final isRecurring = schedule.date.year == 2024 && schedule.date.month == 1 && schedule.date.day == 1;
                    final isNextWeekSchedule = !isRecurring;
                    
                    String scheduleText;
                    if (isNextWeekSchedule) {
                      final date = schedule.date;
                      scheduleText = '${date.day}/${date.month}/${date.year} ($dayName): $startTime - $endTime';
                    } else {
                      scheduleText = '$dayName: $startTime - $endTime';
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isNextWeekSchedule ? Colors.orange[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: isNextWeekSchedule 
                            ? Border.all(color: Colors.orange[300]!, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (isNextWeekSchedule) 
                            const Icon(Icons.event, color: Colors.orange, size: 16),
                          if (isNextWeekSchedule) 
                            const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              scheduleText,
                              style: TextStyle(
                                fontWeight: isNextWeekSchedule ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (widget.canEdit) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _editScheduleItem(setDialogState, schedules, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  schedules.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                
                  // Edit All Schedule button (only if user can edit)
                  if (widget.canEdit)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditAllScheduleDialog(classData);
                      },
                      child: const Text('Edit All Schedule'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (widget.canEdit)
              TextButton(
                onPressed: () async {
                  await _saveSchedule(classData.id, schedules);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditInstructorDialog(BranchClassResponse classData) {
    final TextEditingController instructorController = TextEditingController(text: classData.instructor);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Edit Instructor - ${classData.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: instructorController,
              enabled: widget.canEdit,
              decoration: InputDecoration(
                labelText: 'Instructor Name',
                hintText: widget.canEdit ? 'Enter instructor name' : 'View only',
                border: const OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            Text(
              'Current instructor: ${classData.instructor}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (widget.canEdit)
            TextButton(
              onPressed: () async {
                final newInstructor = instructorController.text.trim();
                if (newInstructor.isEmpty) {
                  _showSnackBar('Please enter an instructor name');
                  return;
                }
                if (newInstructor == classData.instructor) {
                  _showSnackBar('No changes made');
                  Navigator.pop(context);
                  return;
                }
                
                await _updateInstructor(classData.id, newInstructor);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
        ],
      ),
    );
  }

  Future<void> _updateInstructor(String classId, String instructor) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final instructorData = UpdateClassInstructorRequest(instructor: instructor);
      final result = await ApiService.updateBranchClassInstructor(
        classId,
        instructorData,
        accessToken,
      );

      if (result['success']) {
        _showSnackBar('Instructor updated successfully');
        _loadClasses(); // Refresh the classes list
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update instructor');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editScheduleItem(StateSetter setDialogState, List<ClassSchedule> schedules, int index) {
    _showScheduleItemDialog(setDialogState, schedules, editingIndex: index);
  }

  void _showEditAllScheduleDialog(BranchClassResponse classData) {
    List<ClassSchedule> allSchedules = List.from(classData.schedule);
    final List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    // Extract recurring schedules by grouping schedules with same day of week
    // Group by day_of_week to allow updating all schedules for a specific day
    Map<int, List<ClassSchedule>> groupedByDayOfWeek = {};
    
    for (final schedule in allSchedules) {
      final dayOfWeek = schedule.dayOfWeek;
      if (!groupedByDayOfWeek.containsKey(dayOfWeek)) {
        groupedByDayOfWeek[dayOfWeek] = [];
      }
      groupedByDayOfWeek[dayOfWeek]!.add(schedule);
    }
    
    // Find days that have multiple schedules (recurring pattern)
    // Use the most common time as the template, or the first one if all have different times
    Map<int, ClassSchedule> recurringSchedules = {};
    for (final entry in groupedByDayOfWeek.entries) {
      if (entry.value.length > 1) {
        // This day has multiple schedules - find the most common time pattern
        Map<String, int> timePatternCounts = {};
        for (final schedule in entry.value) {
          final timeKey = '${schedule.startTime.hour}_${schedule.startTime.minute}_${schedule.endTime.hour}_${schedule.endTime.minute}';
          timePatternCounts[timeKey] = (timePatternCounts[timeKey] ?? 0) + 1;
        }
        
        // Find the most common time pattern
        String? mostCommonTimeKey;
        int maxCount = 0;
        for (final timeEntry in timePatternCounts.entries) {
          if (timeEntry.value > maxCount) {
            maxCount = timeEntry.value;
            mostCommonTimeKey = timeEntry.key;
          }
        }
        
        // Use the schedule with the most common time pattern, or the first one
        ClassSchedule? templateSchedule;
        if (mostCommonTimeKey != null) {
          final parts = mostCommonTimeKey.split('_');
          final startH = int.parse(parts[0]);
          final startM = int.parse(parts[1]);
          final endH = int.parse(parts[2]);
          final endM = int.parse(parts[3]);
          
          templateSchedule = entry.value.firstWhere(
            (s) => s.startTime.hour == startH && 
                   s.startTime.minute == startM &&
                   s.endTime.hour == endH &&
                   s.endTime.minute == endM,
            orElse: () => entry.value.first,
          );
        } else {
          templateSchedule = entry.value.first;
        }
        
        recurringSchedules[entry.key] = templateSchedule;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Edit All Schedule - ${classData.name}'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recurring Weekly Schedules',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Edit recurring schedules that apply to all similar days (e.g., all Mondays)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Show existing recurring schedules
                    ...recurringSchedules.entries.map((entry) {
                      final dayOfWeek = entry.key;
                      final schedule = entry.value;
                      final dayName = days[dayOfWeek];
                      final startTime = TimeOfDay.fromDateTime(schedule.startTime);
                      final endTime = TimeOfDay.fromDateTime(schedule.endTime);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.repeat, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Every $dayName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _editRecurringSchedule(
                                    setDialogState,
                                    recurringSchedules,
                                    allSchedules,
                                    dayOfWeek,
                                    schedule,
                                    classData.id,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      recurringSchedules.remove(dayOfWeek);
                                      // Remove from all schedules
                                      allSchedules.removeWhere((s) => 
                                        s.dayOfWeek == dayOfWeek &&
                                        s.date.year == 2024 && 
                                        s.date.month == 1 && 
                                        s.date.day == 1
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Add new recurring schedule button
                    ElevatedButton.icon(
                      onPressed: () => _addRecurringSchedule(
                        setDialogState,
                        recurringSchedules,
                        allSchedules,
                        days,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Recurring Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Merge recurring schedules with existing specific date schedules
                final finalSchedules = <ClassSchedule>[];
                
                // Add all recurring schedules
                finalSchedules.addAll(recurringSchedules.values);
                
                // Add all non-recurring schedules from original list
                for (final schedule in classData.schedule) {
                  final isRecurring = schedule.date.year == 2024 && 
                                     schedule.date.month == 1 && 
                                     schedule.date.day == 1;
                  if (!isRecurring) {
                    finalSchedules.add(schedule);
                  }
                }
                
                await _saveSchedule(classData.id, finalSchedules);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _addRecurringSchedule(
    StateSetter setDialogState,
    Map<int, ClassSchedule> recurringSchedules,
    List<ClassSchedule> allSchedules,
    List<String> days,
  ) {
    int selectedDay = 0;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setTimeDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Add Recurring Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
                items: days.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setTimeDialogState(() {
                    selectedDay = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setTimeDialogState(() {
                            startTime = time;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (time != null) {
                          setTimeDialogState(() {
                            endTime = time;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (startTime.hour > endTime.hour || 
                    (startTime.hour == endTime.hour && startTime.minute >= endTime.minute)) {
                  _showSnackBar('End time must be after start time');
                  return;
                }

                if (recurringSchedules.containsKey(selectedDay)) {
                  _showSnackBar('A recurring schedule already exists for ${days[selectedDay]}');
                  return;
                }

                // Create recurring schedule
                final utcStartTime = DateTime.utc(2024, 1, 1, startTime.hour, startTime.minute);
                final utcEndTime = DateTime.utc(2024, 1, 1, endTime.hour, endTime.minute);
                final newSchedule = ClassSchedule(
                  dayOfWeek: selectedDay,
                  date: DateTime(2024, 1, 1),
                  startTime: utcStartTime,
                  endTime: utcEndTime,
                );

                setDialogState(() {
                  recurringSchedules[selectedDay] = newSchedule;
                  allSchedules.add(newSchedule);
                });

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editRecurringSchedule(
    StateSetter setDialogState,
    Map<int, ClassSchedule> recurringSchedules,
    List<ClassSchedule> allSchedules,
    int dayOfWeek,
    ClassSchedule schedule,
    String classId, // Not used for bulk update, but kept for compatibility
  ) async {
    TimeOfDay startTime = TimeOfDay.fromDateTime(schedule.startTime);
    TimeOfDay endTime = TimeOfDay.fromDateTime(schedule.endTime);
    final List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setTimeDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Edit Recurring Schedule - ${days[dayOfWeek]}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setTimeDialogState(() {
                            startTime = time;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (time != null) {
                          setTimeDialogState(() {
                            endTime = time;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (startTime.hour > endTime.hour || 
                    (startTime.hour == endTime.hour && startTime.minute >= endTime.minute)) {
                  _showSnackBar('End time must be after start time');
                  return;
                }

                // Format times as ISO 8601 datetime strings for the API
                // The backend expects time.Time which requires full datetime in ISO 8601 format
                // We use today's date with the specified time, in UTC
                final now = DateTime.now().toUtc();
                final startDateTime = DateTime.utc(now.year, now.month, now.day, startTime.hour, startTime.minute, 0);
                final endDateTime = DateTime.utc(now.year, now.month, now.day, endTime.hour, endTime.minute, 0);
                final startTimeStr = startDateTime.toIso8601String();
                final endTimeStr = endDateTime.toIso8601String();

                // Ensure day_of_week matches backend format (0=Sunday, 1=Monday, ..., 6=Saturday)
                print('=== Bulk Update Class Time Debug ===');
                print('Day of Week: $dayOfWeek (${days[dayOfWeek]})');
                print('Start Time: $startTimeStr');
                print('End Time: $endTimeStr');
                print('Full URL will be: /api/branch/classes/bulk-update-time');

                // Create bulk update request
                // Note: The backend uses authenticated branch context for BranchAdmin,
                // so we don't need to pass branchId
                final bulkUpdateRequest = BulkUpdateClassTimeRequest(
                  dayOfWeek: dayOfWeek,
                  newStartTime: startTimeStr,
                  newEndTime: endTimeStr,
                );
                
                print('Request JSON: ${jsonEncode(bulkUpdateRequest.toJson())}');

                // Show loading
                setTimeDialogState(() {
                  // Close the dialog first
                });
                Navigator.pop(context);

                // Call API to bulk update class times for all classes in the branch
                setState(() {
                  _isLoading = true;
                });

                try {
                  final result = await ApiService.bulkUpdateClassTime(
                    bulkUpdateRequest,
                    accessToken,
                  );

                  if (result['success']) {
                    final responseData = result['data'];
                    if (responseData != null) {
                      final response = BulkUpdateClassTimeResponse.fromJson(responseData);
                      final message = 'Updated ${response.updatedClassesCount} classes, ${response.updatedSchedulesCount} schedules for ${response.dayOfWeek}';
                      _showSnackBar(message);
                      print('Bulk update successful: $message');
                      print('Updated dates: ${response.updatedDates}');
                    } else {
                      _showSnackBar('Recurring schedule updated successfully');
                    }
                    // Reload classes to get updated schedule
                    await _loadClasses();
                  } else {
                    final errorMsg = result['message'] ?? 'Failed to update recurring schedule';
                    final errorDetails = result['error'];
                    print('Bulk update failed: $errorMsg');
                    if (errorDetails != null) {
                      print('Error details: $errorDetails');
                    }
                    _showSnackBar(errorMsg);
                  }
                } catch (e) {
                  print('Exception during bulk update: $e');
                  _showSnackBar('An error occurred: $e');
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleItemDialog(StateSetter setDialogState, List<ClassSchedule> schedules, {int? editingIndex}) {
    // Only allow editing specific dates, not recurring schedules
    if (editingIndex == null) {
      _showSnackBar('Please use "Edit All Schedule" to add new schedules');
      return;
    }
    
    final existingSchedule = schedules[editingIndex];
    // Check if this is a recurring schedule
    final isRecurring = existingSchedule.date.year == 2024 && 
                       existingSchedule.date.month == 1 && 
                       existingSchedule.date.day == 1;
    
    if (isRecurring) {
      _showSnackBar('Please use "Edit All Schedule" to edit recurring schedules');
      return;
    }
    
    TimeOfDay startTime = TimeOfDay.fromDateTime(existingSchedule.startTime);
    TimeOfDay endTime = TimeOfDay.fromDateTime(existingSchedule.endTime);
    DateTime selectedDate = DateTime(
      existingSchedule.date.year,
      existingSchedule.date.month,
      existingSchedule.date.day,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setTimeDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Edit Schedule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Date selection
              ListTile(
                title: const Text('Date'),
                subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setTimeDialogState(() {
                      selectedDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Time selection
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setTimeDialogState(() {
                            startTime = time;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (time != null) {
                          setTimeDialogState(() {
                            endTime = time;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validate times
                if (startTime.hour > endTime.hour || 
                    (startTime.hour == endTime.hour && startTime.minute >= endTime.minute)) {
                  _showSnackBar('End time must be after start time');
                  return;
                }

                // Check for overlapping schedules on the same date
                for (int i = 0; i < schedules.length; i++) {
                  if (i == editingIndex) continue;
                  
                  final existingSchedule = schedules[i];
                  // Check if existing schedule is recurring (skip conflict check for recurring)
                  final existingIsRecurring = existingSchedule.date.year == 2024 && 
                                             existingSchedule.date.month == 1 && 
                                             existingSchedule.date.day == 1;
                  
                  if (!existingIsRecurring) {
                    // Check if it's the same date
                    if (existingSchedule.date.year == selectedDate.year &&
                        existingSchedule.date.month == selectedDate.month &&
                        existingSchedule.date.day == selectedDate.day) {
                      final existingStart = TimeOfDay.fromDateTime(existingSchedule.startTime);
                      final existingEnd = TimeOfDay.fromDateTime(existingSchedule.endTime);
                      
                      if ((startTime.hour < existingEnd.hour || 
                           (startTime.hour == existingEnd.hour && startTime.minute < existingEnd.minute)) &&
                          (endTime.hour > existingStart.hour || 
                           (endTime.hour == existingStart.hour && endTime.minute > existingStart.minute))) {
                        _showSnackBar('Schedule times overlap with existing schedule on this date');
                        return;
                      }
                    }
                  }
                }

                // Create schedule for specific date
                final scheduleDate = selectedDate;
                // Create UTC DateTime directly (treat entered times as UTC)
                final utcStartTime = DateTime.utc(scheduleDate.year, scheduleDate.month, scheduleDate.day, startTime.hour, startTime.minute);
                final utcEndTime = DateTime.utc(scheduleDate.year, scheduleDate.month, scheduleDate.day, endTime.hour, endTime.minute);
                final newSchedule = ClassSchedule(
                  dayOfWeek: scheduleDate.weekday % 7, // Convert to 0-6 format (Sunday = 0)
                  date: scheduleDate,
                  startTime: utcStartTime,
                  endTime: utcEndTime,
                );

                setDialogState(() {
                  schedules[editingIndex] = newSchedule;
                });

                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSchedule(String classId, List<ClassSchedule> schedules) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final scheduleData = UpdateClassScheduleRequest(schedule: schedules);
      final result = await ApiService.updateBranchClassSchedule(
        classId,
        scheduleData,
        accessToken,
      );

      if (result['success']) {
        _showSnackBar('Schedule updated successfully');
        _loadClasses(); // Refresh the classes list
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update schedule');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to call logout API, but don't fail if it doesn't work
      try {
        final result = await ApiService.branchLogout(accessToken);
        if (result['success']) {
          print('Branch logout API successful');
        } else {
          print('Branch logout API failed: ${result['message']}');
        }
      } catch (e) {
        print('Branch logout API failed, but continuing with local logout: $e');
      }
      
      // Always show success message and navigate back
      _showSnackBar('Logged out successfully');
      Navigator.pop(context); // Go back to login page
    } catch (e) {
      print('Error during logout process: $e');
      // Even if there's an error, try to navigate back
      _showSnackBar('Logged out successfully');
      Navigator.pop(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  void _showTeamMembersDialog(Map<String, dynamic> branchData) {
    final teamMembers = branchData['team_members'] as List? ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Team Members'),
        content: SizedBox(
          width: double.maxFinite,
          child: teamMembers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No team members found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Team members will appear here once they are added to the branch',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: teamMembers.length,
                  itemBuilder: (context, index) {
                    final member = teamMembers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFF8BB0C),
                                child: Text(
                                  (member['full_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['full_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      member['role'] ?? 'No role specified',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTeamMemberInfoRow('Email', member['email'] ?? 'N/A'),
                          _buildTeamMemberInfoRow('Phone', '${member['country_code'] ?? ''} ${member['phone_number'] ?? 'N/A'}'),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
