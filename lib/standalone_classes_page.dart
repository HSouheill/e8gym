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
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _searchQuery = '';
  
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
    if (refresh) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
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
        final classListResponse = StandaloneClassListResponse.fromJson(data);
        
        setState(() {
          _classes = classListResponse.classes;
        });
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
        _isRefreshing = false;
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
      _loadClasses(refresh: true);
    }
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
                      // const SizedBox(width: 20),
                      const Expanded(
                        child: Text(
                          'Standalone Classes',
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

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Classes',
                          _classes.length.toString(),
                          Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Active Classes',
                          _classes.where((c) => c.isActive).length.toString(),
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'With Schedule',
                          _classes.where((c) => c.schedule.isNotEmpty).length.toString(),
                          Icons.schedule,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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
                        '${_classes.length} Classes',
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
                    child: _classes.isEmpty && !_isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No standalone classes found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first standalone class to get started',
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
                                    backgroundColor: const Color(0xFFF8BB0C),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            itemCount: _classes.length,
                            itemBuilder: (context, index) {
                              return _buildClassCard(_classes[index]);
                            },
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

  Widget _buildClassCard(StandaloneClassResponse classData) {
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
                      classData.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Instructor: ${classData.instructor}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
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
            ],
          ),
          const SizedBox(height: 12),
          Text(
            classData.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
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
            ],
          ),
          if (classData.schedule.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Schedule: ${_formatSchedule(classData.schedule)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
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
                'View',
                Icons.visibility,
                Colors.blue,
                () => _viewClass(classData),
              ),
              _buildActionButton(
                'Edit',
                Icons.edit,
                Colors.orange,
                () => _editClass(classData),
              ),
              if (classData.isExpired)
                _buildActionButton(
                  'Renew',
                  Icons.refresh,
                  Colors.green,
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
    );
  }

  String _formatSchedule(List<ClassSchedule> schedules) {
    if (schedules.isEmpty) return 'No schedule';
    
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final scheduleStrings = schedules.map((s) {
      final day = daysOfWeek[s.dayOfWeek];
      final startTime = '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}';
      final endTime = '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}';
      return '$day $startTime-$endTime';
    }).toList();
    
    return scheduleStrings.join(', ');
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

  void _viewClass(StandaloneClassResponse classData) {
    // TODO: Navigate to class detail page
    _showSnackBar('Viewing class: ${classData.name}');
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
      _loadClasses(refresh: true);
    }
  }

  Future<void> _renewClass(StandaloneClassResponse classData) async {
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
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weeks Active',
                hintText: 'Enter number of weeks (1-52)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Handle input validation
              },
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
              // TODO: Get the weeks value from TextField
              Navigator.of(context).pop(4); // Default to 4 weeks for now
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

  Future<void> _deleteClass(StandaloneClassResponse classData) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete "${classData.name}"? This action cannot be undone.'),
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
        final result = await ApiService.deleteStandaloneClass(
          classData.id,
          widget.accessToken,
        );

        if (result['success']) {
          _showSnackBar('Class deleted successfully');
          // Refresh the classes list
          _loadClasses(refresh: true);
        } else {
          _showSnackBar(result['message'] ?? 'Failed to delete class');
        }
      } catch (e) {
        _showSnackBar('An error occurred: $e');
      }
    }
  }

  Future<void> _loadExpiringClasses() async {
    try {
      final result = await ApiService.getExpiringClasses(
        widget.accessToken,
        daysThreshold: 7, // Show classes expiring in next 7 days
      );

      if (result['success']) {
        final data = result['data'];
        final classListResponse = StandaloneClassListResponse.fromJson(data);
        
        if (classListResponse.classes.isNotEmpty) {
          // Show expiring classes in a dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Expiring Classes'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: classListResponse.classes.length,
                  itemBuilder: (context, index) {
                    final classData = classListResponse.classes[index];
                    return ListTile(
                      title: Text(classData.name),
                      subtitle: Text('Expires: ${_formatDate(classData.expiresAt!)}'),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _renewClass(classData);
                        },
                        child: const Text('Renew'),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        } else {
          _showSnackBar('No classes expiring in the next 7 days');
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to fetch expiring classes');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }
  }
}
