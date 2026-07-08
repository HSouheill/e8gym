import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/auth_models.dart';
import '../../models/standalone_class_models.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/foundation.dart';

class EditBranchPage extends StatefulWidget {
  final String accessToken;
  final BranchResponse branch;
  
  const EditBranchPage({
    super.key,
    required this.accessToken,
    required this.branch,
  });

  @override
  State<EditBranchPage> createState() => _EditBranchPageState();
}

class _EditBranchPageState extends State<EditBranchPage> {
  final TextEditingController _branchIdController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingClasses = false;
  
  // Class selection
  List<StandaloneClassResponse> _availableClasses = [];
  List<StandaloneClassResponse> _selectedClasses = [];
  
  // Team member management
  List<TeamMemberModel> _teamMembers = [];
  Set<String> _originalTeamMemberEmails = {}; // Track original team members by email
  final TextEditingController _teamMemberNameController = TextEditingController();
  final TextEditingController _teamMemberEmailController = TextEditingController();
  final TextEditingController _teamMemberPhoneController = TextEditingController();
  final TextEditingController _teamMemberPasswordController = TextEditingController();
  final TextEditingController _teamMemberConfirmPasswordController = TextEditingController();
  final String _selectedCountryCode = '+1';
  String _selectedTeamMemberRole = 'viewer';
  bool _showAddTeamMemberForm = false;
  bool _obscureTeamMemberPassword = true;
  bool _obscureTeamMemberConfirmPassword = true;
  static const List<Map<String, String>> _teamMemberRoleOptions = [
    {
      'value': 'admin',
      'title': 'Admin',
      'subtitle': 'Can manage branch & login',
    },
    {
      'value': 'viewer',
      'title': 'Viewer',
      'subtitle': 'Read-only access',
    },
  ];

  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  File? _branchImageFile;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAvailableClasses();
  }

  void _initializeControllers() {
    _branchIdController.text = widget.branch.branchId ?? '';
    _branchNameController.text = widget.branch.branchName;
    _adminNameController.text = widget.branch.adminName;
    _emailController.text = widget.branch.email;
    _phoneNumberController.text = widget.branch.phoneNumber;
    _locationController.text = widget.branch.location;
    
    // Initialize team members
    _teamMembers = List.from(widget.branch.teamMembers);
    
    // Track original team member emails to distinguish existing vs new members
    _originalTeamMemberEmails = widget.branch.teamMembers
        .map((m) => m.email.toLowerCase())
        .toSet();
    
    // Debug: Log team members initialization
    if (kDebugMode) print('=== Edit Branch Page - Team Members Debug ===');
    if (kDebugMode) print('Branch: ${widget.branch.branchName}');
    if (kDebugMode) print('Team Members Count: ${widget.branch.teamMembers.length}');
    if (kDebugMode) print('Team Members: ${widget.branch.teamMembers.map((m) => m.fullName).toList()}');
    if (kDebugMode) print('Original Team Member Emails: $_originalTeamMemberEmails');
    if (kDebugMode) print('Initialized Team Members Count: ${_teamMembers.length}');
    if (kDebugMode) print('=============================================');
    
    // Initialize selected classes will be done after loading available classes
    _selectedClasses = [];
  }

  Future<void> _loadAvailableClasses() async {
    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final result = await ApiService.getStandaloneClasses(
        widget.accessToken,
        limit: 100,
      );

      if (result['success']) {
        final data = result['data'];
        if (data != null) {
          try {
            final classListResponse = StandaloneClassListResponse.fromJson(data);
            
            setState(() {
              _availableClasses = classListResponse.classes.where((c) => c.isActive).toList();
              
              // Initialize selected classes from existing branch data
              _initializeSelectedClassesFromBranch();
            });
          } catch (parseError) {
            if (kDebugMode) print('Error parsing class data: $parseError');
            _showSnackBar('Error parsing class data. Please try again.');
            setState(() {
              _availableClasses = [];
            });
          }
        } else {
          if (kDebugMode) print('API returned null data for classes');
          setState(() {
            _availableClasses = [];
          });
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to load available classes');
      }
    } catch (e) {
      _showSnackBar('An error occurred while loading classes: $e');
    } finally {
      setState(() {
        _isLoadingClasses = false;
      });
    }
  }

  void _initializeSelectedClassesFromBranch() {
    // Map existing branch classes to standalone classes
    for (final branchClass in widget.branch.classes) {
      // Find matching standalone class by name (since we don't have direct ID mapping)
      try {
        final matchingStandaloneClass = _availableClasses.firstWhere(
          (standaloneClass) => standaloneClass.name == branchClass.name,
        );
        _selectedClasses.add(matchingStandaloneClass);
      } catch (e) {
        // If no matching class found, skip it
        if (kDebugMode) print('No matching standalone class found for: ${branchClass.name}');
      }
    }
  }

  @override
  void dispose() {
    _branchIdController.dispose();
    _branchNameController.dispose();
    _adminNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    
    // Team member controllers
    _teamMemberNameController.dispose();
    _teamMemberEmailController.dispose();
    _teamMemberPhoneController.dispose();
    _teamMemberPasswordController.dispose();
    _teamMemberConfirmPasswordController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Branch: ${widget.branch.branchName}'),
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
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branch Information Section
              _buildSectionCard(
                'Branch Information',
                Icons.business,
                [
                  _buildTextField(
                    controller: _branchIdController,
                    label: 'Branch ID',
                    icon: Icons.tag,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Branch ID is required';
                      }
                      if (value.length < 3) {
                        return 'Branch ID must be at least 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                        return 'Branch ID can only contain letters and numbers';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _branchNameController,
                    label: 'Branch Name',
                    icon: Icons.business,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Branch name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _adminNameController,
                    label: 'Admin Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Admin name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneNumberController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    icon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Location is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Branch Image Upload Section
                  _buildImageUploadSection(),
                ],
              ),
              const SizedBox(height: 20),

              // Classes Section
              _buildSectionCard(
                'Classes',
                Icons.fitness_center,
                [
                  if (_isLoadingClasses)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'Selected Classes (${_selectedClasses.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedClasses.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No classes selected',
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
                            itemCount: _selectedClasses.length,
                            itemBuilder: (context, index) {
                              final classItem = _selectedClasses[index];
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
                                    Icon(
                                      Icons.fitness_center,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                                                             child: Text(
                                         classItem.name,
                                         style: const TextStyle(
                                           fontWeight: FontWeight.w600,
                                         ),
                                       ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _selectedClasses.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        _buildClassSelectionDropdown(),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Team Members Section
              _buildSectionCard(
                'Team Members',
                Icons.people,
                [
                  Text(
                    'Current Team Members (${_teamMembers.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_teamMembers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No team members added',
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
                      itemCount: _teamMembers.length,
                      itemBuilder: (context, index) {
                        final member = _teamMembers[index];
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
                                  member.fullName.isNotEmpty 
                                      ? member.fullName[0].toUpperCase()
                                      : '?',
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
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removeTeamMember(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  if (_showAddTeamMemberForm) _buildAddTeamMemberForm(),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddTeamMemberForm = !_showAddTeamMemberForm;
                      });
                    },
                    icon: Icon(_showAddTeamMemberForm ? Icons.remove : Icons.add),
                    label: Text(_showAddTeamMemberForm ? 'Cancel' : 'Add Team Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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

  Widget _buildImageUploadSection() {
    // Normalize existing branch image URL
    final normalizedImageUrl = widget.branch.image != null && widget.branch.image!.isNotEmpty
        ? _normalizeImageUrl(widget.branch.image)
        : null;
    
    // Debug logging
    if (widget.branch.image != null) {
      if (kDebugMode) print('=== Edit Branch Image Debug ===');
      if (kDebugMode) print('Original branch.image: ${widget.branch.image}');
      if (kDebugMode) print('Normalized URL: $normalizedImageUrl');
      if (kDebugMode) print('================================');
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 129, 124, 124),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.image,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Branch Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _branchImageFile != null 
                          ? 'New image selected' 
                          : normalizedImageUrl != null && normalizedImageUrl.isNotEmpty
                              ? 'Current image available'
                              : 'No image selected',
                      style: TextStyle(
                        color: _branchImageFile != null 
                            ? Colors.green[700]
                            : normalizedImageUrl != null && normalizedImageUrl.isNotEmpty
                                ? Colors.blue[700]
                                : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    if (normalizedImageUrl != null && normalizedImageUrl.isNotEmpty && _branchImageFile == null)
                      const Text(
                        'Click to change image',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _handleBranchImageUpload,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _branchImageFile != null 
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _branchImageFile != null ? Icons.check : Icons.camera_alt,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          // Display image preview (newly selected or existing)
          if (_branchImageFile != null || (normalizedImageUrl != null && normalizedImageUrl.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _branchImageFile != null
                    ? Image.file(
                        _branchImageFile!,
                        fit: BoxFit.cover,
                      )
                    : normalizedImageUrl != null && normalizedImageUrl.isNotEmpty
                        ? Image.network(
                            normalizedImageUrl,
                            fit: BoxFit.cover,
                            headers: const {
                              'Accept': 'image/*',
                            },
                            cacheWidth: 400,
                            cacheHeight: 400,
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
                              if (kDebugMode) print('=== Image Network Error ===');
                              if (kDebugMode) print('URL: $normalizedImageUrl');
                              if (kDebugMode) print('Error: $error');
                              if (kDebugMode) print('Stack: $stackTrace');
                              if (kDebugMode) print('==========================');
                              return Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                if (kDebugMode) print('=== Image Loaded Successfully ===');
                                if (kDebugMode) print('URL: $normalizedImageUrl');
                                if (kDebugMode) print('==================================');
                                return child;
                              }
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Upload a representative image for this branch. This will be displayed in branch listings and details.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 129, 124, 124),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildClassSelectionDropdown() {
    // Ensure we have unique classes by ID
    final uniqueAvailableClasses = _availableClasses
        .fold<List<StandaloneClassResponse>>([], (list, classItem) {
      if (!list.any((item) => item.id == classItem.id)) {
        list.add(classItem);
      }
      return list;
    });

    // Filter out already selected classes
    final availableForSelection = uniqueAvailableClasses
        .where((c) => !_selectedClasses.any((selected) => selected.id == c.id))
        .toList();



    // If no classes available, show a disabled dropdown
    if (availableForSelection.isEmpty) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Add Class',
          prefixIcon: const Icon(Icons.fitness_center, color: Colors.white),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        value: null,
        items: const [DropdownMenuItem<String>(value: null, child: Text('No more classes available'))],
        onChanged: null,
        hint: const Text('No more classes available'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.white),
                SizedBox(width: 12),
                Text('Add Class'),
              ],
            ),
          ),
          value: null,
          items: availableForSelection.isNotEmpty
              ? availableForSelection
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(c.name),
                        ),
                      ))
                  .toList()
              : const [DropdownMenuItem<String>(value: null, child: Text('No classes available'))],
          onChanged: (String? classId) {
            if (classId != null) {
              final selectedClass = availableForSelection.firstWhere((c) => c.id == classId);
              setState(() {
                _selectedClasses.add(selectedClass);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildAddTeamMemberForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _teamMemberNameController,
            label: 'Full Name',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTeamMemberRoleDropdown(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _teamMemberEmailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _teamMemberPhoneController,
            label: 'Phone',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _teamMemberPasswordController,
            label: 'Password',
            icon: Icons.lock,
            obscureText: _obscureTeamMemberPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureTeamMemberPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureTeamMemberPassword = !_obscureTeamMemberPassword;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _teamMemberConfirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: _obscureTeamMemberConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm password';
              }
              if (value != _teamMemberPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureTeamMemberConfirmPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureTeamMemberConfirmPassword = !_obscureTeamMemberConfirmPassword;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Password is required for all team members. Only team members with Admin or Viewer role can sign in to the branch portal.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addTeamMember,
            icon: const Icon(Icons.add),
            label: const Text('Add Member'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBranchImageUpload() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _branchImageFile = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e');
    }
  }

  Widget _buildTeamMemberRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTeamMemberRole,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              items: _teamMemberRoleOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option['value'],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option['subtitle'] ?? '',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) return;
                setState(() {
                  _selectedTeamMemberRole = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _addTeamMember() {
    if (_teamMemberNameController.text.isEmpty ||
        _teamMemberEmailController.text.isEmpty ||
        _teamMemberPhoneController.text.isEmpty ||
        _teamMemberPasswordController.text.isEmpty ||
        _teamMemberConfirmPasswordController.text.isEmpty ||
        _selectedTeamMemberRole.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    // Trim and validate password
    final password = _teamMemberPasswordController.text.trim();
    final confirmPassword = _teamMemberConfirmPasswordController.text.trim();
    
    // Validate password is not empty after trimming
    if (password.isEmpty) {
      _showSnackBar('Password cannot be empty');
      return;
    }

    // Password validation
    if (password.length < 8) {
      _showSnackBar('Password must be at least 8 characters');
      return;
    }

    // Password confirmation validation
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    final newMember = TeamMemberModel(
      fullName: _teamMemberNameController.text.trim(),
      email: _teamMemberEmailController.text.trim(),
      phoneNumber: _teamMemberPhoneController.text.trim(),
      countryCode: _selectedCountryCode,
      role: _selectedTeamMemberRole,
      password: password, // Use trimmed password
    );

    setState(() {
      _teamMembers.add(newMember);
      _showAddTeamMemberForm = false;
    });

    // Clear form
    _teamMemberNameController.clear();
    _teamMemberEmailController.clear();
    _teamMemberPhoneController.clear();
    _teamMemberPasswordController.clear();
    _teamMemberConfirmPasswordController.clear();
    _selectedTeamMemberRole = 'viewer';
    _obscureTeamMemberPassword = true;
    _obscureTeamMemberConfirmPassword = true;

    _showSnackBar('Team member added successfully');
  }

  Future<void> _removeTeamMember(int index) async {
    if (index < 0 || index >= _teamMembers.length) {
      return;
    }

    final member = _teamMembers[index];
    final isExistingMember = member.id != null && 
        _originalTeamMemberEmails.contains(member.email.toLowerCase());

    // If it's an existing member (has ID), call API to delete
    if (isExistingMember && member.id != null) {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Team Member'),
          content: Text('Are you sure you want to delete ${member.fullName}?'),
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

      if (confirm != true) {
        return;
      }

      // Show loading
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await ApiService.deleteTeamMember(
          widget.branch.id,
          member.id!,
          widget.accessToken,
        );

        if (result['success']) {
          setState(() {
            _teamMembers.removeAt(index);
            _originalTeamMemberEmails.remove(member.email.toLowerCase());
          });
          _showSnackBar('Team member deleted successfully');
        } else {
          _showSnackBar(result['message'] ?? 'Failed to delete team member');
        }
      } catch (e) {
        _showSnackBar('An error occurred: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // New member (no ID), just remove from list
      setState(() {
        _teamMembers.removeAt(index);
      });
      _showSnackBar('Team member removed');
    }
  }

  Future<void> _saveChanges() async {
    // Validate required fields
    if (_branchIdController.text.isEmpty ||
        _branchNameController.text.isEmpty ||
        _adminNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _locationController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    // Branch ID validation
    if (_branchIdController.text.length < 3) {
      _showSnackBar('Branch ID must be at least 3 characters');
      return;
    }

    // Check if Branch ID contains only alphanumeric characters
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(_branchIdController.text)) {
      _showSnackBar('Branch ID can only contain letters and numbers');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert StandaloneClassResponse to ClassModel
      final classModels = _selectedClasses.map((standaloneClass) => ClassModel(
        name: standaloneClass.name,
        description: standaloneClass.description,
        duration: standaloneClass.duration,
        capacity: standaloneClass.capacity,
        instructor: standaloneClass.instructor,
        schedule: standaloneClass.schedule, // Include the schedule from standalone class
        isVisible: standaloneClass.isVisible ?? true,
      )).toList();

      // Separate new team members (to be added via POST endpoint)
      // Backend UpdateBranch doesn't accept team members, so we'll add them separately
      final newTeamMembers = _teamMembers.where((member) {
        final isExistingMember = _originalTeamMemberEmails.contains(member.email.toLowerCase());
        // Include only new members that have non-empty passwords (trimmed)
        final hasValidPassword = member.password.trim().isNotEmpty && member.password.trim().length >= 8;
        return !isExistingMember && hasValidPassword;
      }).toList();
      
      // Additional safety check: Verify all new team members have valid passwords
      for (final member in newTeamMembers) {
        if (member.password.trim().isEmpty || member.password.trim().length < 8) {
          _showSnackBar('Invalid password for team member: ${member.email}');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Create update request (without team members - backend doesn't accept them)
      final updateRequest = UpdateBranchRequest(
        branchId: _branchIdController.text.trim(),
        branchName: _branchNameController.text.trim(),
        adminName: _adminNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        location: _locationController.text.trim(),
        image: _branchImageFile == null ? widget.branch.image : null, // Only include existing image URL if no new file
        classes: classModels,
        teamMembers: null, // Backend UpdateBranch doesn't accept team members
        isActive: true,
      );
      
      final updateRequestJson = updateRequest.toJson();

      // Debug: Print the request data
      if (kDebugMode) print('=== Update Branch Debug ===');
      if (kDebugMode) print('Branch ID: ${widget.branch.id}');
      if (kDebugMode) print('Total Team Members: ${_teamMembers.length}');
      if (kDebugMode) print('Original Team Members: ${_originalTeamMemberEmails.length}');
      if (kDebugMode) print('New Team Members (with passwords): ${newTeamMembers.length}');
      if (kDebugMode) print('Has new image file: ${_branchImageFile != null}');
      if (kDebugMode) print('Request data: ${jsonEncode(updateRequestJson)}');
      
      // Call API to update branch with image file if provided
      final result = await ApiService.updateBranch(
        widget.branch.id,
        updateRequestJson,
        widget.accessToken,
        imageFile: _branchImageFile,
      );

      if (result['success']) {
        // If branch update succeeded, add new team members via POST endpoint
        if (newTeamMembers.isNotEmpty) {
          int successCount = 0;
          int failCount = 0;
          
          for (final member in newTeamMembers) {
            try {
              final teamMemberRequest = {
                'full_name': member.fullName,
                'email': member.email,
                'phone_number': member.phoneNumber,
                'country_code': member.countryCode,
                'role': member.role,
                'password': member.password,
              };
              
              final addResult = await ApiService.addTeamMember(
                widget.branch.id,
                teamMemberRequest,
                widget.accessToken,
              );
              
              if (addResult['success']) {
                successCount++;
                // Update the member with the ID from response and mark as existing
                final responseData = addResult['data'];
                if (responseData != null && responseData['id'] != null) {
                  // Find and update the member in the list
                  for (int i = 0; i < _teamMembers.length; i++) {
                    if (_teamMembers[i].email == member.email && 
                        _teamMembers[i].id == null) {
                      _teamMembers[i] = TeamMemberModel(
                        id: responseData['id'].toString(),
                        fullName: member.fullName,
                        email: member.email,
                        phoneNumber: member.phoneNumber,
                        countryCode: member.countryCode,
                        role: member.role,
                        password: member.password,
                      );
                      _originalTeamMemberEmails.add(member.email.toLowerCase());
                      break;
                    }
                  }
                }
              } else {
                failCount++;
                if (kDebugMode) print('Failed to add team member ${member.email}: ${addResult['message']}');
              }
            } catch (e) {
              failCount++;
              if (kDebugMode) print('Error adding team member ${member.email}: $e');
            }
          }
          
          if (mounted) {
            if (failCount == 0) {
              _showSnackBar('Branch updated and ${successCount} team member(s) added successfully');
            } else {
              _showSnackBar('Branch updated. ${successCount} team member(s) added, ${failCount} failed');
            }
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        } else {
          if (mounted) {
            _showSnackBar('Branch updated successfully');
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        }
      } else {
        if (mounted) {
          _showSnackBar(result['message'] ?? 'Failed to update branch');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
