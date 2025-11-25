import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'models/branch_user_models.dart';

class SuperAdminUsersPage extends StatefulWidget {
  final String accessToken;
  
  const SuperAdminUsersPage({
    super.key,
    required this.accessToken,
  });

  @override
  State<SuperAdminUsersPage> createState() => _SuperAdminUsersPageState();
}

class _SuperAdminUsersPageState extends State<SuperAdminUsersPage> {
  List<BranchWithUsersResponse> _branches = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  
  // Pagination
  int _currentPage = 1;
  int _totalBranches = 0;
  int _limit = 20;
  bool _hasMoreData = true;
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Background image
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _loadBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      // First try to get from API
      final result = await ApiService.getAppSettings(widget.accessToken);
      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        String? backgroundImage;
        
        // Try different possible keys for background image
        if (data['background_image'] != null) {
          backgroundImage = data['background_image'];
        } else if (data['backgroundImage'] != null) {
          backgroundImage = data['backgroundImage'];
        } else if (data['background'] != null) {
          backgroundImage = data['background'];
        }
        
        if (backgroundImage != null && backgroundImage.isNotEmpty) {
          // Normalize the URL
          String normalizedUrl = _normalizeUrl(backgroundImage);
          setState(() {
            _backgroundImageUrl = normalizedUrl;
          });
          
          // Cache the URL
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('background_image_url', normalizedUrl);
          return;
        }
      }
      
      // Fallback to cached URL
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('background_image_url');
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
        });
      }
    } catch (e) {
      print('Error loading background image: $e');
      // Fallback to cached URL
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('background_image_url');
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
        });
      }
    }
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // Handle relative paths
    if (url.startsWith('/app/')) {
      return 'https://e8gym.online/uploads$url';
    } else if (url.startsWith('app/')) {
      return 'https://e8gym.online/uploads/$url';
    } else if (url.startsWith('/uploads/')) {
      return 'https://e8gym.online$url';
    } else if (url.startsWith('uploads/')) {
      return 'https://e8gym.online/$url';
    }
    
    return 'https://e8gym.online/uploads/$url';
  }

  Future<void> _loadBranches({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _branches.clear();
        _hasMoreData = true;
      });
    }

    if (!_hasMoreData && !refresh) return;

    setState(() {
      _isLoading = refresh;
      _isLoadingMore = !refresh;
    });

    try {
      final result = await ApiService.getBranchesWithUsers(
        widget.accessToken,
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (result['success']) {
        final data = result['data'];
        if (data != null) {
          final branches = (data['branches'] as List)
              .map((branch) => BranchWithUsersResponse.fromJson(branch))
              .toList();
          
          final total = data['total'] ?? 0;
          final page = data['page'] ?? 1;
          final limit = data['limit'] ?? 20;

          setState(() {
            if (refresh) {
              _branches = branches;
            } else {
              _branches.addAll(branches);
            }
            _totalBranches = total;
            _currentPage = page;
            _limit = limit;
            _hasMoreData = _branches.length < total;
          });
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to load branches');
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



  Future<void> _loadMoreBranches() async {
    if (_hasMoreData && !_isLoadingMore) {
      setState(() {
        _currentPage++;
      });
      await _loadBranches();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // Debounce search - wait 500ms after user stops typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadBranches(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches & Users'),
        backgroundColor: const Color(0xFFF8BB0C),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              _loadBranches(refresh: true);
            },
            tooltip: 'Reload branches',
          ),
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
                colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
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
          Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search branches...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFF8BB0C)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFFF8BB0C)),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              // Branches List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            const Icon(Icons.business, color: Color(0xFFF8BB0C)),
                            const SizedBox(width: 8),
                            Text(
                              'Branches (${_totalBranches})',
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Branches List
                      Expanded(
                        child: _isLoading && _branches.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                                ),
                              )
                            : _branches.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.business_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _searchQuery.isNotEmpty 
                                            ? 'No branches found matching "$_searchQuery"'
                                            : 'No branches found',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (_searchQuery.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              _onSearchChanged('');
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
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => _loadBranches(refresh: true),
                                    child: NotificationListener<ScrollNotification>(
                                      onNotification: (ScrollNotification scrollInfo) {
                                        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                                          _loadMoreBranches();
                                        }
                                        return false;
                                      },
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        itemCount: _branches.length + (_hasMoreData ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index == _branches.length) {
                                            // Load more indicator
                                            if (_isLoadingMore) {
                                              return const Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          }

                                          final branch = _branches[index];
                                          return _buildBranchCard(branch);
                                        },
                                      ),
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

  Widget _buildBranchCard(BranchWithUsersResponse branch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFF8BB0C),
          backgroundImage: branch.imageUrl != null 
              ? NetworkImage(branch.imageUrl!)
              : null,
          child: branch.imageUrl == null
              ? Text(
                  branch.branchName.isNotEmpty ? branch.branchName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Text(
          branch.branchName,
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
              branch.location,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Admin: ${branch.adminName}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Users: ${branch.userCount}',
              style: const TextStyle(
                color: Color(0xFFF8BB0C),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            _handleBranchAction(value, branch);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'users',
              child: Row(
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 8),
                  Text('View Users'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit Branch'),
                ],
              ),
            ),
          ],
        ),
        children: [
          // Users list
          if (branch.users.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Users in this branch:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFF8BB0C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...branch.users.take(5).map((user) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName.isNotEmpty ? user.fullName : 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (branch.users.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '... and ${branch.users.length - 5} more users',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'No users in this branch yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }



  void _handleBranchAction(String action, BranchWithUsersResponse branch) {
    switch (action) {
      case 'view':
        _showBranchDetails(branch);
        break;
      case 'users':
        _showBranchUsers(branch);
        break;
      case 'edit':
        _editBranch(branch);
        break;
    }
  }

  void _showBranchDetails(BranchWithUsersResponse branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Branch Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Branch Name', branch.branchName.isNotEmpty ? branch.branchName : 'N/A'),
              _buildDetailRow('Location', branch.location.isNotEmpty ? branch.location : 'N/A'),
              _buildDetailRow('Admin Name', branch.adminName.isNotEmpty ? branch.adminName : 'N/A'),
              _buildDetailRow('Email', branch.email.isNotEmpty ? branch.email : 'N/A'),
              _buildDetailRow('Phone', branch.phoneNumber.isNotEmpty ? branch.phoneNumber : 'N/A'),
              _buildDetailRow('User Count', branch.userCount.toString()),
              _buildDetailRow('Classes Count', branch.classes.length.toString()),
              _buildDetailRow('Team Members', branch.teamMembers.length.toString()),
              _buildDetailRow('Created', _formatDate(branch.createdAt)),
              _buildDetailRow('Updated', _formatDate(branch.updatedAt)),
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

  void _showBranchUsers(BranchWithUsersResponse branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Users in ${branch.branchName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: branch.users.isEmpty
              ? const Center(
                  child: Text(
                    'No users in this branch',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: branch.users.length,
                  itemBuilder: (context, index) {
                    final user = branch.users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF8BB0C),
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(user.fullName.isNotEmpty ? user.fullName : 'Unknown User'),
                      subtitle: Text(user.email.isNotEmpty ? user.email : 'No email'),
                      trailing: Text(
                        '${user.totalBookings} bookings',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editBranch(BranchWithUsersResponse branch) {
    // TODO: Implement branch edit
    _showSnackBar('Edit branch functionality not implemented yet');
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
}
