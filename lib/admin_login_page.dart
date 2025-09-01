import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'create_branch_page.dart';
import 'services/api_service.dart';
import 'branch_forgot_password_page.dart';
import 'branch_dashboard_page.dart';
import 'super_admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedAdminType = 'Branch';
  bool _isLoading = false;
  bool _obscurePassword = true; // Add this line for password visibility toggle

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 30),
              child: Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 0),
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
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Admin Login title
                    const Text(
                      'ADMIN LOGIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    const Text(
                      'Access administrative controls',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Admin type selection
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
                                items: ['Branch', 'Super Admin'].map((String value) {
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
                    
                    const SizedBox(height: 32),
                    
                    // Username field
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
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Password field
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
                              Icons.lock,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword, // Use the boolean variable
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          // Add show/hide password toggle button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Forgot Password link (only for Branch Admin)
                    if (_selectedAdminType == 'Branch') ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BranchForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    
                   
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: MediaQuery.of(context).size.width *0.6,
                      height: 80,
                      child: GestureDetector(
                        onTap: _isLoading ? null : () async {
                          await _handleLogin();
                        },
                        child: _isLoading
                            ? Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
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
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    
                    
                    
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Validate inputs
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;
      
      if (_selectedAdminType == 'Super Admin') {
        // Add debug logging for SuperAdmin login
        print('=== SuperAdmin Login Debug ===');
        print('Username/Email: ${_usernameController.text}');
        print('Password: ${_passwordController.text.isNotEmpty ? '[HIDDEN]' : '[EMPTY]'}');
        print('Calling ApiService.superAdminLogin...');
        
        // Call SuperAdmin login API
        result = await ApiService.superAdminLogin(
          _usernameController.text,
          _passwordController.text,
        );
        
        print('SuperAdmin login result: $result');
      } else if (_selectedAdminType == 'Branch') {
        // Call Branch Admin login API
        result = await ApiService.branchLogin(
          _usernameController.text,
          _passwordController.text,
        );
      } else {
        // Call regular admin login API
        result = await ApiService.adminLogin(
          _usernameController.text,
          _passwordController.text,
        );
      }

      if (result['success']) {
        // Login successful
        _showSnackBar(result['message'] ?? 'Login successful!');
        
        // Store user data and token
        final userData = result['data'];
        
        if (_selectedAdminType == 'Branch') {
          print('Admin login successful for: ${userData['branch']['email']}');
          print('Branch Name: ${userData['branch']['branch_name']}');
          print('Access Token: ${userData['access_token']}');
          
          // Navigate to branch dashboard
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BranchDashboardPage(
                branchData: userData,
                accessToken: userData['access_token'],
              ),
            ),
          );
        } else if (_selectedAdminType == 'Super Admin') {
          print('Super Admin login successful for: ${userData['user']['email']}');
          print('Access Token: ${userData['access_token']}');
          
          // Navigate to SuperAdmin dashboard
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SuperAdminDashboardPage(
                accessToken: userData['access_token'],
                userEmail: userData['user']['email'],
              ),
            ),
          );
        } else {
          print('Regular admin login successful for: ${userData['user']['email']}');
          print('Access Token: ${userData['access_token']}');
        }
        
        // Clear form
        _usernameController.clear();
        _passwordController.clear();
      } else {
        // Login failed
        _showSnackBar(result['message'] ?? 'Login failed');
        print('Login error: ${result['error']}');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
      print('Exception during login: $e');
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