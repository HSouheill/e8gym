import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CreateAdminPage extends StatefulWidget {
  const CreateAdminPage({super.key});

  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _selectedAdminType = 'Admin';
  bool _canManageUsers = false;
  bool _canManageContent = false;
  bool _canViewAnalytics = false;
  bool _canManageSettings = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                Color(0x50000000), // Dark overlay for better text readability
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
                          'Create New Admin',
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
                          // Admin type selection
                          _buildSectionTitle('Admin Type'),
                          Container(
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
                                  child: const Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedAdminType,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: ['Admin', 'Super Admin'].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedAdminType = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Full Name field
                          _buildSectionTitle('Full Name'),
                          _buildInputField(
                            controller: _fullNameController,
                            hintText: 'Enter full name',
                            icon: Icons.person,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Email field
                          _buildSectionTitle('Email Address'),
                          _buildInputField(
                            controller: _emailController,
                            hintText: 'Enter email address',
                            icon: Icons.email,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Password field
                          _buildSectionTitle('Password'),
                          _buildInputField(
                            controller: _passwordController,
                            hintText: 'Enter password',
                            icon: Icons.lock,
                            isPassword: true,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Confirm Password field
                          _buildSectionTitle('Confirm Password'),
                          _buildInputField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Permissions section
                          _buildSectionTitle('Permissions'),
                          const SizedBox(height: 16),
                          
                          _buildPermissionCheckbox(
                            'Manage Users',
                            'Can add, edit, and delete user accounts',
                            _canManageUsers,
                            (value) => setState(() => _canManageUsers = value!),
                          ),
                          
                          _buildPermissionCheckbox(
                            'Manage Content',
                            'Can create, edit, and delete app content',
                            _canManageContent,
                            (value) => setState(() => _canManageContent = value!),
                          ),
                          
                          _buildPermissionCheckbox(
                            'View Analytics',
                            'Can access user statistics and reports',
                            _canViewAnalytics,
                            (value) => setState(() => _canViewAnalytics = value!),
                          ),
                          
                          _buildPermissionCheckbox(
                            'Manage Settings',
                            'Can modify app configuration',
                            _canManageSettings,
                            (value) => setState(() => _canManageSettings = value!),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Create Admin button
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 56,
                            child: GestureDetector(
                              onTap: () {
                                _createAdmin();
                              },
                              child: SvgPicture.asset(
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
              obscureText: isPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCheckbox(
    String title,
    String description,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF8BB0C),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFF8BB0C),
            checkColor: Colors.black,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
    );
  }

  void _createAdmin() {
    // Validate inputs
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    // Create admin logic here
    print('Creating new admin:');
    print('Type: $_selectedAdminType');
    print('Name: ${_fullNameController.text}');
    print('Email: ${_emailController.text}');
    print('Permissions:');
    print('- Manage Users: $_canManageUsers');
    print('- Manage Content: $_canManageContent');
    print('- View Analytics: $_canViewAnalytics');
    print('- Manage Settings: $_canManageSettings');

    // Show success message
    _showSnackBar('Admin account created successfully!');
    
    // Clear form
    _fullNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _canManageUsers = false;
      _canManageContent = false;
      _canViewAnalytics = false;
      _canManageSettings = false;
    });
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
