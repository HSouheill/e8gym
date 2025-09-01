import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/branch_class_models.dart';
import 'models/standalone_class_models.dart';
import 'branch_users_page.dart';

class BranchDashboardPage extends StatefulWidget {
  final Map<String, dynamic> branchData;
  final String accessToken;
  
  const BranchDashboardPage({
    super.key,
    required this.branchData,
    required this.accessToken,
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
      final result = await ApiService.getBranchClasses(accessToken);
      
      if (result['success']) {
        final classListResponse = BranchClassListResponse.fromJson(result['data']);
        setState(() {
          _classes = classListResponse.classes;
          _isLoadingClasses = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load classes';
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
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
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
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
          
          // Session info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Session Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Token expires in ${((widget.branchData['expires_in'] ?? 3600) / 3600).toStringAsFixed(1)} hours',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Add some bottom padding to prevent overflow
          const SizedBox(height: 20),
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
              ...classData.schedule.map((schedule) => _buildScheduleItem(schedule)),
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
                const SizedBox(width: 12),
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

  Widget _buildScheduleItem(ClassSchedule schedule) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayName = days[schedule.dayOfWeek];
    final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
    
    // Check if this is a next week schedule (has specific date)
    final isNextWeekSchedule = schedule.startTime.year > 2024 || 
                              (schedule.startTime.year == 2024 && schedule.startTime.month > 1);
    
    String scheduleText;
    if (isNextWeekSchedule) {
      final date = schedule.startTime;
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
    _showEditScheduleDialog(classData);
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
                ...classData.schedule.map((schedule) {
                  final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                  final dayName = days[schedule.dayOfWeek];
                  final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
                  final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
                  
                  // Check if this is a next week schedule
                  final isNextWeekSchedule = schedule.startTime.year > 2024 || 
                                            (schedule.startTime.year == 2024 && schedule.startTime.month > 1);
                  
                  if (isNextWeekSchedule) {
                    final date = schedule.startTime;
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
          content: SizedBox(
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
                    final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
                    final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
                    
                    // Check if this is a next week schedule
                    final isNextWeekSchedule = schedule.startTime.year > 2024 || 
                                              (schedule.startTime.year == 2024 && schedule.startTime.month > 1);
                    
                    String scheduleText;
                    if (isNextWeekSchedule) {
                      final date = schedule.startTime;
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
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                
                // Add new schedule button
                ElevatedButton(
                  onPressed: () => _addScheduleItem(setDialogState, schedules),
                  child: const Text('Add Schedule'),
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

  void _addScheduleItem(StateSetter setDialogState, List<ClassSchedule> schedules) {
    _showScheduleItemDialog(setDialogState, schedules);
  }

  void _editScheduleItem(StateSetter setDialogState, List<ClassSchedule> schedules, int index) {
    _showScheduleItemDialog(setDialogState, schedules, editingIndex: index);
  }

  void _showScheduleItemDialog(StateSetter setDialogState, List<ClassSchedule> schedules, {int? editingIndex}) {
    int selectedDay = editingIndex != null ? schedules[editingIndex].dayOfWeek : 0;
    TimeOfDay startTime = editingIndex != null 
        ? TimeOfDay.fromDateTime(schedules[editingIndex].startTime)
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = editingIndex != null 
        ? TimeOfDay.fromDateTime(schedules[editingIndex].endTime)
        : const TimeOfDay(hour: 10, minute: 0);
    final List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    // For next week scheduling
    bool isNextWeekSchedule = false;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setTimeDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(editingIndex != null ? 'Edit Schedule' : 'Add Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Schedule type selection
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Recurring'),
                      subtitle: const Text('Every week'),
                      value: false,
                      groupValue: isNextWeekSchedule,
                      onChanged: (value) {
                        setTimeDialogState(() {
                          isNextWeekSchedule = value!;
                          selectedDate = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Next Week'),
                      subtitle: const Text('Specific date'),
                      value: true,
                      groupValue: isNextWeekSchedule,
                      onChanged: (value) {
                        setTimeDialogState(() {
                          isNextWeekSchedule = value!;
                          // Set default to next week's same day
                          final now = DateTime.now();
                          final nextWeek = now.add(const Duration(days: 7));
                          selectedDate = DateTime(nextWeek.year, nextWeek.month, nextWeek.day);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Day selection (for recurring) or Date selection (for next week)
              if (!isNextWeekSchedule) ...[
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
              ] else ...[
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(selectedDate != null 
                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                      : 'Select a date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 14)), // Allow up to 2 weeks ahead
                    );
                    if (date != null) {
                      setTimeDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ],
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

                // Validate date selection for next week scheduling
                if (isNextWeekSchedule && selectedDate == null) {
                  _showSnackBar('Please select a date for next week scheduling');
                  return;
                }

                // Check for overlapping schedules
                for (int i = 0; i < schedules.length; i++) {
                  if (i == editingIndex) continue;
                  
                  final existingSchedule = schedules[i];
                  bool hasConflict = false;
                  
                  if (isNextWeekSchedule) {
                    // For next week scheduling, check if the selected date conflicts with any existing schedule
                    if (existingSchedule.dayOfWeek == selectedDate!.weekday % 7) { // Convert to 0-6 format
                      final existingStart = TimeOfDay.fromDateTime(existingSchedule.startTime);
                      final existingEnd = TimeOfDay.fromDateTime(existingSchedule.endTime);
                      
                      if ((startTime.hour < existingEnd.hour || 
                           (startTime.hour == existingEnd.hour && startTime.minute < existingEnd.minute)) &&
                          (endTime.hour > existingStart.hour || 
                           (endTime.hour == existingStart.hour && endTime.minute > existingStart.minute))) {
                        hasConflict = true;
                      }
                    }
                  } else {
                    // For recurring schedules, check day of week conflicts
                    if (existingSchedule.dayOfWeek == selectedDay) {
                      final existingStart = TimeOfDay.fromDateTime(existingSchedule.startTime);
                      final existingEnd = TimeOfDay.fromDateTime(existingSchedule.endTime);
                      
                      if ((startTime.hour < existingEnd.hour || 
                           (startTime.hour == existingEnd.hour && startTime.minute < existingEnd.minute)) &&
                          (endTime.hour > existingStart.hour || 
                           (endTime.hour == existingStart.hour && endTime.minute > existingStart.minute))) {
                        hasConflict = true;
                      }
                    }
                  }
                  
                  if (hasConflict) {
                    _showSnackBar('Schedule times overlap with existing schedule');
                    return;
                  }
                }

                ClassSchedule newSchedule;
                if (isNextWeekSchedule) {
                  // Create schedule for specific date
                  final scheduleDate = selectedDate!;
                  newSchedule = ClassSchedule(
                    dayOfWeek: scheduleDate.weekday % 7, // Convert to 0-6 format (Sunday = 0)
                    startTime: DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day, startTime.hour, startTime.minute),
                    endTime: DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day, endTime.hour, endTime.minute),
                  );
                } else {
                  // Create recurring schedule
                  newSchedule = ClassSchedule(
                    dayOfWeek: selectedDay,
                    startTime: DateTime(2024, 1, 1, startTime.hour, startTime.minute),
                    endTime: DateTime(2024, 1, 1, endTime.hour, endTime.minute),
                  );
                }

                setDialogState(() {
                  if (editingIndex != null) {
                    schedules[editingIndex] = newSchedule;
                  } else {
                    schedules.add(newSchedule);
                  }
                });

                Navigator.pop(context);
              },
              child: Text(editingIndex != null ? 'Update' : 'Add'),
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
      final result = await ApiService.branchLogout(accessToken);
      
      if (result['success']) {
        _showSnackBar('Logged out successfully');
        Navigator.pop(context); // Go back to login page
      } else {
        _showSnackBar(result['message'] ?? 'Logout failed');
      }
    } catch (e) {
      _showSnackBar('An error occurred during logout: $e');
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
