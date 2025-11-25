import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';
import 'models/standalone_class_models.dart';

class CreateBranchPage extends StatefulWidget {
  final String accessToken;
  
  const CreateBranchPage({
    super.key,
    required this.accessToken,
  });

  @override
  State<CreateBranchPage> createState() => _CreateBranchPageState();
}

class _CreateBranchPageState extends State<CreateBranchPage> {
  final TextEditingController _branchIdController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Class selection
  List<StandaloneClassResponse> _availableClasses = [];
  List<StandaloneClassResponse> _selectedClasses = [];
  bool _isLoadingClasses = false;
  
  // Team member management
  List<TeamMemberModel> _teamMembers = [];
  final TextEditingController _teamMemberNameController = TextEditingController();
  final TextEditingController _teamMemberEmailController = TextEditingController();
  final TextEditingController _teamMemberPhoneController = TextEditingController();
  final TextEditingController _teamMemberPasswordController = TextEditingController();
  final TextEditingController _teamMemberConfirmPasswordController = TextEditingController();
  String _selectedCountryCode = '+1';
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
  Map<String, File?> _teamMemberImages = {}; // teamMemberId -> File
  bool _isUploadingBranchImage = false;
  Map<String, bool> _isUploadingTeamMemberImages = {}; // teamMemberId -> bool
  
  // Background image
  String? _backgroundImageUrl;


  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _loadAvailableClasses();
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

  Future<void> _loadAvailableClasses() async {
    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final result = await ApiService.getStandaloneClasses(
        widget.accessToken,
        limit: 100, // Get more classes for selection
      );

      if (result['success']) {
        final data = result['data'];
        if (data != null) {
          try {
            final classListResponse = StandaloneClassListResponse.fromJson(data);
            
            setState(() {
              _availableClasses = classListResponse.classes.where((c) => c.isActive).toList();
            });
          } catch (parseError) {
            print('Error parsing class data: $parseError');
            _showSnackBar('Error parsing class data. Please try again.');
            setState(() {
              _availableClasses = [];
            });
          }
        } else {
          print('API returned null data for classes');
          setState(() {
            _availableClasses = [];
          });
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to load available classes');
        setState(() {
          _availableClasses = [];
        });
      }
    } catch (e) {
      print('Exception in _loadAvailableClasses: $e');
      _showSnackBar('An error occurred while loading classes: $e');
      setState(() {
        _availableClasses = [];
      });
    } finally {
      setState(() {
        _isLoadingClasses = false;
      });
    }
  }

