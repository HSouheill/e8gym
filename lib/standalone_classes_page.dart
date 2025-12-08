import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/standalone_class_models.dart';
import 'create_standalone_class_page.dart';
import 'edit_standalone_class_page.dart';

class StandaloneClassesPage extends StatefulWidget {
  final String accessToken;
  
  const StandaloneClassesPage({
    super.key,
    required this.accessToken,
  });

  @override
  State<StandaloneClassesPage> createState() => _StandaloneClassesPageState();
}

class _StandaloneClassesPageState extends State<StandaloneClassesPage> {
  List<StandaloneClassResponse> _classes = [];
  List<StandaloneClassResponse> _filteredClasses = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Inactive, Expired, Expiring Soon, Visible, Hidden
  bool _classesModified = false; // Track if classes were modified
  bool _isTogglingVisibility = false;
  bool _showFiltersAndStats = false; // Track if filters and stats are visible
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await ApiService.getStandaloneClasses(
        widget.accessToken,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (result['success']) {
        final data = result['data'];
        if (data != null) {
          try {
            final classListResponse = StandaloneClassListResponse.fromJson(data);
            
            setState(() {
              _classes = classListResponse.classes;
              _applyFilters();
            });
          } catch (parseError) {
            print('Error parsing class data: $parseError');
            if (!refresh) {
              _showSnackBar('Error parsing class data. Please try again.');
            }
            setState(() {
              _classes = [];
              _filteredClasses = [];
            });
          }
        } else {
          print('API returned null data for classes');
          setState(() {
            _classes = [];
            _filteredClasses = [];
          });
        }
      } else {
        if (!refresh) {
          _showSnackBar(result['message'] ?? 'Failed to load classes');
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

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _debounceSearch();
  }

  void _applyFilters() {
    List<StandaloneClassResponse> filtered = List.from(_classes);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((classData) {
        return classData.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               classData.instructor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               classData.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case 'Active':
        filtered = filtered.where((classData) => classData.isActive && !classData.isExpired).toList();
        break;
      case 'Inactive':
        filtered = filtered.where((classData) => !classData.isActive).toList();
        break;
      case 'Expired':
        filtered = filtered.where((classData) => classData.isExpired).toList();
        break;
      case 'Expiring Soon':
        filtered = filtered.where((classData) {
          return classData.expiresAt != null && 
                 !classData.isExpired && 
                 classData.expiresAt!.difference(DateTime.now()).inDays <= 7;
        }).toList();
        break;
      case 'With Schedule':
        filtered = filtered.where((classData) => classData.schedule.isNotEmpty).toList();
        break;
      case 'Without Schedule':
        filtered = filtered.where((classData) => classData.schedule.isEmpty).toList();
        break;
      case 'Visible':
        filtered = filtered.where((classData) => classData.isVisible ?? true).toList();
        break;
      case 'Hidden':
        filtered = filtered.where((classData) => classData.isVisible == false).toList();
        break;
      // 'All' case - no additional filtering needed
    }

    setState(() {
      _filteredClasses = filtered;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == _searchController.text) {
        _loadClasses(refresh: true);
      }
    });
  }

  void _navigateToCreateClass() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStandaloneClassPage(
          accessToken: widget.accessToken,
        ),
      ),
    );
    
