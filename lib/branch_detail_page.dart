import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/auth_models.dart';
import 'services/api_service.dart';
import 'edit_branch_page.dart';
import 'utils/app_colors.dart';

class BranchDetailPage extends StatefulWidget {
  final String accessToken;
  final BranchResponse branch;
  
  const BranchDetailPage({
    super.key,
    required this.accessToken,
    required this.branch,
  });

  @override
  State<BranchDetailPage> createState() => _BranchDetailPageState();
}

class _BranchDetailPageState extends State<BranchDetailPage> {
  String? _backgroundImageUrl;
  late BranchResponse _branch;
  bool _isTogglingVisibility = false;
  bool _hasUpdatedClasses = false;
  bool _isBranchLoading = false;

  @override
  void initState() {
    super.initState();
    _branch = widget.branch;
    _loadBackgroundImage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBranchDetails(showLoader: true);
    });
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

  Future<void> _loadBranchDetails({bool showLoader = false}) async {
    final branchIdentifier = _branch.id.isNotEmpty ? _branch.id : (_branch.branchId ?? '');
    if (branchIdentifier.isEmpty) {
      return;
    }

    if (showLoader) {
      setState(() {
        _isBranchLoading = true;
      });
    }

    try {
      final result = await ApiService.getBranch(branchIdentifier, widget.accessToken);
      if (result['success'] == true && result['data'] != null) {
        final updatedBranch = BranchResponse.fromJson(result['data']);
        setState(() {
          _branch = updatedBranch;
          _hasUpdatedClasses = true;
        });
      } else {
        final message = result['message'] ?? 'Failed to load branch details';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.gold,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading branch details: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (showLoader && mounted) {
        setState(() {
          _isBranchLoading = false;
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

  Future<void> _toggleClassVisibility(String classId, int classIndex, bool newVisibility) async {
    if (_isTogglingVisibility) return;

    // Get current visibility state
    final currentClass = _branch.classes[classIndex];
    final currentVisibility = currentClass.isVisible ?? true;
    
    // If the new visibility is the same as current, don't do anything
    if (newVisibility == currentVisibility) {
      return;
    }

    setState(() {
      _isTogglingVisibility = true;
    });

    try {
      // Determine which endpoint to use based on whether we have branch context
      // Super admin viewing branch details should use endpoint with branch ID
      // Branch admin uses endpoint without branch ID (their token provides context)
      Map<String, dynamic> result;
      
      // For super admin, use branch ID in query parameter
      // For branch admin, use endpoint without branch ID (token provides context)
      // Try using branch's id field first (database ID), then branchId if available
      final branchIdentifier = _branch.id.isNotEmpty ? _branch.id : (_branch.branchId ?? '');
      
      if (branchIdentifier.isNotEmpty) {
        // Super admin endpoint: /api/branch/classes/{classId}/toggle-visibility?branch_id={branchId}
        print('Using super admin endpoint with branch ID: $branchIdentifier');
        result = await ApiService.toggleBranchClassVisibilityForSuperAdmin(
          branchIdentifier,
          classId,
          widget.accessToken,
        );
      } else {
        // Branch admin endpoint: /api/branch/classes/{classId}/toggle-visibility
        print('Using branch admin endpoint (no branch ID available)');
        result = await ApiService.toggleBranchClassVisibility(
          classId,
          widget.accessToken,
        );
      }

      if (result['success']) {
        final classData = result['data'];
        final updatedIsVisible = classData['is_visible'] ?? classData['IsVisible'] ?? true;

        // Update the class in the branch
        final updatedClasses = List<ClassModel>.from(_branch.classes);
        updatedClasses[classIndex] = updatedClasses[classIndex].copyWith(
          isVisible: updatedIsVisible,
        );

        setState(() {
          _branch = BranchResponse(
            id: _branch.id,
            branchId: _branch.branchId,
            branchName: _branch.branchName,
            adminName: _branch.adminName,
            email: _branch.email,
            phoneNumber: _branch.phoneNumber,
            location: _branch.location,
            image: _branch.image,
            classes: updatedClasses,
            teamMembers: _branch.teamMembers,
            createdAt: _branch.createdAt,
            updatedAt: _branch.updatedAt,
            createdBy: _branch.createdBy,
          );
          _hasUpdatedClasses = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 
              (updatedIsVisible ? 'Class is now visible' : 'Class is now hidden'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Revert the switch state on error
        setState(() {
          _isTogglingVisibility = false;
        });
        
        // Show detailed error message for debugging
        final errorMessage = result['message'] ?? 'Failed to toggle class visibility';
        final errorDetails = result['error'] ?? '';
        print('Toggle visibility error: $errorMessage');
        print('Error details: $errorDetails');
        print('Branch ID: ${_branch.branchId}');
        print('Branch ID (id field): ${_branch.id}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Revert the switch state on error
      setState(() {
        _isTogglingVisibility = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.black)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingVisibility = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasUpdatedClasses);
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Branch: ${_branch.branchName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isBranchLoading ? null : () => _loadBranchDetails(showLoader: true),
            tooltip: 'Refresh Branch',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isBranchLoading ? null : () => _editBranch(),
            tooltip: 'Edit Branch',
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch Header Card
                _buildBranchHeaderCard(),
                const SizedBox(height: 16),
                
                // Branch Details Card
                _buildBranchDetailsCard(),
                const SizedBox(height: 16),
                
                // Classes Card
                _buildClassesCard(),
                const SizedBox(height: 16),
                
                // Team Members Card
                _buildTeamMembersCard(),
              ],
            ),
          ),
          if (_isBranchLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildBranchHeaderCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _branch.branchName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Admin: ${_branch.adminName}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                         Row(
               children: [
                 _buildStatusChip(
                   'Branch',
                   Colors.white,
                   Icons.business,
                 ),
                 const SizedBox(width: 12),
                 _buildStatusChip(
                   'Admin: ${_branch.adminName}',
                   Colors.blue,
                   Icons.person,
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
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
    );
  }

  Widget _buildBranchDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Branch Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.email, 'Email', _branch.email),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.phone, 'Phone', _branch.phoneNumber),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, 'Location', _branch.location),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.calendar_today, 'Created', _formatDate(_branch.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Classes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_branch.classes.length} classes',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_branch.classes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No classes assigned to this branch',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _branch.classes.length,
                itemBuilder: (context, index) {
                  final classItem = _branch.classes[index];
                  final isVisible = classItem.isVisible ?? true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isVisible ? Colors.grey[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isVisible ? Colors.grey[200]! : Colors.grey[400]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: isVisible ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      classItem.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isVisible ? Colors.black87 : Colors.grey[600],
                                        decoration: isVisible ? null : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  if (!isVisible)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Hidden',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                'Duration: ${classItem.duration} minutes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isVisible ? Colors.black54 : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (classItem.id != null && classItem.id!.isNotEmpty)
                          Switch(
                            value: isVisible,
                            onChanged: _isTogglingVisibility
                                ? null
                                : (value) {
                                    // Only toggle if the value actually changed
                                    if (value != isVisible) {
                                      _toggleClassVisibility(classItem.id!, index, value);
                                    }
                                  },
                            activeColor: Colors.green,
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVisible ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isVisible ? 'Active' : 'Hidden',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMembersCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Team Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_branch.teamMembers.length} members',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_branch.teamMembers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No team members assigned to this branch',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _branch.teamMembers.length,
                itemBuilder: (context, index) {
                  final member = _branch.teamMembers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                                                 CircleAvatar(
                           radius: 20,
                           backgroundColor: Colors.white,
                           child: Text(
                             member.fullName[0].toUpperCase(),
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
                                 member.fullName,
                                 style: const TextStyle(
                                   fontWeight: FontWeight.w600,
                                   color: Colors.black87,
                                 ),
                               ),
                               Text(
                                 member.role,
                                 style: const TextStyle(
                                   fontSize: 12,
                                   color: Colors.black54,
                                 ),
                               ),
                               Text(
                                 member.email,
                                 style: const TextStyle(
                                   fontSize: 12,
                                   color: Colors.black54,
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _editBranch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBranchPage(
          accessToken: widget.accessToken,
          branch: _branch,
        ),
      ),
    );

    if (result == true) {
      await _loadBranchDetails(showLoader: true);
      setState(() {
        _hasUpdatedClasses = true;
      });
    }
  }
}