  @override
  void dispose() {
    _branchIdController.dispose();
    _branchNameController.dispose();
    _adminNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
              child: Column(
                children: [
                  // Header with back button and title
                  Row(
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
                      const Expanded(
                        child: Text(
                          'Create New Branch',
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
                  
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Branch ID field
                          _buildSectionTitle('Branch ID'),
                          _buildInputField(
                            controller: _branchIdController,
                            hintText: 'Enter branch ID',
                            icon: Icons.tag,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Branch Name field
                          _buildSectionTitle('Branch Name'),
                          _buildInputField(
                            controller: _branchNameController,
                            hintText: 'Enter branch name',
                            icon: Icons.business,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Admin Name field
                          _buildSectionTitle('Branch Admin Name'),
                          _buildInputField(
                            controller: _adminNameController,
                            hintText: 'Enter admin full name',
                            icon: Icons.person,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Email field
                          _buildSectionTitle('Admin Email Address'),
                          _buildInputField(
                            controller: _emailController,
                            hintText: 'Enter admin email address',
                            icon: Icons.email,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Password field
                          _buildSectionTitle('Admin Password'),
                          _buildInputField(
                            controller: _passwordController,
                            hintText: 'Enter admin password',
                            icon: Icons.lock,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Confirm Password field
                          _buildSectionTitle('Confirm Admin Password'),
                          _buildInputField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm admin password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Phone Number field
                          _buildSectionTitle('Admin Phone Number'),
                          _buildInputField(
                            controller: _phoneNumberController,
                            hintText: 'Enter phone number (e.g., 5551234567)',
                            icon: Icons.phone,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Location field
                          _buildSectionTitle('Branch Location'),
                          _buildInputField(
                            controller: _locationController,
                            hintText: 'Enter branch location/address',
                            icon: Icons.location_on,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Branch Image Upload Section
                          _buildSectionTitle('Branch Image'),
                          Container(
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
                                    const Icon(
                                      Icons.image,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Branch Image',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _branchImageFile != null 
                                                ? 'Image selected' 
                                                : 'No image selected',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
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
                                          gradient: const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_branchImageFile != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _branchImageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                const Text(
                                  'Upload a representative image for this branch. This will be displayed in branch listings and details.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Class Selection
                          _buildSectionTitle('Import Existing Classes'),
                          Container(
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
                                    const Icon(
                                      Icons.fitness_center,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Available Classes (${_availableClasses.length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Selected: ${_selectedClasses.length} classes',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isLoadingClasses)
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
                                const SizedBox(height: 16),
                                if (_availableClasses.isNotEmpty) ...[
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _availableClasses.length,
                                      itemBuilder: (context, index) {
                                        final classData = _availableClasses[index];
                                        final isSelected = _selectedClasses.contains(classData);
                                        
                                        return ListTile(
                                          title: Text(
                                            classData.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${classData.instructor} • ${classData.capacity} people',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: Checkbox(
                                            value: isSelected,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedClasses.add(classData);
                                                } else {
                                                  _selectedClasses.remove(classData);
                                                }
                                              });
                                            },
                                            activeColor: const Color(0xFFF8BB0C),
                                            checkColor: Colors.black,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedClasses.remove(classData);
                                              } else {
                                                _selectedClasses.add(classData);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ] else if (!_isLoadingClasses) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'No available classes found',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Select classes to automatically assign to this branch. You can manage classes later through the branch management interface.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Team Members Section
                          _buildSectionTitle('Team Members'),
                          Container(
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
                                    const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Team Members (${_teamMembers.length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Add team members to this branch',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showAddTeamMemberForm = !_showAddTeamMemberForm;
                                          if (!_showAddTeamMemberForm) {
                                            _clearTeamMemberForm();
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _showAddTeamMemberForm 
                                              ? Colors.red.withOpacity(0.3)
                                              : const Color(0xFFF8BB0C),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          _showAddTeamMemberForm ? Icons.close : Icons.add,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Add Team Member Form
                                if (_showAddTeamMemberForm) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        // Full Name
                                        _buildTeamMemberInputField(
                                          controller: _teamMemberNameController,
                                          hintText: 'Full Name',
                                          icon: Icons.person,
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Email
                                        _buildTeamMemberInputField(
                                          controller: _teamMemberEmailController,
                                          hintText: 'Email',
                                          icon: Icons.email,
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Phone Number with Country Code
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                                              ),
                                              child: DropdownButton<String>(
                                                value: _selectedCountryCode,
                                                dropdownColor: Colors.black,
                                                style: const TextStyle(color: Colors.white),
                                                underline: Container(),
                                                items: [
                                                  '+1', '+7', '+20', '+27', '+30', '+31', '+32', '+33', '+34', '+36',
                                                  '+39', '+40', '+41', '+43', '+44', '+45', '+46', '+47', '+48', '+49',
                                                  '+51', '+52', '+53', '+54', '+55', '+56', '+57', '+58', '+60', '+61',
                                                  '+62', '+63', '+64', '+65', '+66', '+81', '+82', '+84', '+86', '+90',
                                                  '+91', '+92', '+93', '+94', '+95', '+98', '+212', '+213', '+216', '+218',
                                                  '+220', '+221', '+222', '+223', '+224', '+225', '+226', '+227', '+228', '+229',
                                                  '+230', '+231', '+232', '+233', '+234', '+235', '+236', '+237', '+238', '+239',
                                                  '+240', '+241', '+242', '+243', '+244', '+245', '+246', '+248', '+249', '+250',
                                                  '+251', '+252', '+253', '+254', '+255', '+256', '+257', '+258', '+260', '+261',
                                                  '+262', '+263', '+264', '+265', '+266', '+267', '+268', '+269', '+290', '+291',
                                                  '+297', '+298', '+299', '+350', '+351', '+352', '+353', '+354', '+355', '+356',
                                                  '+357', '+358', '+359', '+370', '+371', '+372', '+373', '+374', '+375', '+376',
                                                  '+377', '+378', '+380', '+381', '+382', '+383', '+385', '+386', '+387', '+389',
                                                  '+420', '+421', '+423', '+500', '+501', '+502', '+503', '+504', '+505', '+506',
                                                  '+507', '+508', '+509', '+590', '+591', '+592', '+593', '+594', '+595', '+596',
                                                  '+597', '+598', '+599', '+670', '+672', '+673', '+674', '+675', '+676', '+677',
                                                  '+678', '+679', '+680', '+681', '+682', '+683', '+684', '+685', '+686', '+687',
                                                  '+688', '+689', '+690', '+691', '+692', '+850', '+852', '+853', '+855', '+856',
                                                  '+880', '+886', '+960', '+961', '+962', '+963', '+964', '+965', '+966', '+967',
                                                  '+968', '+970', '+971', '+972', '+973', '+974', '+975', '+976', '+977', '+992',
                                                  '+993', '+994', '+995', '+996', '+998'
                                                ]
                                                    .map((code) => DropdownMenuItem(
                                                          value: code,
                                                          child: Text(code),
                                                        ))
                                                    .toList(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    _selectedCountryCode = newValue!;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _buildTeamMemberInputField(
                                                controller: _teamMemberPhoneController,
                                                hintText: 'Phone Number',
                                                icon: Icons.phone,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Role
                                        _buildTeamMemberRoleDropdown(),
                                        const SizedBox(height: 16),
                                        
                                        // Password
                                        _buildTeamMemberInputField(
                                          controller: _teamMemberPasswordController,
                                          hintText: 'Password',
                                          icon: Icons.lock,
                                          isPassword: true,
                                          obscureText: _obscureTeamMemberPassword,
                                          onToggleVisibility: () {
                                            setState(() {
                                              _obscureTeamMemberPassword = !_obscureTeamMemberPassword;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Confirm Password
                                        _buildTeamMemberInputField(
                                          controller: _teamMemberConfirmPasswordController,
                                          hintText: 'Confirm Password',
                                          icon: Icons.lock_outline,
                                          isPassword: true,
                                          obscureText: _obscureTeamMemberConfirmPassword,
                                          onToggleVisibility: () {
                                            setState(() {
                                              _obscureTeamMemberConfirmPassword = !_obscureTeamMemberConfirmPassword;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Password is required for all team members. Only team members with Admin or Viewer role can sign in to the branch portal.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Add Button
                                        SizedBox(
                                          width: double.infinity,
                                          child: GestureDetector(
                                            onTap: _addTeamMember,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Add Team Member',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Team Members List
                                if (_teamMembers.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _teamMembers.length,
                                      itemBuilder: (context, index) {
                                        final member = _teamMembers[index];
                                        final memberId = 'temp_$index';
                                        final hasImage = _teamMemberImages[memberId] != null;
                                        
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              // Team member image or placeholder
                                              GestureDetector(
                                                onTap: () => _handleTeamMemberImageUpload(memberId),
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF8BB0C),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: hasImage
                                                      ? ClipRRect(
                                                          borderRadius: BorderRadius.circular(20),
                                                          child: Image.file(
                                                            _teamMemberImages[memberId]!,
                                                            fit: BoxFit.cover,
                                                            width: 40,
                                                            height: 40,
                                                          ),
                                                        )
                                                      : Text(
                                                          member.fullName[0].toUpperCase(),
                                                          style: const TextStyle(
                                                            color: Colors.black,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              
                                              // Team member info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                            member.fullName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                            ),
                                          ),
                                                    Text(
                                                      '${member.role.toUpperCase()} • ${member.email}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                              Text(
                                                '${member.countryCode}${member.phoneNumber}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Action buttons
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Image upload button
                                                  GestureDetector(
                                                    onTap: () => _handleTeamMemberImageUpload(memberId),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: hasImage 
                                                            ? Colors.green.withOpacity(0.3)
                                                            : const Color(0xFFF8BB0C),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Icon(
                                                        hasImage ? Icons.check : Icons.camera_alt,
                                                        color: Colors.black,
                                                        size: 16,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                                  
                                                  // Delete button
                                              GestureDetector(
                                                onTap: () => _removeTeamMember(index),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                        size: 16,
                                                      ),
                                                ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ] else if (!_showAddTeamMemberForm) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'No team members added yet',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 8),
                                Text(
                                  'Add team members who will work at this branch. You can manage team members later through the branch management interface.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          
                          
                          
                          const SizedBox(height: 40),
                          
                          // Create Branch button
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 56,
                            child: GestureDetector(
                              onTap: _isLoading ? null : () {
                                _createBranch();
                              },
                              child: _isLoading
                                  ? Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFDBA50B).withOpacity(0.3),
                                            offset: const Offset(0, 5),
                                            blurRadius: 7,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Create Branch',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFF8BB0C),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          if (isPassword && onToggleVisibility != null)
            IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  void _createBranch() async {
    // Validate inputs
    if (_branchIdController.text.isEmpty ||
        _branchNameController.text.isEmpty ||
        _adminNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _locationController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showSnackBar('Password must be at least 8 characters');
      return;
    }

    // Basic email validation
    if (!_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email address');
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

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert selected classes to ClassModel format
      final selectedClassModels = _selectedClasses.map((standaloneClass) => ClassModel(
        name: standaloneClass.name,
        description: standaloneClass.description,
        duration: standaloneClass.duration,
        capacity: standaloneClass.capacity,
        instructor: standaloneClass.instructor,
        schedule: standaloneClass.schedule, // Include the schedule from the original class
        isVisible: standaloneClass.isVisible ?? true,
      )).toList();

      // Create branch request data
      final branchData = CreateBranchRequest(
        branchID: _branchIdController.text,
        branchName: _branchNameController.text,
        adminName: _adminNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text,
        location: _locationController.text,
        classes: selectedClassModels,
        teamMembers: _teamMembers,
      );

      // Debug: Print the posted data
      print('=== Branch Creation Debug ===');
      print('Team Members Count: ${_teamMembers.length}');
      for (int i = 0; i < _teamMembers.length; i++) {
        final memberJson = _teamMembers[i].toJson();
        print('Team Member $i: $memberJson');
        print('  - Has password field: ${memberJson.containsKey('password')}');
        print('  - Password value: ${memberJson['password']}');
        print('  - Password is empty: ${memberJson['password']?.toString().isEmpty ?? true}');
      }
      print('Branch Data JSON:');
      final branchJson = branchData.toJson();
      print(jsonEncode(branchJson));
      // Also check team_members in the final JSON
      if (branchJson['team_members'] != null) {
        final teamMembersList = branchJson['team_members'] as List;
        for (int i = 0; i < teamMembersList.length; i++) {
          final member = teamMembersList[i] as Map<String, dynamic>;
          print('Final JSON Team Member $i password: ${member['password']}');
          print('Final JSON Team Member $i has password key: ${member.containsKey('password')}');
        }
      }
      print('============================');

      // Call API to create branch
      final result = await ApiService.createBranch(
        branchData.toJson(),
        widget.accessToken,
      );

      if (result['success']) {
        _showSnackBar(result['message'] ?? 'Branch created successfully!');
        
        // Get the created branch ID for image uploads
        final branchId = result['data']['id'] ?? result['data']['_id'];
        
        // Upload branch image if selected
        if (_branchImageFile != null && branchId != null) {
          await _uploadBranchImageAfterCreation(branchId);
        }
        
        // Upload team member images if selected
        if (_teamMemberImages.isNotEmpty && branchId != null) {
          // Get the created team members from the response
          final createdTeamMembers = result['data']['team_members'] as List<dynamic>? ?? [];
          
          for (int i = 0; i < _teamMemberImages.length && i < createdTeamMembers.length; i++) {
            final tempId = 'temp_$i';
            final imageFile = _teamMemberImages[tempId];
            final teamMemberId = createdTeamMembers[i]['id'] ?? createdTeamMembers[i]['_id'];
            
            if (imageFile != null && teamMemberId != null) {
              await _uploadTeamMemberImageAfterCreation(branchId, teamMemberId);
            }
          }
        }
        
        // Clear form
        _branchIdController.clear();
        _branchNameController.clear();
        _adminNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _phoneNumberController.clear();
        _locationController.clear();
        
        // Clear selected classes
        setState(() {
          _selectedClasses.clear();
        });
        
        // Clear team members
        setState(() {
          _teamMembers.clear();
        });
        
        // Clear images
        setState(() {
          _branchImageFile = null;
          _teamMemberImages.clear();
        });
        
        // Navigate back with success indicator
        Navigator.pop(context, true);
      } else {
        _showSnackBar(result['message'] ?? 'Failed to create branch');
        print('Branch creation error: ${result['error']}');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
      print('Exception during branch creation: $e');
    } finally {
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    }
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

  // Team Member Management Methods
  Widget _buildTeamMemberInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFF8BB0C),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          if (isPassword && onToggleVisibility != null)
            IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF8BB0C),
              width: 1.5,
            ),
            color: Colors.black.withOpacity(0.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTeamMemberRole,
              isExpanded: true,
              dropdownColor: Colors.black,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              style: const TextStyle(
                color: Colors.white,
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option['subtitle'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
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
    // Validate inputs
    if (_teamMemberNameController.text.isEmpty ||
        _teamMemberEmailController.text.isEmpty ||
        _teamMemberPhoneController.text.isEmpty ||
        _teamMemberPasswordController.text.isEmpty ||
        _teamMemberConfirmPasswordController.text.isEmpty ||
        _selectedTeamMemberRole.isEmpty) {
      _showSnackBar('Please fill in all team member fields');
      return;
    }

    // Basic email validation
    if (!_teamMemberEmailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    // Password validation
    if (_teamMemberPasswordController.text.length < 8) {
      _showSnackBar('Password must be at least 8 characters');
      return;
    }

    // Password confirmation validation
    if (_teamMemberPasswordController.text != _teamMemberConfirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    // Validate password is not empty (double check)
    final password = _teamMemberPasswordController.text.trim();
    if (password.isEmpty) {
      _showSnackBar('Password cannot be empty');
      return;
    }

    // Create team member
    final teamMember = TeamMemberModel(
      fullName: _teamMemberNameController.text.trim(),
      email: _teamMemberEmailController.text.trim(),
      phoneNumber: _teamMemberPhoneController.text.trim(),
      countryCode: _selectedCountryCode,
      role: _selectedTeamMemberRole,
      password: password, // Use trimmed password
    );
    
    // Debug: Verify password is included
    print('=== Team Member Creation Debug ===');
    print('Team Member JSON: ${teamMember.toJson()}');
    print('Password in JSON: ${teamMember.toJson()['password']}');
    print('Password length: ${password.length}');
    print('Password is empty: ${password.isEmpty}');
    print('==================================');

    setState(() {
      _teamMembers.add(teamMember);
    });

    // Clear form and hide it
    _clearTeamMemberForm();
    setState(() {
      _showAddTeamMemberForm = false;
    });

    _showSnackBar('Team member added successfully!');
  }

  void _removeTeamMember(int index) {
    setState(() {
      // Remove the team member
      _teamMembers.removeAt(index);
      
      // Reindex the remaining images
      final updatedImages = <String, File?>{};
      for (int i = 0; i < _teamMembers.length; i++) {
        // If we're at or after the removed index, look for the image that was one position higher
        final oldKey = i >= index ? 'temp_${i + 1}' : 'temp_$i';
        if (_teamMemberImages.containsKey(oldKey)) {
          updatedImages['temp_$i'] = _teamMemberImages[oldKey];
        }
      }
      _teamMemberImages = updatedImages;
    });
    _showSnackBar('Team member removed');
  }

  void _clearTeamMemberForm() {
    _teamMemberNameController.clear();
    _teamMemberEmailController.clear();
    _teamMemberPhoneController.clear();
    _teamMemberPasswordController.clear();
    _teamMemberConfirmPasswordController.clear();
    _selectedCountryCode = '+1';
    _selectedTeamMemberRole = 'viewer';
    _obscureTeamMemberPassword = true;
    _obscureTeamMemberConfirmPassword = true;
  }

  // Image Upload Methods
  Future<void> _handleBranchImageUpload() async {
    if (_isUploadingBranchImage) return;

    // Show image source selection dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Branch Image'),
        content: const Text('Choose where to pick the branch image from'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _branchImageFile = File(image.path);
      });

      _showSnackBar('Branch image selected successfully!');
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }
  }

  Future<void> _handleTeamMemberImageUpload(String teamMemberId) async {
    if (_isUploadingTeamMemberImages[teamMemberId] == true) return;

    // Show image source selection dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Team Member Image'),
        content: const Text('Choose where to pick the team member image from'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _teamMemberImages[teamMemberId] = File(image.path);
      });

      _showSnackBar('Team member image selected successfully!');
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }
  }

  Future<void> _uploadBranchImageAfterCreation(String branchId) async {
    if (_branchImageFile == null) return;

    setState(() {
      _isUploadingBranchImage = true;
    });

    try {
      final result = await ApiService.uploadBranchImage(
        branchId,
        _branchImageFile!,
        widget.accessToken,
      );

      if (result['success']) {
        _showSnackBar('Branch image uploaded successfully!');
      } else {
        _showSnackBar(result['message'] ?? 'Failed to upload branch image');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBranchImage = false;
        });
      }
    }
  }

  Future<void> _uploadTeamMemberImageAfterCreation(String branchId, String teamMemberId) async {
    final imageFile = _teamMemberImages[teamMemberId];
    if (imageFile == null) return;

    setState(() {
      _isUploadingTeamMemberImages[teamMemberId] = true;
    });

    try {
      final result = await ApiService.uploadTeamMemberImage(
        branchId,
        teamMemberId,
        imageFile,
        widget.accessToken,
      );

      if (result['success']) {
        _showSnackBar('Team member image uploaded successfully!');
      } else {
        _showSnackBar(result['message'] ?? 'Failed to upload team member image');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingTeamMemberImages[teamMemberId] = false;
        });
      }
    }
  }
}
