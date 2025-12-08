import 'package:flutter/material.dart';
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
                              colors: [Colors.white, Colors.white70],
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
                          title: 'Classes (${_getFilteredClasses().length})',
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
                  subtitle: '${_getFilteredClasses().length} classes',
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

  List<BranchClassResponse> _getFilteredClasses() {
    // Filter out classes where isVisible is false
    return _classes.where((classData) {
      // Hide if visibility is explicitly set to false
      if (classData.isVisible == false) return false;
      // Show if visible is true or null (default to visible)
      return true;
    }).toList();
  }

  Widget _buildClassesContent() {
    final filteredClasses = _getFilteredClasses();
    
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
                  : filteredClasses.isEmpty
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
                          itemCount: filteredClasses.length,
                          itemBuilder: (context, index) {
                            return _buildClassCard(filteredClasses[index]);
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
            _buildInfoRow('Capacity', '${classData.capacity} members'),
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
              _buildGroupedSchedule(classData.schedule),
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
                        backgroundColor: Colors.white,
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
            
            if (widget.canEdit) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _editCapacity(classData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Edit Capacity'),
                ),
              ),
            ],
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
    
    // Recurring schedules use dates in 2099 as marker dates
    // The exact date depends on the day of week (each day uses a date that falls on that day)
    for (final schedule in schedules) {
      final isRecurring = schedule.date.year >= 2099;
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

  Widget _buildGroupedSchedule(List<ClassSchedule> schedules) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    // Group schedules by day of week
    Map<int, List<ClassSchedule>> groupedByDay = {};
    Map<int, List<ClassSchedule>> specificDatesByDay = {};
    
    for (final schedule in schedules) {
      final isRecurring = schedule.date.year >= 2099;
      
      if (isRecurring) {
        // Recurring schedule - group by day of week
        if (!groupedByDay.containsKey(schedule.dayOfWeek)) {
          groupedByDay[schedule.dayOfWeek] = [];
        }
        groupedByDay[schedule.dayOfWeek]!.add(schedule);
      } else {
        // Specific date schedule - group by day name
        if (!specificDatesByDay.containsKey(schedule.dayOfWeek)) {
          specificDatesByDay[schedule.dayOfWeek] = [];
        }
        specificDatesByDay[schedule.dayOfWeek]!.add(schedule);
      }
    }
    
    // Sort days
    final sortedDays = <int>[];
    for (int i = 0; i < 7; i++) {
      if (groupedByDay.containsKey(i) || specificDatesByDay.containsKey(i)) {
        sortedDays.add(i);
      }
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortedDays.map((dayOfWeek) {
        final recurringSchedules = groupedByDay[dayOfWeek] ?? [];
        final specificSchedules = specificDatesByDay[dayOfWeek] ?? [];
        final allSchedules = [...recurringSchedules, ...specificSchedules];
        
        // Sort schedules by start time
        allSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
        
        return GestureDetector(
          onTap: () => _showDayScheduleDialog(days[dayOfWeek], allSchedules),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  days[dayOfWeek],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allSchedules.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showDayScheduleDialog(String dayName, List<ClassSchedule> schedules) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('$dayName Schedule'),
        content: SizedBox(
          width: double.maxFinite,
          child: schedules.isEmpty
              ? const Text('No schedules for this day')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    final isRecurring = schedule.date.year >= 2099;
                    final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
                    final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
                    
                    String scheduleText;
                    if (isRecurring) {
                      scheduleText = '$startTime - $endTime';
                    } else {
                      final date = schedule.date;
                      scheduleText = '${date.day}/${date.month}/${date.year}: $startTime - $endTime';
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isRecurring ? Colors.blue[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isRecurring ? Colors.blue[200]! : Colors.orange[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRecurring ? Icons.repeat : Icons.event,
                            color: isRecurring ? Colors.blue : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scheduleText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isRecurring ? Colors.blue[900] : Colors.orange[900],
                                  ),
                                ),
                                if (isRecurring)
                                  Text(
                                    'Recurring weekly',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
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

  Widget _buildScheduleItem(ClassSchedule schedule) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayName = days[schedule.dayOfWeek];
    // Display UTC times directly without timezone conversion
    final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
    
    // Check if this is a recurring schedule (recurring schedules use dates in 2099 as markers)
    final isRecurring = schedule.date.year >= 2099;
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
            ? Colors.white.withOpacity(0.2) // Different color for next week schedules
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: isNextWeekSchedule 
            ? Border.all(color: Colors.white, width: 1)
            : null,
      ),
      child: Row(
        children: [
          if (isNextWeekSchedule) 
            const Icon(Icons.event, color: Colors.white, size: 12),
          if (isNextWeekSchedule) 
            const SizedBox(width: 4),
          Expanded(
            child: Text(
              scheduleText,
              style: TextStyle(
                color: isNextWeekSchedule ? Colors.white : Colors.white,
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
              Text('Capacity: ${classData.capacity} members'),
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
                  
                  // Check if this is a recurring schedule (recurring schedules use dates in 2099 as markers)
                  final isRecurring = schedule.date.year >= 2099;
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
    List<ClassSchedule> schedules = _getSortedSchedules(List<ClassSchedule>.from(classData.schedule));
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
                    
                    // Check if this is a recurring schedule (recurring schedules use dates in 2099 as markers)
                    final isRecurring = schedule.date.year >= 2099;
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
                
                  // Add Time Slot button (only if user can edit)
                  if (widget.canEdit) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        _addTimeSlotFromScheduleDialog(setDialogState, schedules, classData);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Time Slot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
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
    }
  }

  void _editCapacity(BranchClassResponse classData) {
    if (!widget.canEdit) {
      _showSnackBar('You do not have permission to edit capacity');
      return;
    }
    _showEditCapacityDialog(classData);
  }

  void _showEditCapacityDialog(BranchClassResponse classData) {
    final TextEditingController capacityController = TextEditingController(text: classData.capacity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Edit Capacity - ${classData.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: capacityController,
              enabled: widget.canEdit,
              decoration: InputDecoration(
                labelText: 'Capacity',
                hintText: widget.canEdit ? 'Enter number of members' : 'View only',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Current capacity: ${classData.capacity} members',
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
                final capacityText = capacityController.text.trim();
                if (capacityText.isEmpty) {
                  _showSnackBar('Please enter a capacity');
                  return;
                }
                
                final newCapacity = int.tryParse(capacityText);
                if (newCapacity == null || newCapacity < 1) {
                  _showSnackBar('Please enter a valid capacity (minimum 1)');
                  return;
                }
                
                if (newCapacity == classData.capacity) {
                  _showSnackBar('No changes made');
                  Navigator.pop(context);
                  return;
                }
                
                await _updateCapacity(classData.id, newCapacity);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
        ],
      ),
    );
  }

  Future<void> _updateCapacity(String classId, int capacity) async {
    try {
      // Get branch ID from branchData
      final branchData = widget.branchData['branch'] ?? {};
      final branchId = branchData['id'] ?? branchData['_id'] ?? '';
      
      if (branchId.isEmpty) {
        _showSnackBar('Branch ID not found');
        return;
      }

      final updateData = UpdateClassRequest(capacity: capacity);
      final result = await ApiService.updateBranchClass(
        branchId,
        classId,
        updateData,
        accessToken,
      );

      if (result['success']) {
        _showSnackBar('Capacity updated successfully');
        _loadClasses(); // Refresh the classes list
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update capacity');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }
  }

  void _editScheduleItem(StateSetter setDialogState, List<ClassSchedule> schedules, int index) {
    _showScheduleItemDialog(setDialogState, schedules, editingIndex: index);
  }

  void _addTimeSlotFromScheduleDialog(
    StateSetter setDialogState,
    List<ClassSchedule> schedules,
    BranchClassResponse classData,
  ) {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    DateTime selectedDate = DateTime.now();
    final List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setTimeDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Add Time Slot'),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date selection
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year} (${days[selectedDate.weekday % 7]})'),
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
                for (final existingSchedule in schedules) {
                  // Check if existing schedule is recurring (skip conflict check for recurring)
                  final existingIsRecurring = existingSchedule.date.year >= 2099;
                  
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

                // Add to schedules list and update dialog state
                setDialogState(() {
                  schedules.add(newSchedule);
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

  void _showEditAllScheduleDialog(BranchClassResponse classData) {
    List<ClassSchedule> allSchedules = _getSortedSchedules(List<ClassSchedule>.from(classData.schedule));
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
                                      // Remove all schedules for this day of week
                                      allSchedules.removeWhere((s) => s.dayOfWeek == dayOfWeek);
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
                await _saveSchedule(classData.id, allSchedules);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get a future date that falls on the specified day of week
  // dayOfWeek: 0=Sunday, 1=Monday, ..., 6=Saturday (backend format)
  DateTime _getRecurringDateMarker(int dayOfWeek) {
    // Use a date in 2099 that falls on the correct day of week
    // We'll use 2099-01-01 as a base and calculate from there
    final baseDate = DateTime.utc(2099, 1, 1);
    
    // Convert Dart weekday (1=Monday, 7=Sunday) to backend format (0=Sunday, 1=Monday, ..., 6=Saturday)
    final baseDartWeekday = baseDate.weekday; // 1-7
    final baseBackendWeekday = baseDartWeekday == 7 ? 0 : baseDartWeekday; // Convert to 0-6
    
    // Calculate the offset needed to get to the desired day of week
    int offset = dayOfWeek - baseBackendWeekday;
    if (offset < 0) {
      offset += 7; // Wrap around if negative
    }
    
    return baseDate.add(Duration(days: offset));
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
                // Use a future date that falls on the correct day of week as marker
                // This ensures the backend calculates the correct weekday from the date
                final recurringDateMarker = _getRecurringDateMarker(selectedDay);
                final utcStartTime = DateTime.utc(recurringDateMarker.year, recurringDateMarker.month, recurringDateMarker.day, startTime.hour, startTime.minute);
                final utcEndTime = DateTime.utc(recurringDateMarker.year, recurringDateMarker.month, recurringDateMarker.day, endTime.hour, endTime.minute);
                final newSchedule = ClassSchedule(
                  dayOfWeek: selectedDay,
                  date: recurringDateMarker,
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
    String classId, // The specific class ID to update
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

                bool updated = false;
                setDialogState(() {
                  ClassSchedule? template;
                  for (int i = 0; i < allSchedules.length; i++) {
                    final scheduleEntry = allSchedules[i];
                    if (scheduleEntry.dayOfWeek == dayOfWeek) {
                      final date = scheduleEntry.date;
                      final updatedSchedule = ClassSchedule(
                        dayOfWeek: scheduleEntry.dayOfWeek,
                        date: date,
                        startTime: DateTime.utc(date.year, date.month, date.day, startTime.hour, startTime.minute),
                        endTime: DateTime.utc(date.year, date.month, date.day, endTime.hour, endTime.minute),
                      );
                      allSchedules[i] = updatedSchedule;
                      template ??= updatedSchedule;
                      updated = true;
                    }
                  }
                  if (template != null) {
                    recurringSchedules[dayOfWeek] = template;
                  }
                });

                if (!updated) {
                  _showSnackBar('No schedules found for ${days[dayOfWeek]}');
                  return;
                }

                Navigator.pop(context);
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
    // Check if this is a recurring schedule (recurring schedules use dates in 2099 as markers)
    final isRecurring = existingSchedule.date.year >= 2099;
    
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
                  final existingIsRecurring = existingSchedule.date.year >= 2099;
                  
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
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleLogout() async {
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
    }
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
                                backgroundColor: Colors.white,
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
