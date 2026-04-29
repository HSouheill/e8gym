import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/branch_user_models.dart';
import '../../utils/background_image_service.dart';

class BranchUsersPage extends StatefulWidget {
  final String accessToken;
  
  const BranchUsersPage({
    super.key,
    required this.accessToken,
  });

  @override
  State<BranchUsersPage> createState() => _BranchUsersPageState();
}

class _BranchUsersPageState extends State<BranchUsersPage> {
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _errorMessage;
  String? _backgroundImageUrl;
  
  // Users data
  List<BranchUserResponse> _users = [];
  BranchUserStatsResponse? _stats;
  
  // Search and filters
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  bool _hasMoreData = true;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _loadUsers();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBackgroundImage() async {
    final url = await BackgroundImageService.loadBackgroundImage(
      widget.accessToken,
      dashboardType: 'branch',
    );
    if (mounted && url != null && url.isNotEmpty) {
      setState(() {
        _backgroundImageUrl = url;
      });
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
      });
    }

    if (!_hasMoreData && !refresh) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getBranchUsers(
        widget.accessToken,
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        dateFrom: _dateFrom?.toIso8601String().split('T')[0],
        dateTo: _dateTo?.toIso8601String().split('T')[0],
      );

      if (result['success']) {
        try {
          print('API Response data: ${result['data']}');
          final userListResponse = BranchUserListResponse.fromJson(result['data']);
          
          setState(() {
            if (refresh) {
              _users = userListResponse.users;
            } else {
              _users.addAll(userListResponse.users);
            }
            _totalUsers = userListResponse.total;
            _totalPages = (userListResponse.total / _limit).ceil();
            _hasMoreData = _currentPage < _totalPages;
            _isLoading = false;
          });
        } catch (parseError) {
          setState(() {
            _errorMessage = 'Failed to parse user data: $parseError';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load users';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final result = await ApiService.getBranchUserStats(widget.accessToken);
      
      if (result['success']) {
        try {
          print('Stats API Response data: ${result['data']}');
          final stats = BranchUserStatsResponse.fromJson(result['data']);
          setState(() {
            _stats = stats;
            _isLoadingStats = false;
          });
        } catch (parseError) {
          print('Failed to parse stats data: $parseError');
          setState(() {
            _isLoadingStats = false;
          });
        }
      } else {
        print('Failed to load stats: ${result['message']}');
        setState(() {
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Network error loading stats: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _debounceSearch();
  }

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == _searchController.text) {
        _loadUsers(refresh: true);
      }
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFrom != null && _dateTo != null 
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      _loadUsers(refresh: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _dateFrom = null;
      _dateTo = null;
    });
    _loadUsers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                image: AssetImage('assets/background/background.png'),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 30),
              child: Column(
                children: [
                  // Header
                  Row(
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
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Branch Users',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _loadUsers(refresh: true),
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
                            Icons.refresh,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25), // Reduced spacing
                  
                  // Stats cards
                  if (_stats != null) 
                    _buildStatsCards()
                  else if (_isLoadingStats)
                    const SizedBox(
                      height: 130, // Updated to match stats cards height
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  
                  const SizedBox(height: 15), // Reduced spacing
                  
                  // Search and filters
                  _buildSearchAndFilters(),
                  
                  const SizedBox(height: 20),
                  
                  // Users list
                  Expanded(
                    child: _buildUsersList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return SizedBox(
      height: 130, // Increased height to accommodate text
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildStatCard(
            'Total Users',
            _stats!.totalUsers.toString(),
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Active Users',
            _stats!.activeUsers.toString(),
            Icons.person,
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'New This Month',
            _stats!.newUsersThisMonth.toString(),
            Icons.person_add,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Avg Bookings',
            _stats!.averageBookingsPerUser.toStringAsFixed(1),
            Icons.bookmark,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Adjusted padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Icon(icon, color: color, size: 22), // Slightly reduced icon size
          const SizedBox(height: 6), // Reduced spacing
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // Slightly reduced font size
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4), // Added spacing between value and title
          Flexible( // Wrapped in Flexible to handle text overflow
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11, // Slightly reduced font size
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Allow up to 2 lines
              overflow: TextOverflow.ellipsis, // Handle overflow gracefully
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search users by name or email...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Filters row
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dateFrom != null && _dateTo != null
                              ? '${DateFormat('MMM dd').format(_dateFrom!)} - ${DateFormat('MMM dd').format(_dateTo!)}'
                              : 'Date Range',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    if (_isLoading && _users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null && _users.isEmpty) {
      return Center(
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
              onPressed: () => _loadUsers(refresh: true),
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
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.white,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Users will appear here once they book classes at your branch',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Showing ${_users.length} of $_totalUsers users',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        
        // Users list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadUsers(refresh: true),
            child: ListView.builder(
              itemCount: _users.length + (_hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _users.length) {
                  return _buildLoadMoreButton();
                }
                return _buildUserCard(_users[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BranchUserResponse user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 25,
          child: Text(
            user.fullName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              '${user.countryCode} ${user.phoneNumber}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${user.totalBookings} bookings',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (user.lastBooked != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.schedule, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Last: ${DateFormat('MMM dd').format(user.lastBooked!)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
          onPressed: () => _viewUserDetails(user),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_hasMoreData) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _currentPage++;
            });
            _loadUsers();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Load More'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _viewUserDetails(BranchUserResponse user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchUserDetailPage(
          user: user,
          accessToken: widget.accessToken,
        ),
      ),
    );
  }
}

class BranchUserDetailPage extends StatefulWidget {
  final BranchUserResponse user;
  final String accessToken;
  
  const BranchUserDetailPage({
    super.key,
    required this.user,
    required this.accessToken,
  });

  @override
  State<BranchUserDetailPage> createState() => _BranchUserDetailPageState();
}

class _BranchUserDetailPageState extends State<BranchUserDetailPage> {
  String? _backgroundImageUrl;
  List<BranchUserBooking> _bookings = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreBookings = true;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _loadUserBookings();
  }

  Future<void> _loadBackgroundImage() async {
    final url = await BackgroundImageService.loadBackgroundImage(
      widget.accessToken,
      dashboardType: 'branch',
    );
    if (mounted && url != null && url.isNotEmpty) {
      setState(() {
        _backgroundImageUrl = url;
      });
    }
  }

  Future<void> _loadUserBookings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreBookings = true;
      });
    }

    if (!_hasMoreBookings && !refresh) return;

    try {
      final result = await ApiService.getBranchUserBookings(
        widget.user.userId,
        widget.accessToken,
        page: _currentPage,
        limit: _limit,
      );

      if (result['success']) {
        final bookingListResponse = BranchUserBookingListResponse.fromJson(result['data']);
        
        setState(() {
          if (refresh) {
            _bookings = bookingListResponse.bookings;
          } else {
            _bookings.addAll(bookingListResponse.bookings);
          }
          _totalPages = (bookingListResponse.total / _limit).ceil();
          _hasMoreBookings = _currentPage < _totalPages;
        });
      }
    } catch (e) {
      // Handle error silently for bookings
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                image: AssetImage('assets/background/background.png'),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 30),
              child: Column(
                children: [
                  // Header
                  Row(
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
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'User Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // User info card
                  _buildUserInfoCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Bookings section
                  Expanded(
                    child: _buildBookingsSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 40,
            child: Text(
              widget.user.fullName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem('Phone', '${widget.user.countryCode} ${widget.user.phoneNumber}'),
              _buildInfoItem('Bookings', widget.user.totalBookings.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _bookings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No bookings found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This user hasn\'t made any bookings yet',
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
                  itemCount: _bookings.length + (_hasMoreBookings ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _bookings.length) {
                      return _buildLoadMoreBookingsButton();
                    }
                    return _buildBookingCard(_bookings[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BranchUserBooking booking) {
    final displayClassName = booking.className.isNotEmpty
        ? booking.className
        : 'Class ${booking.classId.substring(0, booking.classId.length >= 6 ? 6 : booking.classId.length)}';
    final displayInstructor = booking.instructor.isNotEmpty ? booking.instructor : 'Not specified';
    final notesAvailable = booking.notes != null && booking.notes!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayClassName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Instructor: $displayInstructor',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('MMM dd, yyyy').format(booking.classDate)} at ${DateFormat('HH:mm').format(booking.startTime)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.bookmark, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'Booked on ${DateFormat('MMM dd, yyyy').format(booking.bookedAt)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          if (notesAvailable) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.notes!.trim(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildLoadMoreBookingsButton() {
    if (_hasMoreBookings) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _currentPage++;
            });
            _loadUserBookings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Load More Bookings'),
        ),
      );
    }
    return const SizedBox.shrink();
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
}
