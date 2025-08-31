import 'package:flutter/material.dart';
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
  final TextEditingController _teamMemberRoleController = TextEditingController();
  String _selectedCountryCode = '+1';
  bool _showAddTeamMemberForm = false;


  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
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
        final classListResponse = StandaloneClassListResponse.fromJson(data);
        
        setState(() {
          _availableClasses = classListResponse.classes.where((c) => c.isActive).toList();
        });
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

  @override
  void dispose() {
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
    _teamMemberRoleController.dispose();
    
    super.dispose();
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
                                        // Name and Email Row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTeamMemberInputField(
                                                controller: _teamMemberNameController,
                                                hintText: 'Full Name',
                                                icon: Icons.person,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _buildTeamMemberInputField(
                                                controller: _teamMemberEmailController,
                                                hintText: 'Email',
                                                icon: Icons.email,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Phone and Role Row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTeamMemberInputField(
                                                controller: _teamMemberPhoneController,
                                                hintText: 'Phone Number',
                                                icon: Icons.phone,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _buildTeamMemberInputField(
                                                controller: _teamMemberRoleController,
                                                hintText: 'Role',
                                                icon: Icons.work,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Country Code and Add Button
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
                                                items: ['+1', '+44', '+33', '+49', '+81', '+86', '+91', '+971']
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
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Team Members List
                                if (_teamMembers.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _teamMembers.length,
                                      itemBuilder: (context, index) {
                                        final member = _teamMembers[index];
                                        return ListTile(
                                          title: Text(
                                            member.fullName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${member.role} • ${member.email}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${member.countryCode}${member.phoneNumber}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _removeTeamMember(index),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
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
                          
                          const SizedBox(height: 32),
                          
                          // Branch Setup Info
                          _buildSectionTitle('Branch Setup'),
                          const SizedBox(height: 16),
                          
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
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Branch Setup Information',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'After branch creation, you can assign existing classes and add team members through the branch management interface.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
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
                          
                          const SizedBox(height: 40),
                        ],
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
    if (_branchNameController.text.isEmpty ||
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

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert selected classes to ClassModel format
      final selectedClassModels = _selectedClasses.map((standaloneClass) => ClassModel(
        name: standaloneClass.name,
        description: standaloneClass.description,
        duration: 60, // Default duration for branch classes
        capacity: standaloneClass.capacity,
        instructor: standaloneClass.instructor,
      )).toList();

      // Create branch request data
      final branchData = CreateBranchRequest(
        branchName: _branchNameController.text,
        adminName: _adminNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text,
        location: _locationController.text,
        classes: selectedClassModels,
        teamMembers: _teamMembers,
      );

      // Call API to create branch
      final result = await ApiService.createBranch(
        branchData.toJson(),
        widget.accessToken,
      );

      if (result['success']) {
        _showSnackBar(result['message'] ?? 'Branch created successfully!');
        
        // Clear form
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
        
        // Navigate back or show success page
        Navigator.pop(context);
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
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTeamMember() {
    // Validate inputs
    if (_teamMemberNameController.text.isEmpty ||
        _teamMemberEmailController.text.isEmpty ||
        _teamMemberPhoneController.text.isEmpty ||
        _teamMemberRoleController.text.isEmpty) {
      _showSnackBar('Please fill in all team member fields');
      return;
    }

    // Basic email validation
    if (!_teamMemberEmailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    // Create team member
    final teamMember = TeamMemberModel(
      fullName: _teamMemberNameController.text,
      email: _teamMemberEmailController.text,
      phoneNumber: _teamMemberPhoneController.text,
      countryCode: _selectedCountryCode,
      role: _teamMemberRoleController.text,
    );

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
      _teamMembers.removeAt(index);
    });
    _showSnackBar('Team member removed');
  }

  void _clearTeamMemberForm() {
    _teamMemberNameController.clear();
    _teamMemberEmailController.clear();
    _teamMemberPhoneController.clear();
    _teamMemberRoleController.clear();
    _selectedCountryCode = '+1';
  }
}
