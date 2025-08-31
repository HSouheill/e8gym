import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'models/auth_models.dart';
import 'create_branch_page.dart';
import 'standalone_classes_page.dart';
import 'admin_login_page.dart';
import 'branch_detail_page.dart';
import 'edit_branch_page.dart';

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
  }

  Future<void> _initializeStorage() async {
    try {
      await _storageService.init();
      final storedToken = _storageService.getAccessToken();
      print('=== Storage Initialization Debug ===');
      print('Stored token available: ${storedToken != null}');
      if (storedToken != null) {
        print('Stored token length: ${storedToken.length}');
        print('Stored token starts with Bearer: ${storedToken.startsWith('Bearer ')}');
      }
      print('Widget access token: ${widget.accessToken}');
      print('Widget token length: ${widget.accessToken.length}');
    } catch (e) {
      print('Error initializing storage: $e');
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

  void _navigateToStandaloneClasses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StandaloneClassesPage(
          accessToken: widget.accessToken,
        ),
      ),
    );
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
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF8BB0C)),
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
      final storedToken = _storageService.getAccessToken();
      print('Stored token: ${storedToken != null ? '${storedToken.substring(0, 20)}...' : 'null'}');
      
      // Use stored token if available, otherwise use widget token
      final tokenToUse = storedToken ?? widget.accessToken;
      print('Token to use for logout: ${tokenToUse.substring(0, 20)}...');
      
      final result = await ApiService.superAdminLogout(tokenToUse);
      
      if (result['success']) {
        // Clear stored auth data
        await _storageService.clearAuthData();
        
        if (mounted) {
          // Navigate back to admin login page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AdminLoginPage(),
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          _showSnackBar(result['message'] ?? 'Logout failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred during logout: $e');
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
  }) {
    final bool isDisabled = title == 'Logging out...';
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF8BB0C).withOpacity(0.2) : Colors.transparent,
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
          size: 22,
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
            fontSize: 14,
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
                                const Text(
                                  'SuperAdmin Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Welcome, ${widget.userEmail}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Menu Button
                          
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateBranchPage(
                                    accessToken: widget.accessToken,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
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
                                  colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search branches...',
                            hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.search, color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: _buildStatCard(
                               'Total Classes',
                               _branches.fold(0, (sum, branch) => sum + branch.classes.length).toString(),
                               Icons.fitness_center,
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: _buildStatCard(
                               'Total Team Members',
                               _branches.fold(0, (sum, branch) => sum + branch.teamMembers.length).toString(),
                               Icons.people,
                             ),
                           ),
                         ],
                       ),
                     ),

                    const SizedBox(height: 20),

                    // Branches List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Branches',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_branches.length} of $_totalBranches',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
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
                            ? const Center(
                                child: Text(
                                  'No branches found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
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
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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
                                colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
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
                                const Expanded(
                                  child: Text(
                                    'SuperAdmin',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.black,
                                  size: 28,
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
                                ),
                                const SizedBox(height: 6),
                                _buildSidebarMenuItem(
                                  icon: Icons.fitness_center,
                                  title: 'Classes',
                                  isSelected: false,
                                  onTap: _navigateToStandaloneClasses,
                                ),
                                const SizedBox(height: 6),
                                _buildSidebarMenuItem(
                                  icon: Icons.people,
                                  title: 'Users',
                                  isSelected: false,
                                  onTap: () {
                                    // TODO: Implement Users page
                                    setState(() {
                                      _isSidebarOpen = false;
                                    });
                                  },
                                ),
                                const SizedBox(height: 6),
                                _buildSidebarMenuItem(
                                  icon: Icons.settings,
                                  title: 'Settings',
                                  isSelected: false,
                                  onTap: () {
                                    // TODO: Implement Users page
                                    setState(() {
                                      _isSidebarOpen = false;
                                    });
                                  },
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
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFF8BB0C),
                                      child: Text(
                                        widget.userEmail[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.userEmail,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text(
                                            'SuperAdmin',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                      style: const TextStyle(fontSize: 13),
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
          ),
        ),
      );
    
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
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
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(BranchResponse branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin: ${branch.adminName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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
              Text(
                branch.phoneNumber,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${_formatDate(branch.createdAt)}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
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
        content: Text(message),
        backgroundColor: const Color(0xFFF8BB0C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewBranch(BranchResponse branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchDetailPage(
          accessToken: widget.accessToken,
          branch: branch,
        ),
      ),
    );
  }

  void _editBranch(BranchResponse branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBranchPage(
          accessToken: widget.accessToken,
          branch: branch,
        ),
      ),
    );
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
