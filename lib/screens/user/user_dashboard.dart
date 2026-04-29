import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../models/standalone_class_models.dart';
import '../../models/booking_models.dart';
import '../../models/branch_class_models.dart';
import '../../models/auth_models.dart';
import '../../widgets/user_sidebar.dart';
import 'user_profile_page.dart';
import 'change_password_page.dart';
import 'change_branch_page.dart';
import '../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';
import '../../utils/background_image_service.dart';

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
  
  // Booked classes tracking - allows multiple bookings per class
  // Key: "classId_scheduleId" or "classId_date_time", Value: booking ID
  Map<String, String> _bookingKeyToBookingId = {}; // Map booking key to booking ID
  List<BookingResponse> _allBookings = []; // Store all bookings for reference
  
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
      // Use centralized service to load user dashboard background
      final backgroundUrl = await BackgroundImageService.loadBackgroundImagePublic(
        dashboardType: 'user',
      );
      
      if (mounted && backgroundUrl != null && backgroundUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = backgroundUrl;
        });
      }
    } catch (e) {
      // Fallback to cached value on error
      final cachedUrl = await BackgroundImageService.getCachedBackgroundUrl(
        dashboardType: 'user',
      );
      if (mounted && cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
        });
      }
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

  Future<void> _handleUnauthorized() async {
    await _storageService.clearAuthData();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _initializePage() async {
    try {
      await _storageService.init();
      _accessToken = await _storageService.getAccessToken();
      if (_accessToken != null) {
        await _loadUserBranchClasses();
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
        if (result['statusCode'] == 401) {
          await _handleUnauthorized();
          return;
        }
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
      
      if (result['success'] == false && result['statusCode'] == 401) {
        await _handleUnauthorized();
        return;
      }
      if (result['success']) {
        final bookingsData = result['data'];
        
        // Parse using BookingListResponse model
        final bookingListResponse = BookingListResponse.fromJson(bookingsData);
        
        // Store all bookings and create mapping by composite key (classId + scheduleId)
        final bookingKeyMap = <String, String>{};
        final allBookingsList = <BookingResponse>[];
        
        for (var booking in bookingListResponse.bookings) {
          // Store all bookings (including cancelled for reference)
          allBookingsList.add(booking);
          
          // Only track active bookings (not cancelled)
          if (booking.status != 'cancelled' && booking.classId.isNotEmpty) {
            // Create composite key: classId_scheduleId
            final bookingKey = '${booking.classId}_${booking.scheduleId}';
            bookingKeyMap[bookingKey] = booking.id;
          }
        }
        
        setState(() {
          _bookingKeyToBookingId = bookingKeyMap;
          _allBookings = allBookingsList;
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
      final bookingIdMapJson = prefs.getString('booking_key_to_id_map');
      
      if (bookingIdMapJson != null) {
        final Map<String, dynamic> bookingIdMap = jsonDecode(bookingIdMapJson);
        setState(() {
          _bookingKeyToBookingId = bookingIdMap.map((key, value) => MapEntry(key.toString(), value.toString()));
        });
      }
    } catch (e) {
      print('Error loading booked classes from storage: $e');
    }
  }

  Future<void> _saveBookedClassesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('booking_key_to_id_map', jsonEncode(_bookingKeyToBookingId));
    } catch (e) {
      print('Error saving booked classes to storage: $e');
    }
  }

  // Get all bookings for a specific class
  List<BookingResponse> _getBookingsForClass(String classId) {
    return _allBookings.where((booking) => 
      booking.classId == classId && booking.status != 'cancelled'
    ).toList();
  }

  // Get booking ID for a specific schedule
  String? _getBookingIdForSchedule(String classId, String scheduleId) {
    final bookingKey = '${classId}_$scheduleId';
    return _bookingKeyToBookingId[bookingKey];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleCancelBooking(BranchClassResponse classData, String? scheduleId) async {
    if (_accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
        ),
      );
      return;
    }

    // If scheduleId is provided, cancel that specific booking
    // Otherwise, show dialog to select which booking to cancel
    String? bookingId;
    
    if (scheduleId != null) {
      bookingId = _getBookingIdForSchedule(classData.id, scheduleId);
    } else {
      // Show dialog to select which booking to cancel if multiple exist
      final bookings = _getBookingsForClass(classData.id);
      if (bookings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active bookings found for this class', style: TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
          ),
        );
        return;
      }
      
      if (bookings.length == 1) {
        bookingId = bookings.first.id;
      } else {
        // Show selection dialog for multiple bookings
        final selectedBooking = await _showBookingSelectionDialog(classData, bookings);
        if (selectedBooking == null) return;
        bookingId = selectedBooking.id;
      }
    }

    if (bookingId == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking ID not found. Please refresh and try again.', style: TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
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
                color: Colors.white,
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
              backgroundColor: AppColors.snackbarBackground,
              foregroundColor: Colors.black,
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
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );

    try {
      // Cancel booking using the update endpoint (PUT /api/bookings/:id)
      // This internally calls updateBooking with status: 'cancelled'
      final result = await ApiService.cancelBooking(bookingId, _accessToken!);

      Navigator.of(context).pop(); // Close loading dialog

      if (result['success']) {
        // Find and remove the cancelled booking from tracking
        final bookingToRemove = _allBookings.firstWhere(
          (b) => b.id == bookingId,
          orElse: () => _allBookings.first,
        );
        
        final bookingKey = '${bookingToRemove.classId}_${bookingToRemove.scheduleId}';
        setState(() {
          _bookingKeyToBookingId.remove(bookingKey);
          _allBookings.removeWhere((b) => b.id == bookingId);
        });
        await _saveBookedClassesToStorage();
        
        // Reload bookings to get updated list
        await _loadUserBookings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Booking for "${classData.name}" has been cancelled successfully',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to cancel booking', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: $e', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
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
        if (result['statusCode'] == 401) {
          await _handleUnauthorized();
          return;
        }
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
          content: Text('Authentication required', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
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
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: AppColors.snackbarBackground,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Validate required data
    if (_userBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch information is missing', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
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
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            content: Text(schedulesResult['message'] ?? 'Failed to load available schedules', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
          ),
        );
        return;
      }

      // Parse schedules response
      final schedulesData = ClassSchedulesResponse.fromJson(schedulesResult['data']);
      
      // Filter to only available schedules with available slots
      final availableSchedules = schedulesData.schedules
          .where((schedule) => schedule.isAvailable && !schedule.isPast && schedule.availableSlots > 0)
          .toList();

      if (availableSchedules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No available schedules for this class at the moment',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Check if all schedules have full capacity (availableSlots == 0)
      final allSchedulesFull = availableSchedules.every((schedule) => schedule.availableSlots == 0);
      if (allSchedulesFull) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Class capacity is full for "${classData.name}". All available time slots are fully booked.',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 4),
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
                  color: Colors.white,
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
                        color: Colors.white.withOpacity(0.3),
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
                              color: Colors.white,
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
                              color: Colors.white,
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

      // Check if selected schedule has available slots
      if (selectedSchedule.availableSlots == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Class capacity is full for this time slot. Please select another time.',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

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
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Instructor: ${schedulesData.instructor}',
                style: const TextStyle(
                  color: Colors.white,
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
                backgroundColor: Colors.white,
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );

      // Create booking request with selected schedule
      final bookingRequest = CreateBookingRequest(
        classId: classData.id,
        classType: 'branch',
        branchId: _userBranch!.id,
        branchLocation: _userBranch!.location,
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
              result['message'] ?? '${classData.name} booked successfully at ${_userBranch?.branchName}!',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Check if it's a booking conflict (same time slot)
        final errorMessage = result['message'] ?? 'Failed to book class';
        final isTimeConflict = errorMessage.toLowerCase().contains('conflict') ||
                              errorMessage.toLowerCase().contains('same time') ||
                              (errorMessage.toLowerCase().contains('already') && 
                               errorMessage.toLowerCase().contains('time'));
        
        if (isTimeConflict) {
          // Show custom popup for time conflict
          _showBookingConflictDialog(classData.name);
        } else {
          // Show regular error snackbar for other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.snackbarBackground,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking class: $e', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
        ),
      );
    }
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
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDevice = screenWidth >= 800;

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
              padding: EdgeInsets.symmetric(
                horizontal: isLargeDevice ? 20 : 16,
                vertical: isLargeDevice ? 12 : 10,
              ),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLargeDevice ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDevice ? 12 : 8,
                    vertical: isLargeDevice ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allSchedules.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLargeDevice ? 14 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 18,
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

  Future<BookingResponse?> _showBookingSelectionDialog(
    BranchClassResponse classData,
    List<BookingResponse> bookings,
  ) async {
    return await showDialog<BookingResponse>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Select Booking to Cancel',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(booking.classDate),
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
                        '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(booking.status),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pop(booking),
                ),
              );
            },
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
  }

  Future<void> _handleUpdateBooking(BookingResponse booking) async {
    if (_accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
        ),
      );
      return;
    }

    final TextEditingController notesController = TextEditingController(
      text: booking.notes ?? '',
    );
    String? selectedStatus = booking.status;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Update Booking',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class: ${booking.className}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('EEEE, MMM dd, yyyy').format(booking.classDate)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Time: ${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Status:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  items: ['confirmed', 'cancelled', 'completed', 'no_show']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(status.toUpperCase()),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notes:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                    hintText: 'Add notes...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ],
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'status': selectedStatus,
                  'notes': notesController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );

    try {
      final updateRequest = UpdateBookingRequest(
        status: result['status'] != booking.status ? result['status'] : null,
        notes: result['notes'] != (booking.notes ?? '') ? result['notes'] : null,
      );

      final updateResult = await ApiService.updateBooking(
        booking.id,
        updateRequest,
        _accessToken!,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (updateResult['success']) {
        // Reload bookings to get updated list
        await _loadUserBookings();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updateResult['message'] ?? 'Booking updated successfully',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updateResult['message'] ?? 'Failed to update booking', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating booking: $e', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
        ),
      );
    }
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
              backgroundColor: Colors.white,
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
  final size = MediaQuery.of(context).size;
  final width = size.width;

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
                width: (width * 0.75).clamp(220.0, 280.0),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDevice = screenWidth >= 900;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Menu Icon
          IconButton(
            onPressed: _toggleSidebar,
            icon: Icon(
              _isSidebarOpen ? Icons.menu_open : Icons.menu,
              color: Colors.white,
              size: 28,
            ),
            tooltip: _isSidebarOpen ? 'Hide Menu' : 'Show Menu',
          ),
          
          const SizedBox(width: 8),
          
          // Title
          Expanded(
            child: Text(
              _userBranch != null ? '${_userBranch!.branchName} Classes' : 'My Classes',
              style: TextStyle(
                color: Colors.white,
                fontSize: isLargeDevice ? 28 : 24,
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
              size: 28,
            ),
            tooltip: 'Refresh Classes',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDevice = screenWidth >= 800;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: TextField(
        controller: _classSearchController,
        onChanged: _onClassSearchChanged,
        style: TextStyle(
          color: Colors.white,
          fontSize: isLargeDevice ? 18 : 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search classes...',
          hintStyle: TextStyle(
            color: Colors.white70,
            fontSize: isLargeDevice ? 18 : 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white70,
            size: isLargeDevice ? 24 : 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDevice = screenWidth >= 800;
    if (_isLoading && _classes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: isLargeDevice ? 20 : 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadUserBranchClasses(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDevice = screenWidth >= 900;
    
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
              style: TextStyle(
                color: Colors.white70,
                fontSize: isLargeDevice ? 20 : 18,
              ),
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
                  backgroundColor: Colors.white,
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
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: filteredClasses.length,
        itemBuilder: (context, index) {
          return _buildClassCard(filteredClasses[index]);
        },
      ),
    );
  }


  Widget _buildClassCard(BranchClassResponse classData) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeDevice = screenSize.width >= 800;
    final imageHeight = (screenSize.height * 0.25).clamp(160.0, 220.0);

    final bookings = _getBookingsForClass(classData.id);
    final hasBookings = bookings.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBookings ? Colors.green : Colors.white,
          width: hasBookings ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Booked Badge - show count if multiple bookings
          if (hasBookings)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
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
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    bookings.length == 1
                        ? 'You have booked this class'
                        : 'You have ${bookings.length} bookings for this class',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: isLargeDevice ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Class Images
          if (classData.images.isNotEmpty) ...[
            Container(
              height: imageHeight,
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
                              color: Colors.white.withOpacity(0.3),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Booked indicator overlay on image
                  if (hasBookings)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          bookings.length > 1 ? bookings.length.toString() : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
                        color: Colors.white,
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
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class name
                Text(
                  classData.name,
                  style: TextStyle(
                    color: Colors.white,
                        fontSize: isLargeDevice ? 30 : 22,
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
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isLargeDevice ? 18 : 16,
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
                  Text(
                    'Schedule:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLargeDevice ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildGroupedSchedule(classData.schedule),
                ],
                
                const SizedBox(height: 16),
                
                // Show existing bookings if any
                if (hasBookings) ...[
                  Text(
                    'Your Bookings:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLargeDevice ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...bookings.map((booking) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(booking.classDate),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isLargeDevice ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isLargeDevice ? 16 : 14,
                                ),
                              ),
                              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  booking.notes!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: isLargeDevice ? 16 : 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontSize: isLargeDevice ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                          onPressed: () => _handleUpdateBooking(booking),
                          tooltip: 'Update booking',
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
                          onPressed: () => _handleCancelBooking(classData, booking.scheduleId),
                          tooltip: 'Cancel booking',
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                
                // Book button - always show, allowing multiple bookings
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleBookClass(classData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      hasBookings ? 'Book Another Time' : 'Book Class',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isLargeDevice ? 20 : 18,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDevice = screenWidth >= 900;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isLargeDevice ? 16 : 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isLargeDevice ? 16 : 14,
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
