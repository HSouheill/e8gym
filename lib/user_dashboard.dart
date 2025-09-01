import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'models/standalone_class_models.dart';
import 'models/booking_models.dart';
import 'models/branch_class_models.dart';
import 'models/auth_models.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  
  // State management
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _accessToken;
  
  // Current view state
  bool _showingBranches = true;
  BranchResponse? _selectedBranch;
  
  // Branches data
  List<BranchResponse> _branches = [];
  final TextEditingController _branchSearchController = TextEditingController();
  String _branchSearchQuery = '';
  
  // Classes data
  List<BranchClassResponse> _classes = [];
  final TextEditingController _classSearchController = TextEditingController();
  String _classSearchQuery = '';
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _branchSearchController.dispose();
    _classSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    try {
      await _storageService.init();
      _accessToken = _storageService.getAccessToken();
      if (_accessToken != null) {
        await _loadBranches();
      } else {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBranches({bool refresh = false}) async {
    if (_accessToken == null) return;

    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _currentPage = 1;
        _hasMoreData = true;
      });
    }

    try {
      final result = await ApiService.getBranches(
        _accessToken!,
        page: _currentPage,
        limit: 20,
        search: _branchSearchQuery.isNotEmpty ? _branchSearchQuery : null,
      );

      if (result['success']) {
        final data = result['data'];
        final branches = (data['branches'] as List)
            .map((branchData) => BranchResponse.fromJson(branchData))
            .toList();

        setState(() {
          if (refresh || _currentPage == 1) {
            _branches = branches;
          } else {
            _branches.addAll(branches);
          }
          
          _totalPages = (data['total'] / 20).ceil();
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load branches';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadBranchClasses({bool refresh = false}) async {
    if (_accessToken == null || _selectedBranch == null) return;

    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _currentPage = 1;
        _hasMoreData = true;
      });
    }

    try {
      final result = await ApiService.getBranchClassesForUser(
        _selectedBranch!.id,
        _accessToken!,
        page: _currentPage,
        limit: 20,
      );

      if (result['success']) {
        final data = result['data'];
        final classes = (data['classes'] as List)
            .map((classData) => BranchClassResponse.fromJson(classData))
            .toList();

        setState(() {
          if (refresh || _currentPage == 1) {
            _classes = classes;
          } else {
            _classes.addAll(classes);
          }
          
          _totalPages = (data['total'] / 20).ceil();
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load classes';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMoreData || _isLoading) return;

    setState(() {
      _currentPage++;
    });

    if (_showingBranches) {
      await _loadBranches();
    } else {
      await _loadBranchClasses();
    }
  }

  void _onBranchSearchChanged(String query) {
    setState(() {
      _branchSearchQuery = query;
    });
    
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_branchSearchQuery == query) {
        _loadBranches(refresh: true);
      }
    });
  }

  void _onClassSearchChanged(String query) {
    setState(() {
      _classSearchQuery = query;
    });
    
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_classSearchQuery == query) {
        _loadBranchClasses(refresh: true);
      }
    });
  }

  void _selectBranch(BranchResponse branch) {
    setState(() {
      _selectedBranch = branch;
      _showingBranches = false;
      _classes = [];
      _currentPage = 1;
      _hasMoreData = true;
    });
    _loadBranchClasses();
  }

  void _goBackToBranches() {
    setState(() {
      _showingBranches = true;
      _selectedBranch = null;
      _classes = [];
      _currentPage = 1;
      _hasMoreData = true;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
      await _storageService.clearAuthData();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBookClass(BranchClassResponse classData) async {
    if (_accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog with branch information
    final shouldBook = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Book Class',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to book "${classData.name}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${_selectedBranch?.branchName}',
              style: const TextStyle(
                color: Color(0xFFF8BB0C),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Instructor: ${classData.instructor}',
              style: const TextStyle(
                color: Color(0xFFF8BB0C),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8BB0C),
              foregroundColor: Colors.black,
            ),
            child: const Text('Book Class'),
          ),
        ],
      ),
    );

    if (shouldBook != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
        ),
      ),
    );

    try {
      // Validate required data
      if (_selectedBranch == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch information is missing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get the next available schedule for this class
      if (classData.schedule.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No schedule available for this class'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // For simplicity, we'll use the first available schedule
      final schedule = classData.schedule.first;
      
      // Calculate the next occurrence of this schedule
      final nextOccurrence = _getNextOccurrence(schedule.dayOfWeek, schedule.startTime);
      
      // Create booking request
      final bookingRequest = CreateBookingRequest(
        classId: classData.id,
        classType: 'branch',
        branchId: _selectedBranch!.id, // Required for branch class bookings
        scheduleId: classData.id, // Using class ID as schedule ID for simplicity
        classDate: nextOccurrence,
        startTime: DateTime(
          nextOccurrence.year,
          nextOccurrence.month,
          nextOccurrence.day,
          schedule.startTime.hour,
          schedule.startTime.minute,
        ),
        endTime: DateTime(
          nextOccurrence.year,
          nextOccurrence.month,
          nextOccurrence.day,
          schedule.endTime.hour,
          schedule.endTime.minute,
        ),
      );

      // Debug log to verify the request
      print('Booking request: ${bookingRequest.toJson()}');

      final result = await ApiService.createBooking(bookingRequest, _accessToken!);

      Navigator.of(context).pop(); // Close loading dialog

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? '${classData.name} booked successfully at ${_selectedBranch?.branchName}!'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to book class'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _getNextOccurrence(int dayOfWeek, DateTime time) {
    final now = DateTime.now();
    final today = now.weekday;
    
    // Calculate days until next occurrence
    int daysUntilNext = dayOfWeek - today;
    if (daysUntilNext <= 0) {
      daysUntilNext += 7; // Next week
    }
    
    return DateTime(
      now.year,
      now.month,
      now.day + daysUntilNext,
      time.hour,
      time.minute,
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  String _formatSchedule(List<ClassSchedule> schedule) {
    if (schedule.isEmpty) return 'No schedule available';
    
    final groupedSchedule = <int, List<ClassSchedule>>{};
    for (final s in schedule) {
      groupedSchedule.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }
    
    final sortedDays = groupedSchedule.keys.toList()..sort();
    final scheduleStrings = sortedDays.map((day) {
      final daySchedules = groupedSchedule[day]!;
      final timeRanges = daySchedules.map((s) => 
        '${_formatTime(s.startTime)}-${_formatTime(s.endTime)}'
      ).join(', ');
      return '${_getDayName(day)}: $timeRanges';
    }).toList();
    
    return scheduleStrings.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
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
                _buildHeader(),
                
                // Search bar
                _buildSearchBar(),
                
                // Content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (!_showingBranches)
            IconButton(
              onPressed: _goBackToBranches,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _showingBranches ? 'Available Branches' : '${_selectedBranch?.branchName} Classes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (_showingBranches) {
                _loadBranches(refresh: true);
              } else {
                _loadBranchClasses(refresh: true);
              }
            },
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFF8BB0C), width: 1),
      ),
      child: TextField(
        controller: _showingBranches ? _branchSearchController : _classSearchController,
        onChanged: _showingBranches ? _onBranchSearchChanged : _onClassSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: _showingBranches ? 'Search branches...' : 'Search classes...',
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && (_showingBranches ? _branches.isEmpty : _classes.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
        ),
      );
    }

    if (_errorMessage != null && (_showingBranches ? _branches.isEmpty : _classes.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_showingBranches) {
                  _loadBranches(refresh: true);
                } else {
                  _loadBranchClasses(refresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8BB0C),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_showingBranches) {
      return _buildBranchesList();
    } else {
      return _buildClassesList();
    }
  }

  Widget _buildBranchesList() {
    if (_branches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              color: Colors.white70,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No branches available',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBranches(refresh: true),
      color: const Color(0xFFF8BB0C),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _branches.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _branches.length) {
            return _buildLoadMoreButton();
          }
          return _buildBranchCard(_branches[index]);
        },
      ),
    );
  }

  Widget _buildClassesList() {
    if (_classes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              color: Colors.white70,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No classes available',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBranchClasses(refresh: true),
      color: const Color(0xFFF8BB0C),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _classes.length) {
            return _buildLoadMoreButton();
          }
          return _buildClassCard(_classes[index]);
        },
      ),
    );
  }

  Widget _buildBranchCard(BranchResponse branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF8BB0C),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectBranch(branch),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branch name
              Text(
                branch.branchName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Admin name
              _buildDetailRow(Icons.person, 'Admin', branch.adminName),
              
              // Location
              _buildDetailRow(Icons.location_on, 'Location', branch.location),
              
              // Email
              _buildDetailRow(Icons.email, 'Email', branch.email),
              
              // Phone
              _buildDetailRow(Icons.phone, 'Phone', branch.phoneNumber),
              
              const SizedBox(height: 12),
              
              // Classes count
              Text(
                '${branch.classes.length} classes available',
                style: const TextStyle(
                  color: Color(0xFFF8BB0C),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Tap to view classes hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.touch_app,
                    color: Color(0xFFF8BB0C),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tap to view classes',
                    style: TextStyle(
                      color: Color(0xFFF8BB0C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(BranchClassResponse classData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF8BB0C),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class name
            Text(
              classData.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            if (classData.description.isNotEmpty) ...[
              Text(
                classData.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Instructor
            _buildDetailRow(Icons.person, 'Instructor', classData.instructor),
            
            // Duration
            _buildDetailRow(Icons.schedule, 'Duration', '${classData.duration} minutes'),
            
            // Capacity
            _buildDetailRow(Icons.group, 'Capacity', '${classData.capacity} people'),
            
            const SizedBox(height: 12),
            
            // Schedule
            if (classData.schedule.isNotEmpty) ...[
              const Text(
                'Schedule:',
                style: TextStyle(
                  color: Color(0xFFF8BB0C),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatSchedule(classData.schedule),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleBookClass(classData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8BB0C),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Book Class',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFF8BB0C),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (!_hasMoreData) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _loadMoreData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF8BB0C),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text('Load More'),
        ),
      ),
    );
  }
}
