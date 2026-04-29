import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/background_image_service.dart';

class SuperAdminBookingsPage extends StatefulWidget {
  final String accessToken;
  
  const SuperAdminBookingsPage({
    super.key,
    required this.accessToken,
  });

  @override
  State<SuperAdminBookingsPage> createState() => _SuperAdminBookingsPageState();
}

class _SuperAdminBookingsPageState extends State<SuperAdminBookingsPage> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  
  // Pagination
  int _currentPage = 1;
  int _totalClasses = 0;
  int _limit = 20;
  bool _hasMoreData = true;
  
  // Background image
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _loadBookings();
  }

  Future<void> _loadBookings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _classes.clear();
        _hasMoreData = true;
      });
    }

    if (!_hasMoreData && !refresh) return;

    setState(() {
      _isLoading = refresh;
      _isLoadingMore = !refresh;
    });

    try {
      final result = await ApiService.getAdminBookings(
        widget.accessToken,
        page: _currentPage,
        limit: _limit,
      );

      if (result['success']) {
        final data = result['data'];
        if (data != null) {
          final classes = (data['classes'] as List).cast<Map<String, dynamic>>();
          
          final total = data['total'] ?? 0;
          final page = data['page'] ?? 1;
          final limit = data['limit'] ?? 20;

          setState(() {
            if (refresh) {
              _classes = classes;
            } else {
              _classes.addAll(classes);
            }
            _totalClasses = total;
            _currentPage = page;
            _limit = limit;
            _hasMoreData = _classes.length < total;
          });
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to load bookings');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreBookings() async {
    if (_hasMoreData && !_isLoadingMore) {
      setState(() {
        _currentPage++;
      });
      await _loadBookings();
    }
  }

  Future<void> _loadBackgroundImage() async {
    final url = await BackgroundImageService.loadBackgroundImage(
      widget.accessToken,
      dashboardType: 'superadmin',
    );
    if (mounted && url != null && url.isNotEmpty) {
      setState(() {
        _backgroundImageUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Base gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white70],
              ),
            ),
          ),
          
          // Static background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/E8Logos/admin_dashboard_background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Dynamic background image overlay
          if (_backgroundImageUrl != null)
            Positioned.fill(
              child: Image.network(
                _backgroundImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          
          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0x50000000),
              ),
            ),
          ),
          
          // Main content
          Column(
          children: [
            // Classes List
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.book_online, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Classes with Bookings (${_totalClasses})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Classes List
                    Expanded(
                      child: _isLoading && _classes.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : _classes.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No classes with bookings found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () => _loadBookings(refresh: true),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    itemCount: _classes.length + (_hasMoreData ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _classes.length) {
                                        // Load more indicator
                                        if (_isLoadingMore) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      }

                                      final classData = _classes[index];
                                      return _buildClassCard(classData);
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    final className = classData['class_name'] ?? 'Unknown Class';
    final instructor = classData['instructor'] ?? 'Unknown Instructor';
    final capacity = classData['capacity'] ?? 0;
    final totalBookings = classData['total_bookings'] ?? 0;
    final bookedUsers = (classData['booked_users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isActive = classData['is_active'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.fitness_center,
            color: Colors.black,
            size: 24,
          ),
        ),
        title: Text(
          className,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Instructor: $instructor',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bookings: $totalBookings / $capacity',
              style: TextStyle(
                color: totalBookings >= capacity ? Colors.red : Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.expand_more,
          color: Colors.grey[600],
        ),
        children: [
          if (bookedUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No bookings for this class',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookedUsers.length,
              itemBuilder: (context, index) {
                final user = bookedUsers[index];
                return _buildUserBookingCard(user);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUserBookingCard(Map<String, dynamic> userData) {
    final userName = userData['full_name'] ?? 'Unknown User';
    final email = userData['email'] ?? 'No email';
    final phone = userData['phone_number'] ?? 'No phone';
    final bookingStatus = userData['booking_status'] ?? 'unknown';
    final bookedAt = userData['booked_at'] != null 
        ? DateTime.parse(userData['booked_at'])
        : null;
    final classDate = userData['class_date'] != null 
        ? DateTime.parse(userData['class_date'])
        : null;
    final startTime = userData['start_time'] != null 
        ? DateTime.parse(userData['start_time'])
        : null;
    final endTime = userData['end_time'] != null 
        ? DateTime.parse(userData['end_time'])
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(bookingStatus),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bookingStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booked: ${_formatDateTime(bookedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (classDate != null)
                      Text(
                        'Class Date: ${_formatDate(classDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (startTime != null && endTime != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Time: ${_formatTime(startTime)} - ${_formatTime(endTime)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    // Convert UTC time to local time for display
    final localTime = dateTime.toLocal();
    return '${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}';
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
}