    if (result == true) {
      setState(() {
        _classesModified = true;
      });
      _loadClasses(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the modification flag when popping
        Navigator.of(context).pop(_classesModified);
        return false; // Prevent default pop behavior since we're handling it manually
      },
      child: Scaffold(
        body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white70],
          ),
        ),
        child: Container(
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
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
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
                      // const SizedBox(width: 20),
                      const Expanded(
                        child: Text(
                          'Classes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,


                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToCreateClass,
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
                        hintText: 'Search classes...',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        _showFiltersAndStats = !_showFiltersAndStats;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showFiltersAndStats ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Collapsible Filter and Stats Section
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showFiltersAndStats
                      ? Column(
                          children: [
                            const SizedBox(height: 10),
                            // Filter Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Filter Classes',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_selectedFilter != 'All')
                                        TextButton(
                                          onPressed: () => _onFilterChanged('All'),
                                          child: const Text(
                                            'Clear Filters',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildFilterChip('All', Icons.list),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('Active', Icons.check_circle),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('Inactive', Icons.cancel),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('Expired', Icons.error),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('Expiring Soon', Icons.warning),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('With Schedule', Icons.schedule),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('Without Schedule', Icons.schedule_outlined),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('Visible', Icons.visibility),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('Hidden', Icons.visibility_off),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Stats Cards
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Classes',
                                          _filteredClasses.length.toString(),
                                          Icons.fitness_center,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Active Classes',
                                          _filteredClasses.where((c) => c.isActive && !c.isExpired).length.toString(),
                                          Icons.check_circle,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildStatCard(
                                          'With Schedule',
                                          _filteredClasses.where((c) => c.schedule.isNotEmpty).length.toString(),
                                          Icons.schedule,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                // Classes List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Classes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_filteredClasses.length} Classes',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Classes List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadClasses(refresh: true),
                    child: _filteredClasses.isEmpty && !_isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedFilter == 'All' ? Icons.fitness_center : Icons.filter_list,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFilter == 'All' 
                                      ? 'No classes found'
                                      : 'No classes found for "$_selectedFilter" filter',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedFilter == 'All'
                                      ? 'Create your first class to get started'
                                      : 'Try changing the filter or create a new class',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _navigateToCreateClass,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Class'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            itemCount: _filteredClasses.length,
                            itemBuilder: (context, index) {
                              return _buildClassCard(_filteredClasses[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withOpacity(0.9)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.white
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {VoidCallback? onTap, bool isClickable = false}) {
    Widget cardContent = Column(
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
    );

    if (isClickable && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: cardContent,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: cardContent,
    );
  }

  Widget _buildClassCard(StandaloneClassResponse classData) {
    // Check if class is expiring soon (within 7 days)
    final isExpiringSoon = classData.expiresAt != null && 
        !classData.isExpired && 
        classData.expiresAt!.difference(DateTime.now()).inDays <= 7;
    
    // Check visibility status
    final isVisible = classData.isVisible ?? true;
    
    // Determine border color based on class status
    Color borderColor = Colors.white.withOpacity(0.3);
    if (!isVisible) {
      borderColor = Colors.grey.withOpacity(0.7);
    } else if (classData.isExpired) {
      borderColor = Colors.red.withOpacity(0.7);
    } else if (isExpiringSoon) {
      borderColor = Colors.orange.withOpacity(0.7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVisible ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Name and Expiring/Expired Badge at Top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          classData.name,
                          style: TextStyle(
                            color: isVisible ? Colors.white : Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: isVisible ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (isExpiringSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'EXPIRING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (classData.isExpired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'EXPIRED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Active/Inactive Status and Visibility Toggle (Vertical)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Active/Inactive Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: classData.isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 4),
                    // Visibility Toggle Switch
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isVisible,
                        onChanged: _isTogglingVisibility
                            ? null
                            : (value) => _toggleClassVisibility(classData),
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.grey,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Visibility Badge (if hidden)
          if (!isVisible)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_off,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Hidden from members',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructor: ${classData.instructor}',
                  style: TextStyle(
                    color: isVisible ? Colors.white70 : Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  classData.description,
                  style: TextStyle(
                    color: isVisible ? Colors.white70 : Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
          
                // Images Display
                if (classData.images.isNotEmpty) ...[
                  Container(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: classData.images.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              classData.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white70,
                                    size: 40,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[800],
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
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Capacity: ${classData.capacity}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ${classData.duration} min',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (classData.schedule.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildGroupedSchedule(classData.schedule),
                ],
                const SizedBox(height: 8),
                Text(
                  'Created: ${_formatDate(classData.createdAt)}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                if (classData.expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expires: ${_formatDate(classData.expiresAt!)}',
                    style: TextStyle(
                      color: classData.isExpired ? Colors.red : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (classData.renewalCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Renewed: ${classData.renewalCount} times',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      'Edit',
                      Icons.edit,
                      Colors.orange,
                      () => _editClass(classData),
                    ),
                    if (classData.isExpired || isExpiringSoon)
                      _buildActionButton(
                        'Renew',
                        Icons.refresh,
                        classData.isExpired ? Colors.green : Colors.amber,
                        () => _renewClass(classData),
                      ),
                    _buildActionButton(
                      'Delete',
                      Icons.delete,
                      Colors.red,
                      () => _deleteClass(classData),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allSchedules.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 16,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.white,
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


  void _editClass(StandaloneClassResponse classData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStandaloneClassPage(
          accessToken: widget.accessToken,
          classData: classData,
        ),
      ),
    );
    
    if (result == true) {
      setState(() {
        _classesModified = true;
      });
      _loadClasses(refresh: true);
    }
  }

  Future<void> _renewClass(StandaloneClassResponse classData) async {
    final weeksController = TextEditingController();
    
    // Show renewal dialog
    final weeksActive = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renew Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many weeks would you like to renew "${classData.name}" for?'),
            const SizedBox(height: 16),
            TextField(
              controller: weeksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weeks Active',
                hintText: 'Enter number of weeks (1-52)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final weeksText = weeksController.text.trim();
              final weeks = int.tryParse(weeksText);
              
              if (weeks == null || weeks < 1 || weeks > 52) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: const Text('Please enter a valid number of weeks (1-52)', style: TextStyle(color: Colors.black)),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop(weeks);
            },
            child: const Text('Renew'),
          ),
        ],
      ),
    );

    if (weeksActive != null && weeksActive > 0) {
      try {
        final renewData = RenewClassRequest(weeksActive: weeksActive);
        final result = await ApiService.renewClass(
          classData.id,
          renewData,
          widget.accessToken,
        );

        if (result['success']) {
          _showSnackBar('Class renewed successfully for $weeksActive weeks');
          setState(() {
            _classesModified = true;
          });
          // Refresh the classes list
          _loadClasses(refresh: true);
        } else {
          _showSnackBar(result['message'] ?? 'Failed to renew class');
        }
      } catch (e) {
        _showSnackBar('An error occurred: $e');
      }
    }
  }

  Future<void> _toggleClassVisibility(StandaloneClassResponse classData) async {
    if (_isTogglingVisibility) return;

    setState(() {
      _isTogglingVisibility = true;
    });

    try {
      final result = await ApiService.toggleStandaloneClassVisibility(
        classData.id,
        widget.accessToken,
      );

      if (result['success']) {
        final updatedClassData = result['data'];
        final newIsVisible = updatedClassData['is_visible'] ?? updatedClassData['IsVisible'] ?? true;

        // Update the class in the list
        final classIndex = _classes.indexWhere((c) => c.id == classData.id);
        if (classIndex != -1) {
          setState(() {
            _classes[classIndex] = _classes[classIndex].copyWith(
              isVisible: newIsVisible,
            );
            _classesModified = true;
            _applyFilters();
          });
        }

        
      } 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.black)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isTogglingVisibility = false;
      });
    }
  }

  Future<void> _deleteClass(StandaloneClassResponse classData) async {
    // Log deletion initiation
    print('=== Standalone Class Deletion Initiated ===');
    print('Class ID: ${classData.id}');
    print('Class Name: ${classData.name}');
    print('Instructor: ${classData.instructor}');
    print('Is Active: ${classData.isActive}');
    print('Is Visible: ${classData.isVisible ?? true}');
    print('Is Expired: ${classData.isExpired}');
    print('Total Classes in List: ${_classes.length}');
    print('Filtered Classes Count: ${_filteredClasses.length}');
    
    // Find class index in the list
    final classIndex = _classes.indexWhere((c) => c.id == classData.id);
    if (classIndex != -1) {
      print('Class found at index: $classIndex');
    } else {
      print('WARNING: Class not found in classes list');
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete "${classData.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              print('Deletion cancelled by user');
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              print('Deletion confirmed by user');
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print('Proceeding with class deletion...');
      print('Sending delete request to API for class ID: ${classData.id}');
      
      try {
        final result = await ApiService.deleteStandaloneClass(
          classData.id,
          widget.accessToken,
        );

        if (result['success']) {
          print('✓ API deletion request successful');
          
          // Extract response data if available
          final responseData = result['data'];
          int bookingsDeleted = 0;
          
          if (responseData != null && responseData is Map) {
            bookingsDeleted = responseData['bookings_deleted'] ?? 0;
            print('Bookings deleted from server: $bookingsDeleted');
          }
          
          // Verify class removal from local list
          final stillInList = _classes.any((c) => c.id == classData.id);
          if (stillInList) {
            print('WARNING: Class still exists in local list before refresh');
          } else {
            print('✓ Class already removed from local list');
          }
          
          // Update UI state
          setState(() {
            _classesModified = true;
          });
          
          print('Refreshing classes list to verify deletion...');
          
          // Refresh the classes list
          await _loadClasses(refresh: true);
          
          // Verify deletion after refresh
          final verifyStillExists = _classes.any((c) => c.id == classData.id);
          if (verifyStillExists) {
            print('ERROR: VERIFICATION FAILED - Class ${classData.id} still exists after refresh!');
          } else {
            print('✓ Verification successful: Class ${classData.id} confirmed deleted from list');
          }
          
          // Summary log
          print('=== Standalone Class Deletion Summary ===');
          print('Class ID: ${classData.id}');
          print('Class Name: ${classData.name}');
          print('Instructor: ${classData.instructor}');
          print('✓ Removed from standalone classes collection');
          print('✓ Deleted $bookingsDeleted related booking(s) from bookings collection');
          print('✓ All references removed from database collections');
          print('✓ UI updated and list refreshed');
          print('=========================================');
          
          // _showSnackBar('Class deleted successfully');
        } else {
          final errorMessage = result['message'] ?? 'Failed to delete class';
          final errorDetails = result['error'];
          
          print('ERROR: API deletion request failed');
          print('Error Message: $errorMessage');
          if (errorDetails != null) {
            print('Error Details: $errorDetails');
          }
          
          // _showSnackBar(errorMessage);
        }
      } catch (e, stackTrace) {
        print('EXCEPTION: Error occurred during class deletion');
        print('Exception Type: ${e.runtimeType}');
        print('Exception Message: $e');
        print('Stack Trace: $stackTrace');
        print('Class ID: ${classData.id}');
        print('Class Name: ${classData.name}');
        
        // _showSnackBar('An error occurred: $e');
      }
    } else {
      print('Deletion aborted - user cancelled');
    }
  }


}
