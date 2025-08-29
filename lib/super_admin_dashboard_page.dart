import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';
import 'create_branch_page.dart';
import 'standalone_classes_page.dart';

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
  bool _isRefreshing = false;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalBranches = 0;
  int _limit = 20;
  bool _hasMorePages = true;
  bool _isSidebarOpen = false;
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _scrollController.addListener(_onScroll);
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
        _isRefreshing = true;
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
        final branches = (data['branches'] as List)
            .map((branch) => BranchResponse.fromJson(branch))
            .toList();
        
        final total = data['total'] as int;
        final currentPage = data['page'] as int;
        final limit = data['limit'] as int;

        setState(() {
          if (refresh) {
            _branches = branches;
          } else {
            _branches.addAll(branches);
          }
          _totalBranches = total;
          _currentPage = currentPage;
          _limit = limit;
          _hasMorePages = _branches.length < total;
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
        _isRefreshing = false;
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
        final branches = (data['branches'] as List)
            .map((branch) => BranchResponse.fromJson(branch))
            .toList();
        
        final total = data['total'] as int;
        final currentPage = data['page'] as int;

        setState(() {
          _branches.addAll(branches);
          _totalBranches = total;
          _currentPage = currentPage;
          _hasMorePages = _branches.length < total;
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

  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF8BB0C).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF926E07) : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF926E07) : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
            child: Row(
              children: [
                // Sidebar
                if (_isSidebarOpen)
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Sidebar Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.black,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'SuperAdmin',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isSidebarOpen = false;
                                  });
                                },
                                icon: const Icon(Icons.close, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        
                        // Sidebar Menu Items
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
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
                              const SizedBox(height: 8),
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
                              const SizedBox(height: 8),
                              _buildSidebarMenuItem(
                                icon: Icons.fitness_center,
                                title: 'Standalone Classes',
                                isSelected: false,
                                onTap: _navigateToStandaloneClasses,
                              ),
                              const SizedBox(height: 8),
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
                              const SizedBox(height: 8),
                              _buildSidebarMenuItem(
                                icon: Icons.settings,
                                title: 'Settings',
                                isSelected: false,
                                onTap: () {
                                  // TODO: Implement Settings page
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFF8BB0C),
                                    child: Text(
                                      widget.userEmail[0].toUpperCase(),
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
                                          widget.userEmail,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Text(
                                          'SuperAdmin',
                                          style: TextStyle(
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
                        ),
                      ],
                    ),
                  ),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
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
                            const SizedBox(width: 20),
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
                                setState(() {
                                  _isSidebarOpen = !_isSidebarOpen;
                                });
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
                                child: Icon(
                                  _isSidebarOpen ? Icons.close : Icons.menu,
                                  color: Colors.black,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
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
                          'Active Branches',
                          _branches.where((b) => b.isActive).length.toString(),
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Verified Branches',
                          _branches.where((b) => b.isVerified).length.toString(),
                          Icons.verified,
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
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: branch.isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      branch.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: branch.isVerified ? Colors.blue : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      branch.isVerified ? 'Verified' : 'Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
                '${branch.countryCode} ${branch.phoneNumber}',
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
}
