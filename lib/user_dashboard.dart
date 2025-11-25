import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'models/standalone_class_models.dart';
import 'models/booking_models.dart';
import 'models/branch_class_models.dart';
import 'models/auth_models.dart';
import 'widgets/user_sidebar.dart';
import 'pages/user_profile_page.dart';
import 'pages/change_password_page.dart';
import 'pages/change_branch_page.dart';
import 'pages/medical_citations_page.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _errorMessage;
  String? _accessToken;
  String _currentPage = 'dashboard';
  bool _isSidebarOpen = true;
  
  // User's branch and classes data
  BranchResponse? _userBranch;
  List<BranchClassResponse> _classes = [];
  final TextEditingController _classSearchController = TextEditingController();
  String _classSearchQuery = '';
  
  // Booked classes tracking
  Set<String> _bookedClassIds = {};
  Map<String, String> _classIdToBookingId = {}; // Map class ID to booking ID for cancellation
  
  // BMI data
  BMIResponse? _userBMI;
  bool _isLoadingBMI = false;
  
  // User data
  UserResponse? _currentUser;
  
  // Background image
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      // First try to get from API
      final resp = await ApiService.getAppSettings('');
      if (resp['success'] == true) {
        final data = resp['data'];
        String? backgroundPath;
        
        // Extract background image path from various possible keys
        if (data is Map) {
          backgroundPath = data['background_image'] ?? 
                          data['BackgroundImage'] ?? 
                          data['backgroundImage'];
        }
        
        if (backgroundPath != null && backgroundPath.isNotEmpty) {
          // Normalize the URL (convert /app/ to /uploads/app/)
          String normalizedUrl = backgroundPath;
          if (backgroundPath.startsWith('app/')) {
            normalizedUrl = 'uploads/$backgroundPath';
          } else if (!backgroundPath.startsWith('http')) {
            normalizedUrl = backgroundPath.startsWith('/') ? backgroundPath : '/$backgroundPath';
          }
          
          final fullUrl = normalizedUrl.startsWith('http') 
              ? normalizedUrl 
              : 'https://e8gym.online/$normalizedUrl';
          
          if (mounted) {
            setState(() {
              _backgroundImageUrl = fullUrl;
            });
          }
          
          // Cache the URL for future use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_background_url', fullUrl);
          return;
        }
      }
      
      // Fallback to cached value if API didn't return a background
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('app_background_url');
      if (mounted && cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
        });
      }
    } catch (e) {
      // Fallback to cached value on error
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedUrl = prefs.getString('app_background_url');
        if (mounted && cachedUrl != null && cachedUrl.isNotEmpty) {
          setState(() {
            _backgroundImageUrl = cachedUrl;
          });
        }
      } catch (_) {
        // Ignore errors, fallback to default background
      }
    }
  }

  @override
  void dispose() {
    _classSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    try {
      await _storageService.init();
      _accessToken = await _storageService.getAccessToken();
      if (_accessToken != null) {
        await _loadUserBranchClasses();
        await _loadUserBMI();
        await _loadCurrentUser();
        await _loadUserBookings();
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

  Future<void> _loadCurrentUser() async {
    if (_accessToken == null) return;

    try {
      final result = await ApiService.getUserProfile(_accessToken!);
      
      if (result['success'] && result['data'] != null) {
        final userData = UserResponse.fromJson(result['data']);
        setState(() {
          _currentUser = userData;
        });
      } else {
        print('Failed to load user profile: ${result['message']}');
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadUserBookings() async {
    if (_accessToken == null) return;

    try {
      // Get user bookings from API
      final result = await ApiService.getUserBookings(_accessToken!);
      
      if (result['success']) {
        final bookingsData = result['data'];
        
        // Parse using BookingListResponse model
        final bookingListResponse = BookingListResponse.fromJson(bookingsData);
        
        // Extract class IDs and booking IDs from bookings (only active/confirmed bookings)
        final bookedIds = <String>{};
        final classToBookingMap = <String, String>{};
        for (var booking in bookingListResponse.bookings) {
          // Only count bookings that are not cancelled
          if (booking.status != 'cancelled' && booking.classId.isNotEmpty) {
            bookedIds.add(booking.classId);
            classToBookingMap[booking.classId] = booking.id;
          }
        }
        
        setState(() {
          _bookedClassIds = bookedIds;
          _classIdToBookingId = classToBookingMap;
        });
        await _saveBookedClassesToStorage();
      } else {
        // If API call fails, try to load from local storage as fallback
        await _loadBookedClassesFromStorage();
      }
    } catch (e) {
      print('Error loading user bookings: $e');
      // Fallback to local storage
      await _loadBookedClassesFromStorage();
    }
  }

  Future<void> _loadBookedClassesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookedIdsJson = prefs.getString('booked_class_ids');
      final bookingIdMapJson = prefs.getString('class_booking_id_map');
      
      if (bookedIdsJson != null) {
        final List<dynamic> bookedIds = jsonDecode(bookedIdsJson);
        setState(() {
          _bookedClassIds = bookedIds.map((id) => id.toString()).toSet();
        });
      }
      
      if (bookingIdMapJson != null) {
        final Map<String, dynamic> bookingIdMap = jsonDecode(bookingIdMapJson);
        setState(() {
          _classIdToBookingId = bookingIdMap.map((key, value) => MapEntry(key.toString(), value.toString()));
        });
      }
    } catch (e) {
      print('Error loading booked classes from storage: $e');
    }
  }

  Future<void> _saveBookedClassesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('booked_class_ids', jsonEncode(_bookedClassIds.toList()));
      await prefs.setString('class_booking_id_map', jsonEncode(_classIdToBookingId));
    } catch (e) {
      print('Error saving booked classes to storage: $e');
    }
  }

  bool _isClassBooked(String classId) {
    return _bookedClassIds.contains(classId);
  }

  Future<void> _handleCancelBooking(BranchClassResponse classData) async {
    if (_accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get booking ID for this class
    final bookingId = _classIdToBookingId[classData.id];
    if (bookingId == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking ID not found. Please refresh and try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Cancel Booking',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your booking for "${classData.name}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${_userBranch?.branchName}',
              style: const TextStyle(
                color: Color(0xFFF8BB0C),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. You will need to book again if you change your mind.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Keep Booking',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

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
      final result = await ApiService.cancelBooking(bookingId, _accessToken!);

      Navigator.of(context).pop(); // Close loading dialog

      if (result['success']) {
        // Remove class ID from booked classes
        setState(() {
          _bookedClassIds.remove(classData.id);
          _classIdToBookingId.remove(classData.id);
        });
        await _saveBookedClassesToStorage();
        
        // Reload bookings to get updated list
        await _loadUserBookings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Booking for "${classData.name}" has been cancelled successfully'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to cancel booking'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _onPageChanged(String page) {
    setState(() {
      _currentPage = page;
    });

    switch (page) {
      case 'profile':
        _navigateToProfile();
        break;
      case 'change_branch':
        _navigateToChangeBranch();
        break;
      case 'change_password':
        _navigateToChangePassword();
        break;
      case 'bmi':
        _showBMICalculator();
        break;
      case 'dashboard':
      default:
        // Already on dashboard
        break;
    }
  }

  Future<void> _navigateToProfile() async {
    if (_accessToken == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          accessToken: _accessToken!,
          currentUser: _currentUser,
        ),
      ),
    );

    // If user data was updated, refresh the current user
    if (result != null && result is UserResponse) {
      setState(() {
        _currentUser = result;
      });
    }
  }

  Future<void> _navigateToChangeBranch() async {
    if (_accessToken == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeBranchPage(
          accessToken: _accessToken!,
          currentBranch: _userBranch,
        ),
      ),
    );

    // If branch was changed, refresh the branch data
    if (result != null && result is BranchResponse) {
      setState(() {
        _userBranch = result;
      });
      // Reload classes for the new branch
      await _loadUserBranchClasses();
    }
  }

  Future<void> _navigateToChangePassword() async {
    if (_accessToken == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordPage(
          accessToken: _accessToken!,
        ),
      ),
    );
  }

  Future<void> _loadUserBranchClasses({bool refresh = false}) async {
    if (_accessToken == null) return;

    if (!refresh) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('=== Loading User Branch Classes ===');
      final result = await ApiService.getUserBranchClasses(_accessToken!);
      print('User branch classes response: $result');
      print('Response success: ${result['success']}');
      print('Response data: ${result['data']}');

      if (result['success']) {
        final data = result['data'];
        print('Data type: ${data.runtimeType}');
        print('Data keys: ${data is Map ? data.keys.toList() : 'Not a map'}');
        
        if (data == null) {
          setState(() {
            _errorMessage = 'No data received from server';
            _isLoading = false;
            _classes = [];
          });
          return;
        }
        
        // Handle different possible data structures
        String? branchId;
        String? branchName;
        String? location;
        List? classesList;
        
        if (data is Map) {
          branchId = data['branch_id']?.toString() ?? data['branchId']?.toString();
          branchName = data['branch_name'] ?? data['branchName'] ?? data['branch_name'];
          location = data['location'] ?? data['Location'];
          classesList = data['classes'] is List ? data['classes'] as List : null;
          
          print('Branch ID: $branchId');
          print('Branch Name: $branchName');
          print('Location: $location');
          print('Classes list: $classesList');
          print('Classes count: ${classesList?.length ?? 0}');
        }
        
        // Create branch response from the data
        final branchData = {
          'id': branchId ?? '',
          'branch_name': branchName ?? 'Unknown Branch',
          'location': location ?? '',
          'admin_name': '', // Not provided by this endpoint
          'email': '', // Not provided by this endpoint
          'phone_number': '', // Not provided by this endpoint
          'classes': classesList ?? [],
          'team_members': [], // Not provided by this endpoint
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'created_by': '', // Not provided by this endpoint
        };
        
        final branch = BranchResponse.fromJson(branchData);
        final classes = <BranchClassResponse>[];
        
        if (classesList != null && classesList.isNotEmpty) {
          for (var i = 0; i < classesList.length; i++) {
            try {
              final classData = classesList[i];
              print('Parsing class $i: $classData');
              final branchClass = BranchClassResponse.fromJson(classData);
              classes.add(branchClass);
              print('Successfully parsed class: ${branchClass.name}');
            } catch (e) {
              print('Error parsing class $i: $e');
              print('Class data: ${classesList[i]}');
            }
          }
        }

        setState(() {
          _userBranch = branch;
          _classes = classes;
          _isLoading = false;
          _errorMessage = null;
        });
        
        print('User branch loaded: ${branch.branchName} with ${classes.length} classes');
      } else {
        final errorMsg = result['message'] ?? 'Failed to load your branch classes';
        print('Failed to load classes: $errorMsg');
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
          _classes = [];
        });
      }
    } catch (e, stackTrace) {
      print('Exception loading user branch classes: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
        _classes = [];
      });
    }
  }

  void _onClassSearchChanged(String query) {
    setState(() {
      _classSearchQuery = query;
    });
    
    // Filter classes based on search query
    // Since we're not paginating anymore, we can filter locally
  }

  List<BranchClassResponse> _getFilteredClasses() {
    // Filter out expired classes and hidden classes (client-side fallback)
    // Backend should already filter by visibility, but this ensures hidden classes don't show
    final activeClasses = _classes.where((classData) {
      // Hide if expired
      if (classData.hasExpired) return false;
      // Hide if visibility is explicitly set to false
      if (classData.isVisible == false) return false;
      // Show if visible is true or null (default to visible)
      return true;
    }).toList();
    
    // Sort by createdAt in descending order (newest first)
    activeClasses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Then apply search filter if there's a query
    if (_classSearchQuery.isEmpty) {
      return activeClasses;
    }
    
    final filtered = activeClasses.where((classData) {
      return classData.name.toLowerCase().contains(_classSearchQuery.toLowerCase()) ||
             classData.description.toLowerCase().contains(_classSearchQuery.toLowerCase()) ||
             classData.instructor.toLowerCase().contains(_classSearchQuery.toLowerCase());
    }).toList();
    
    // Maintain sort order after filtering
    return filtered;
  }
  
  /// Get count of expired classes
  int _getExpiredClassesCount() {
    return _classes.where((classData) => classData.hasExpired).length;
  }

  Future<void> _handleLogout() async {
    try {
      // Set the auth token before calling logout
      if (_accessToken != null) {
        _authService.setAuthToken(_accessToken!);
      }
      
      await _authService.logout();
      await _storageService.clearAuthData();
      
      if (mounted) {
        // Navigate back to the main login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      // Even if logout API fails, clear local data
      try {
        await _storageService.clearAuthData();
      } catch (clearError) {
        print('Error clearing auth data: $clearError');
      }
      
      if (mounted) {
        // Navigate back to the main login page even if logout API fails
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
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

    // Check if class has expired
    if (classData.hasExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            classData.expiresAt != null
                ? 'This class expired on ${DateFormat('MMM dd, yyyy').format(classData.expiresAt!)}'
                : 'This class has expired and is no longer available for booking',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Validate required data
    if (_userBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch information is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator while fetching schedules
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
      // Fetch available schedules for this class
      final schedulesResult = await ApiService.getClassSchedules(
        classData.id,
        'branch',
        _userBranch!.id,
        _accessToken!,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (!schedulesResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(schedulesResult['message'] ?? 'Failed to load available schedules'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Parse schedules response
      final schedulesData = ClassSchedulesResponse.fromJson(schedulesResult['data']);
      
      // Filter to only available schedules
      final availableSchedules = schedulesData.schedules
          .where((schedule) => schedule.isAvailable && !schedule.isPast)
          .toList();

      if (availableSchedules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available schedules for this class at the moment'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Show schedule selection dialog
      final selectedSchedule = await showDialog<ClassScheduleAvailability>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Schedule',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                classData.name,
                style: const TextStyle(
                  color: Color(0xFFF8BB0C),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Instructor: ${schedulesData.instructor}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: availableSchedules.map((schedule) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF8BB0C).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(schedule.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('HH:mm').format(schedule.startTime)} - ${DateFormat('HH:mm').format(schedule.endTime)}',
                            style: const TextStyle(
                              color: Color(0xFFF8BB0C),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${schedule.availableSlots} of ${schedulesData.capacity} slots available',
                            style: TextStyle(
                              color: schedule.availableSlots > 0
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: schedule.isAvailable
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFFF8BB0C),
                            )
                          : const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                      onTap: schedule.isAvailable
                          ? () => Navigator.of(context).pop(schedule)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );

      if (selectedSchedule == null) return;

      // Show confirmation dialog
      final shouldBook = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Confirm Booking',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class: ${classData.name}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${DateFormat('EEEE, MMM dd, yyyy').format(selectedSchedule.date)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Time: ${DateFormat('HH:mm').format(selectedSchedule.startTime)} - ${DateFormat('HH:mm').format(selectedSchedule.endTime)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${_userBranch?.branchName}',
                style: const TextStyle(
                  color: Color(0xFFF8BB0C),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Instructor: ${schedulesData.instructor}',
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
              child: const Text('Confirm Booking'),
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

      // Create booking request with selected schedule
      final bookingRequest = CreateBookingRequest(
        classId: classData.id,
        classType: 'branch',
        branchId: _userBranch!.id,
        scheduleId: selectedSchedule.scheduleId,
        classDate: selectedSchedule.date,
        startTime: selectedSchedule.startTime,
        endTime: selectedSchedule.endTime,
      );

      final result = await ApiService.createBooking(bookingRequest, _accessToken!);

      Navigator.of(context).pop(); // Close loading dialog

      if (result['success']) {
        // Reload bookings to get the booking ID
        await _loadUserBookings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? '${classData.name} booked successfully at ${_userBranch?.branchName}!'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Check if it's a booking conflict (already booked)
        final errorMessage = result['message'] ?? 'Failed to book class';
        final isBookingConflict = errorMessage.toLowerCase().contains('already') || 
                                 errorMessage.toLowerCase().contains('booked') ||
                                 errorMessage.toLowerCase().contains('conflict') ||
                                 errorMessage.toLowerCase().contains('duplicate');
        
        if (isBookingConflict) {
          // Show custom popup for booking conflict
          _showBookingConflictDialog(classData.name);
        } else {
          // Show regular error snackbar for other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
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


  String _formatTime(DateTime time) {
    // Display UTC time directly without timezone conversion
    return DateFormat('HH:mm').format(time);
  }

  String _formatSchedule(List<ClassSchedule> schedule) {
    if (schedule.isEmpty) return 'No schedule available';
    
    // Group schedules by date to show complete date information
    final scheduleStrings = schedule.map((s) {
      final dateStr = DateFormat('EEEE, d MMMM yyyy').format(s.date);
      final timeRange = '${_formatTime(s.startTime)}-${_formatTime(s.endTime)}';
      return '$dateStr: $timeRange';
    }).toList();
    
    return scheduleStrings.join('\n');
  }

  // BMI Methods
  Future<void> _loadUserBMI() async {
    if (_accessToken == null) return;

    setState(() {
      _isLoadingBMI = true;
    });

    try {
      final result = await ApiService.getUserBMI(_accessToken!);
      
      if (result['success']) {
        final bmiData = BMIResponse.fromJson(result['data']);
        setState(() {
          _userBMI = bmiData;
          _isLoadingBMI = false;
        });
      } else {
        // BMI data not available or incomplete
        setState(() {
          _userBMI = null;
          _isLoadingBMI = false;
        });
      }
    } catch (e) {
      setState(() {
        _userBMI = null;
        _isLoadingBMI = false;
      });
    }
  }

  Future<void> _showBMICalculator() async {
    final TextEditingController heightController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    
    // Pre-fill with existing data if available
    if (_userBMI != null) {
      heightController.text = _userBMI!.height.toString();
      weightController.text = _userBMI!.weight.toString();
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'BMI Calculator',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Enter your height in centimeters',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF8BB0C)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF8BB0C), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Enter your weight in kilograms',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF8BB0C)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF8BB0C), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Medical Citation Link
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MedicalCitationsPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[300],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'View medical information sources',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final height = double.tryParse(heightController.text);
              final weight = double.tryParse(weightController.text);
              
              if (height == null || weight == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid height and weight'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (height < 50 || height > 300) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Height must be between 50 and 300 cm'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (weight < 20 || weight > 500) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weight must be between 20 and 500 kg'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop({
                'height': height,
                'weight': weight,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8BB0C),
              foregroundColor: Colors.black,
            ),
            child: const Text('Calculate BMI'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _calculateAndUpdateBMI(result['height'], result['weight']);
    }
  }

  Future<void> _calculateAndUpdateBMI(double height, double weight) async {
    if (_accessToken == null) return;

    // Show loading dialog
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
      // Update user BMI data
      final result = await ApiService.updateUserBMI(height, weight, _accessToken!);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (result['success']) {
        final bmiData = BMIResponse.fromJson(result['data']);
        setState(() {
          _userBMI = bmiData;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BMI updated successfully! Your BMI is ${bmiData.bmi.toStringAsFixed(1)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update BMI'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating BMI: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue; // Underweight
    if (bmi < 25) return Colors.green; // Normal
    if (bmi < 30) return Colors.orange; // Overweight
    return Colors.red; // Obese
  }

  void _showBookingConflictDialog(String className) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Already Booked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'You are already booked for "$className".',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can\'t book the same class twice. Please check your existing bookings or choose a different class.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To view your bookings, go to your profile or check the bookings section.',
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8BB0C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Main Content - always takes full width
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Stack(
            children: [
              // Static background fallback
              Container(
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
              ),
              // Dynamic background overlay
              if (_backgroundImageUrl != null)
                Positioned.fill(
                  child: Image.network(
                    _backgroundImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // If network image fails, show nothing (fallback to static background)
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              // Dark overlay
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x50000000),
                ),
              ),
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    // Search bar
                    _buildSearchBar(),
                    // BMI Section
                    _buildBMISection(),
                    // Content
                    Expanded(
                      child: ClipRect(
                        child: _buildContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Overlay background when sidebar is open
        if (_isSidebarOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        // Sidebar - overlay when open
        if (_isSidebarOpen)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {}, // Prevent taps from bubbling up to close sidebar
              child: Container(
                width: 280,
                child: UserSidebar(
                  currentPage: _currentPage,
                  onPageChanged: _onPageChanged,
                  onLogout: _handleLogout,
                ),
              ),
            ),
          ),
      ], // This closing bracket was missing
    ),
  );
}

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Menu Icon
          IconButton(
            onPressed: _toggleSidebar,
            icon: Icon(
              _isSidebarOpen ? Icons.menu_open : Icons.menu,
              color: const Color(0xFFF8BB0C),
              size: 28,
            ),
            tooltip: _isSidebarOpen ? 'Hide Menu' : 'Show Menu',
          ),
          
          const SizedBox(width: 8),
          
          // Title
          Expanded(
            child: Text(
              _userBranch != null ? '${_userBranch!.branchName} Classes' : 'My Classes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Refresh Icon
          IconButton(
            onPressed: () => _loadUserBranchClasses(refresh: true),
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Refresh Classes',
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
        controller: _classSearchController,
        onChanged: _onClassSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search classes...',
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBMISection() {
    if (_isLoadingBMI) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF8BB0C), width: 1),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF8BB0C), width: 1),
      ),
      child: _userBMI != null ? _buildBMIInfo() : _buildBMIEmpty(),
    );
  }

  Widget _buildBMIInfo() {
    final bmiColor = _getBMIColor(_userBMI!.bmi);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // BMI Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bmiColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: bmiColor, width: 2),
            ),
            child: Icon(
              Icons.monitor_weight,
              color: bmiColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // BMI Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI: ${_userBMI!.bmi.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: bmiColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userBMI!.category,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_userBMI!.height.toStringAsFixed(0)}cm • ${_userBMI!.weight.toStringAsFixed(1)}kg',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MedicalCitationsPage(),
                      ),
                    );
                  },
                  child: Text(
                    'View medical sources',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontSize: 10,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Update Button
          GestureDetector(
            onTap: _showBMICalculator,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8BB0C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIEmpty() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFF8BB0C), width: 2),
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              color: Color(0xFFF8BB0C),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calculate Your BMI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Track your health and fitness progress',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Calculate Button
          GestureDetector(
            onTap: _showBMICalculator,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Calculate',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _classes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
        ),
      );
    }

    if (_errorMessage != null && _classes.isEmpty) {
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
              onPressed: () => _loadUserBranchClasses(refresh: true),
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

    return _buildClassesList();
  }

  Widget _buildClassesList() {
    final filteredClasses = _getFilteredClasses();
    final expiredCount = _getExpiredClassesCount();
    
    if (filteredClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center,
              color: Colors.white70,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _classSearchQuery.isNotEmpty 
                ? 'No classes found matching "$_classSearchQuery"'
                : expiredCount > 0 && _classes.isNotEmpty
                  ? 'All classes at ${_userBranch?.branchName ?? "your branch"} have expired'
                  : 'No classes available at ${_userBranch?.branchName ?? "your branch"}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (expiredCount > 0 && _classes.isNotEmpty && _classSearchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$expiredCount ${expiredCount == 1 ? 'class has' : 'classes have'} expired and ${expiredCount == 1 ? 'has' : 'have'} been removed from the list.',
                        style: TextStyle(
                          color: Colors.orange.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_classSearchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _classSearchController.clear();
                  _onClassSearchChanged('');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8BB0C),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserBranchClasses(refresh: true);
        await _loadUserBookings();
      },
      color: const Color(0xFFF8BB0C),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredClasses.length,
        itemBuilder: (context, index) {
          return _buildClassCard(filteredClasses[index]);
        },
      ),
    );
  }


  Widget _buildClassCard(BranchClassResponse classData) {
    final isBooked = _isClassBooked(classData.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBooked ? Colors.green : const Color(0xFFF8BB0C),
          width: isBooked ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Booked Badge
          if (isBooked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'You have booked this class',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Class Images
          if (classData.images.isNotEmpty) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: PageView.builder(
                      itemCount: classData.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          classData.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF8BB0C).withOpacity(0.3),
                              child: const Center(
                                child: Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.white.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Booked indicator overlay on image
                  if (isBooked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Image indicators
            if (classData.images.length > 1) ...[
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    classData.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8BB0C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          
          // Class content
          Padding(
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Book/Cancel button
                if (isBooked)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleCancelBooking(classData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Cancel Booking',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
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
        ],
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
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

}
