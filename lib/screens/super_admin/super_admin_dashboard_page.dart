import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/auth_models.dart';
import '../../utils/secure_logger.dart';
import '../../utils/app_colors.dart';
import '../../utils/background_image_service.dart';
import 'create_branch_page.dart';
import 'standalone_classes_page.dart';
import '../admin_login_page.dart';
import '../branch/branch_detail_page.dart';
import 'edit_branch_page.dart';
import 'super_admin_users_page.dart';
import 'super_admin_bookings_page.dart';
import 'super_admin_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  final String accessToken;
  final String userEmail;
  
  const SuperAdminDashboardPage({
    super.key,
    required this.accessToken,
    required this.userEmail,
  });

  @override
  State<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  List<BranchResponse> _branches = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalBranches = 0;
  int _limit = 20;
  bool _hasMorePages = true;
  bool _isSidebarOpen = false;
  bool _isLoggingOut = false;
  String? _backgroundImageUrl;
  bool _showStats = false; // Track if stats are visible
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _scrollController.addListener(_onScroll);
    
    // Initialize storage service and check token
    _initializeStorage();
    _loadBackgroundImage();
  }

  Future<void> _initializeStorage() async {
    try {
      await _storageService.init();
      final storedToken = await _storageService.getAccessToken();
      SecureLogger.debug('Storage initialization', data: {
        'stored_token_available': storedToken != null,
        'stored_token_length': storedToken?.length ?? 0,
        'widget_token_length': widget.accessToken.length,
      });
    } catch (e) {
      SecureLogger.error('Error initializing storage', error: e);
    }
  }

  Future<void> _loadBackgroundImage() async {
    try {
      // Use centralized service to load superadmin dashboard background
      final backgroundUrl = await BackgroundImageService.loadBackgroundImage(
        widget.accessToken,
        dashboardType: 'superadmin',
      );
      
      if (mounted && backgroundUrl != null && backgroundUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = backgroundUrl;
        });
      }
    } catch (e) {
      // Fallback to cached value on error
      final cachedUrl = await BackgroundImageService.getCachedBackgroundUrl(
        dashboardType: 'superadmin',
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMorePages && !_isLoading) {
        _loadMoreBranches();
      }
    }
  }

  Future<void> _loadBranches({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _branches.clear();
        _hasMorePages = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await ApiService.getBranches(
        widget.accessToken,
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (result['success']) {
        final data = result['data'];
        print('=== API Response Debug ===');
        print('Raw API data: $data');
        print('Data type: ${data.runtimeType}');
        if (data is Map && data.containsKey('branches')) {
          print('Branches count: ${(data['branches'] as List).length}');
          for (int i = 0; i < (data['branches'] as List).length; i++) {
            final branch = data['branches'][i];
            print('Branch $i: ${branch['branch_name']} - Image: ${branch['image']}');
          }
        }
        print('========================');
        
        final branchListResponse = BranchListResponse.fromJson(data);
        
        setState(() {
          if (refresh) {
            _branches = branchListResponse.branches;
          } else {
            _branches.addAll(branchListResponse.branches);
          }
          _totalBranches = branchListResponse.total;
          _currentPage = branchListResponse.page;
          _limit = branchListResponse.limit;
          _hasMorePages = _branches.length < branchListResponse.total;
        });
      } else {
        if (!refresh) {
          _showSnackBar(result['message'] ?? 'Failed to load branches');
        }
      }
    } catch (e) {
      if (!refresh) {
        _showSnackBar('An error occurred: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreBranches() async {
    if (_isLoading || !_hasMorePages) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.getBranches(
        widget.accessToken,
        page: _currentPage + 1,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (result['success']) {
        final data = result['data'];
        final branchListResponse = BranchListResponse.fromJson(data);

        setState(() {
          _branches.addAll(branchListResponse.branches);
          _totalBranches = branchListResponse.total;
          _currentPage = branchListResponse.page;
          _hasMorePages = _branches.length < branchListResponse.total;
        });
      } else {
        _showSnackBar(result['message'] ?? 'Failed to load more branches');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _debounceSearch();
  }

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == _searchController.text) {
        _loadBranches(refresh: true);
      }
    });
  }

  Future<void> _navigateToStandaloneClasses() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StandaloneClassesPage(
          accessToken: widget.accessToken,
        ),
      ),
    );
    
    // Refresh branches if classes were modified (which might affect branch stats)
    if (result == true) {
      _loadBranches(refresh: true);
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Debug: Check token before logout
      print('=== Logout Debug ===');
      print('Access Token from widget: ${widget.accessToken}');
      print('Token length: ${widget.accessToken.length}');
      print('Token starts with Bearer: ${widget.accessToken.startsWith('Bearer ')}');
      
      // Get stored token for comparison
      final storedToken = await _storageService.getAccessToken();
      SecureLogger.debug('Logout token check', data: {
        'stored_token_available': storedToken != null,
        'widget_token_length': widget.accessToken.length,
      });
      
      // Use stored token if available, otherwise use widget token
      final tokenToUse = storedToken ?? widget.accessToken;
      
      // Try to call logout API, but don't fail if it doesn't work
      try {
        final result = await ApiService.superAdminLogout(tokenToUse);
        print('Logout API result: ${result['success']}');
      } catch (e) {
        print('Logout API failed, but continuing with local logout: $e');
      }
      
      // Always clear stored auth data regardless of API response
      await _storageService.clearAuthData();
      print('Local auth data cleared successfully');
      
      if (mounted) {
        // Navigate back to admin login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AdminLoginPage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout process: $e');
      // Even if there's an error, try to clear local data and navigate
      try {
        await _storageService.clearAuthData();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AdminLoginPage(),
            ),
            (route) => false,
          );
        }
      } catch (clearError) {
        print('Error clearing auth data: $clearError');
        if (mounted) {
          _showSnackBar('An error occurred during logout: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }


  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLargeDevice,
  }) {
    final bool isDisabled = title == 'Logging out...';
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
              ? const Color(0xFF926E07) 
              : isDisabled 
                  ? Colors.grey[400] 
                  : Colors.grey[600],
          size: isLargeDevice ? 26 : 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected 
                ? const Color(0xFF926E07) 
                : isDisabled 
                    ? Colors.grey[400] 
                    : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: isLargeDevice ? 18 : 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabled: !isDisabled,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minLeadingWidth: 24,
        dense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width ;
    final isLargeDevice = screenWidth >= 800; // e.g. iPad 13-inch

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white70],
          ),
        ),
        child: Stack(
          children: [
            // Static background fallback
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/E8Logos/admin_dashboard_background.jpeg'),
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
              child: Stack(
                children: [
                  // Main Content
                  Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SuperAdmin Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isLargeDevice ? 30 : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Welcome, ${widget.userEmail}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isLargeDevice ? 20 : 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Menu Button
                          
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateBranchPage(
                                    accessToken: widget.accessToken,
                                  ),
                                ),
                              );
                              
                              // Refresh branches if a new branch was created
                              if (result == true) {
                                _loadBranches(refresh: true);
                              }
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white, Colors.white70],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSidebarOpen = !_isSidebarOpen;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white, Colors.white70],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isSidebarOpen ? Icons.close : Icons.menu,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isLargeDevice ? 20 : 18,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search branches...',
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isLargeDevice ? 14 : 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Collapsible Arrow Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showStats = !_showStats;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showStats ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.white70,
                                size: isLargeDevice ? 30 : 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Collapsible Stats Cards
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showStats
                          ? Column(
                              children: [
                                const SizedBox(height: 10),
                                // Stats Cards
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Branches',
                                          _totalBranches.toString(),
                                          Icons.business,
                                          isLargeDevice,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Classes',
                                          _branches.fold(0, (sum, branch) => sum + branch.classes.length).toString(),
                                          Icons.fitness_center,
                                          isLargeDevice,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Team Members',
                                          _branches.fold(0, (sum, branch) => sum + branch.teamMembers.length).toString(),
                                          Icons.people,
                                          isLargeDevice,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Branches List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Branches',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isLargeDevice ? 24 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${_branches.length} of $_totalBranches',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isLargeDevice ? 16 : 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _isLoading ? null : () => _loadBranches(refresh: true),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Branches List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _loadBranches(refresh: true),
                        child: _branches.isEmpty && !_isLoading
                            ? Center(
                                child: Text(
                                  'No branches found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isLargeDevice ? 22 : 18,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                                itemCount: _branches.length + (_hasMorePages ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _branches.length) {
                                    return _buildLoadingIndicator();
                                  }
                                  return _buildBranchCard(_branches[index]);
                                },
                              ),
                      ),
                    ),
                  ],
                ),

                // Right Sidebar
                if (_isSidebarOpen)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(-2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Sidebar Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white, Colors.white70],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSidebarOpen = false;
                                    });
                                  },
                                  icon: const Icon(Icons.close, color: Colors.black, size: 24),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'SuperAdmin',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: isLargeDevice ? 22 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.black,
                                  size: isLargeDevice ? 32 : 28,
                                ),
                              ],
                            ),
                          ),
                          
                          // Sidebar Menu Items
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              children: [
                                _buildSidebarMenuItem(
                                  icon: Icons.dashboard,
                                  title: 'Dashboard',
                                  isSelected: true,
                                  onTap: () {
                                    setState(() {
                                      _isSidebarOpen = false;
                                    });
                                  },
                                  isLargeDevice: isLargeDevice,
                                ),
                                const SizedBox(height: 6),
                                _buildSidebarMenuItem(
                                  icon: Icons.business,
                                  title: 'Branches',
                                  isSelected: true,
                                  onTap: () {
                                    setState(() {
                                      _isSidebarOpen = false;
                                    });
                                  },
                                  isLargeDevice: isLargeDevice,
                                ),
                                const SizedBox(height: 6),
                                _buildSidebarMenuItem(
                                  icon: Icons.fitness_center,
                                  title: 'Classes',
                                  isSelected: false,
                                  onTap: _navigateToStandaloneClasses,
                                  isLargeDevice: isLargeDevice,
                                ),
                                const SizedBox(height: 6),
                                _buildSidebarMenuItem(
                                  icon: Icons.people,
                                  title: 'Users',
                                  isSelected: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SuperAdminUsersPage(
                                          accessToken: widget.accessToken,
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      _isSidebarOpen = false;
                                    });
                                  },
                                  isLargeDevice: isLargeDevice,
                                ),
                                const SizedBox(height: 6),
                                _buildSidebarMenuItem(
                                  icon: Icons.book_online,
                                  title: 'Bookings',
                                  isSelected: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SuperAdminBookingsPage(
                                          accessToken: widget.accessToken,
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      _isSidebarOpen = false;
                                    });
                                  },
                                  isLargeDevice: isLargeDevice,
                                ),
                                const SizedBox(height: 6),
                                _buildSidebarMenuItem(
                                  icon: Icons.settings,
                                  title: 'Settings',
                                  isSelected: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SuperAdminSettingsPage(
                                          accessToken: widget.accessToken,
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      _isSidebarOpen = false;
                                    });
                                  },
                                  isLargeDevice: isLargeDevice,
                                ),
                                
                              ],
                            ),
                          ),
                          
                          // Sidebar Footer
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                
                                // User Info Section
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      // User Avatar
                                      CircleAvatar(
                                        radius: isLargeDevice ? 30 : 25,
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          widget.userEmail[0].toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isLargeDevice ? 22 : 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // User Info
                                      Text(
                                        widget.userEmail,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: isLargeDevice ? 16 : 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        'SuperAdmin',
                                        style: TextStyle(
                                          fontSize: isLargeDevice ? 14 : 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Logout Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoggingOut ? null : _handleLogout,
                                    icon: _isLoggingOut 
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.logout, size: 16),
                                    label: Text(
                                      _isLoggingOut ? 'Logging out...' : 'Logout',
                                      style: TextStyle(fontSize: isLargeDevice ? 16 : 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[50],
                                      foregroundColor: Colors.red[700],
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: Colors.red[200]!),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isLargeDevice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: isLargeDevice ? 40 : 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLargeDevice ? 30 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isLargeDevice ? 14 : 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // Trim whitespace
    String cleanUrl = url.trim();
    
    // If already a full URL, return as-is (it's already normalized correctly)
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      // If it already contains /uploads/branch/, it's correct - return as-is
      if (cleanUrl.contains('/uploads/branch/')) {
        return cleanUrl;
      }
      // If it's a full URL without /uploads/, check if it needs it
      if (cleanUrl.contains('/branch/') && !cleanUrl.contains('/uploads/')) {
        return cleanUrl.replaceAll('/branch/', '/uploads/branch/');
      }
      return cleanUrl;
    }
    
    // Remove leading slash if present for easier processing
    cleanUrl = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
    
    // Handle branch/ paths from API image_url field
    // The API returns "branch/1765219735.jpg" which should be accessed from uploads/
    if (cleanUrl.startsWith('branch/')) {
      return 'https://e8gym.online/uploads/$cleanUrl';
    }
    
    // Handle different path formats
    if (cleanUrl.startsWith('app/')) {
      return 'https://e8gym.online/uploads/$cleanUrl';
    } else if (cleanUrl.startsWith('uploads/')) {
      return 'https://e8gym.online/$cleanUrl';
    } else if (cleanUrl.contains('/')) {
      // If it contains a slash, it might already be a path
      // Check if it looks like it needs uploads/ prefix
      if (!cleanUrl.startsWith('uploads/') && !cleanUrl.startsWith('app/')) {
        return 'https://e8gym.online/uploads/$cleanUrl';
      }
      return 'https://e8gym.online/$cleanUrl';
    }
    
    // Default: prepend uploads/ if not already present
    return 'https://e8gym.online/uploads/$cleanUrl';
  }

  Widget _buildBranchCard(BranchResponse branch) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDevice = screenWidth >= 800;
    // Debug: Print branch image information
    print('=== Branch Image Debug ===');
    print('Branch Name: ${branch.branchName}');
    print('Branch ID: ${branch.branchId}');
    print('Image URL: ${branch.image}');
    print('Image is null: ${branch.image == null}');
    print('Image is empty: ${branch.image?.isEmpty ?? true}');
    print('Image length: ${branch.image?.length ?? 0}');
    print('========================');
    
    // Normalize image URL
    final normalizedImageUrl = branch.image != null && branch.image!.isNotEmpty
        ? _normalizeImageUrl(branch.image)
        : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Branch Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: normalizedImageUrl != null && normalizedImageUrl.isNotEmpty
                      ? Image.network(
                          normalizedImageUrl,
                          fit: BoxFit.cover,
                          headers: const {
                            'Accept': 'image/*',
                          },
                          cacheWidth: 120,
                          cacheHeight: 120,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) {
                              return child;
                            }
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: child,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('=== Image Error Debug ===');
                            print('Branch: ${branch.branchName}');
                            print('Original Image URL: ${branch.image}');
                            print('Normalized Image URL: $normalizedImageUrl');
                            print('Error: $error');
                            print('Stack Trace: $stackTrace');
                            print('========================');
                            return Container(
                              color: Colors.white.withValues(alpha: 0.3),
                              child: const Icon(
                                Icons.business,
                                color: Colors.white,
                                size: 30,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('=== Image Loaded Successfully ===');
                              print('Branch: ${branch.branchName}');
                              print('Normalized Image URL: $normalizedImageUrl');
                              print('================================');
                              return child;
                            }
                            print('=== Image Loading ===');
                            print('Branch: ${branch.branchName}');
                            print('Normalized Image URL: $normalizedImageUrl');
                            print('Progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                            print('====================');
                            return Container(
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.white.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeDevice ? 22 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin: ${branch.adminName}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isLargeDevice ? 20 : 18,
                      ),
                    ),
                    if (branch.branchId != null && branch.branchId!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${branch.branchId}',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: isLargeDevice ? 20 : 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.email,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.email,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isLargeDevice ? 20 : 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.phone,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.phoneNumber,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isLargeDevice ? 20 : 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.location,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isLargeDevice ? 20 : 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${branch.classes.length} Classes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isLargeDevice ? 20 : 18,
                ),
              ),
              const SizedBox(width: 24),
              Icon(
                Icons.people,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${branch.teamMembers.length} Team Members',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isLargeDevice ? 20 : 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${_formatDate(branch.createdAt)}',
            style: TextStyle(
              color: Colors.white60,
              fontSize: isLargeDevice ? 18 : 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'View',
                Icons.visibility,
                Colors.blue,
                () => _viewBranch(branch),
              ),
              _buildActionButton(
                'Edit',
                Icons.edit,
                Colors.orange,
                () => _editBranch(branch),
              ),
              _buildActionButton(
                'Delete',
                Icons.delete,
                Colors.red,
                () => _deleteBranch(branch),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDevice = screenWidth >= 800;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeDevice ? 14 : 12,
          vertical: isLargeDevice ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isLargeDevice ? 20 : 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: isLargeDevice ? 15 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewBranch(BranchResponse branch) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchDetailPage(
          accessToken: widget.accessToken,
          branch: branch,
        ),
      ),
    );
    
    if (result == true) {
      _loadBranches(refresh: true);
    }
  }

  Future<void> _editBranch(BranchResponse branch) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBranchPage(
          accessToken: widget.accessToken,
          branch: branch,
        ),
      ),
    );
    
    // Refresh branches if the branch was updated
    if (result == true) {
      _loadBranches(refresh: true);
    }
  }

  Future<void> _deleteBranch(BranchResponse branch) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete "${branch.branchName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await ApiService.deleteBranch(
          branch.id,
          widget.accessToken,
        );

        if (result['success']) {
          _showSnackBar('Branch deleted successfully');
          // Refresh the branches list
          _loadBranches(refresh: true);
        } else {
          _showSnackBar(result['message'] ?? 'Failed to delete branch');
        }
      } catch (e) {
        _showSnackBar('An error occurred: $e');
      }
    }
  }
}
