import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';

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
  final TextEditingController _countryCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Sample data for classes and team members
  List<ClassModel> _classes = [];
  List<TeamMemberModel> _teamMembers = [];

  @override
  void initState() {
    super.initState();
    _countryCodeController.text = '+1'; // Default country code
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Add some sample classes
    _classes = [
      ClassModel(
        name: 'Yoga Basics',
        description: 'Introduction to yoga for beginners',
        duration: 60,
        capacity: 20,
        schedule: [
          ClassSchedule(
            dayOfWeek: 1, // Monday
            startTime: DateTime(2024, 1, 1, 9, 0), // 9:00 AM
            endTime: DateTime(2024, 1, 1, 10, 0), // 10:00 AM
          ),
        ],
        instructor: 'Sarah Johnson',
        isActive: true,
      ),
      ClassModel(
        name: 'HIIT Training',
        description: 'High-intensity interval training',
        duration: 45,
        capacity: 15,
        schedule: [
          ClassSchedule(
            dayOfWeek: 2, // Tuesday
            startTime: DateTime(2024, 1, 1, 17, 0), // 5:00 PM
            endTime: DateTime(2024, 1, 1, 17, 45), // 5:45 PM
          ),
        ],
        instructor: 'Mike Chen',
        isActive: true,
      ),
    ];

    // Add some sample team members
    _teamMembers = [
      TeamMemberModel(
        fullName: 'Alex Rodriguez',
        email: 'alex@e8gym.com',
        phoneNumber: '555-0101',
        countryCode: '+1',
        role: 'Trainer',
        isActive: true,
      ),
      TeamMemberModel(
        fullName: 'Emma Wilson',
        email: 'emma@e8gym.com',
        phoneNumber: '555-0102',
        countryCode: '+1',
        role: 'Receptionist',
        isActive: true,
      ),
    ];
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _adminNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _countryCodeController.dispose();
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
                            hintText: 'Enter phone number',
                            icon: Icons.phone,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Country Code field
                          _buildSectionTitle('Country Code'),
                          _buildInputField(
                            controller: _countryCodeController,
                            hintText: 'Enter country code (e.g., +1)',
                            icon: Icons.flag,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Classes and Team Members info
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
                                      Icons.fitness_center,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Sample Classes (${_classes.length})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Yoga Basics, HIIT Training, and more will be automatically added to this branch.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
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
                                      Icons.people,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Sample Team Members (${_teamMembers.length})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Trainer and receptionist roles will be automatically added to this branch.',
                                  style: const TextStyle(
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
                                  : SvgPicture.asset(
                                      'assets/img/Button.svg',
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      height: 56,
                                      fit: BoxFit.contain,
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
        _countryCodeController.text.isEmpty) {
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
      // Create branch request data
      final branchData = CreateBranchRequest(
        branchName: _branchNameController.text,
        adminName: _adminNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text,
        countryCode: _countryCodeController.text,
        classes: _classes,
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
        _countryCodeController.text = '+1';
        
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
}
