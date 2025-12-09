import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'branch_dashboard_page.dart';
import 'branch_forgot_password_page.dart';
import 'utils/app_colors.dart';

class BranchLoginPage extends StatefulWidget {
  const BranchLoginPage({super.key});

  @override
  State<BranchLoginPage> createState() => _BranchLoginPageState();
}

class _BranchLoginPageState extends State<BranchLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
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
            colors: [Colors.white, Colors.white70],
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
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 30),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
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
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Branch Login title
                  const Text(
                    'BRANCH LOGIN',
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
                    'Access your branch dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Email field
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white,
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
                              colors: [Colors.white, Colors.white70],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.email,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Enter your email address',
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
                          color: Colors.white,
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
                              colors: [Colors.white, Colors.white70],
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
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Forgot Password link
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
                  
                  const SizedBox(height: 40),
                  
                  // Login button
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
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
                                  colors: [Colors.white, Colors.white70],
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
                          : Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white, Colors.white70],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDBA50B).withOpacity(0.3),
                                    offset: const Offset(0, 3),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
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
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
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
      // Call Branch Admin login API (supports both branch admin and team member login)
      print('Attempting Branch Admin/Team Member login for ${_emailController.text}');
      final result = await ApiService.branchLogin(
        _emailController.text,
        _passwordController.text,
      );

      if (result['success']) {
        // Login successful
        _showSnackBar(result['message'] ?? 'Login successful!');
        
        // Store user data and token
        final userData = result['data'];
        
        // Validate that we have the required data
        if (userData == null || userData['branch'] == null || userData['access_token'] == null) {
          _showSnackBar('Invalid response from server. Please try again.');
          return;
        }
        
        final branchData = userData['branch'];
        final branchEmail = branchData['email'];
        final loginEmail = _emailController.text.toLowerCase();
        
        // Determine if this is a team member login or branch admin login
        final isTeamMemberLogin = loginEmail != branchEmail.toLowerCase();
        
        // Determine user role and permissions
        bool canEdit = true; // Branch admin can always edit
        String? userRole;
        
        if (isTeamMemberLogin) {
          print('Team member login successful for: $loginEmail');
          // Find the team member in the branch data
          final teamMembers = branchData['team_members'] as List? ?? [];
          try {
            final teamMember = teamMembers.firstWhere(
              (member) => (member['email'] as String?)?.toLowerCase() == loginEmail,
            ) as Map<String, dynamic>?;
            if (teamMember != null) {
              print('Team Member Name: ${teamMember['full_name']}');
              userRole = teamMember['role'] as String?;
              print('Team Member Role: $userRole');
              // Viewers cannot edit, only admins can
              canEdit = userRole?.toLowerCase() != 'viewer';
              print('Can Edit: $canEdit');
            }
          } catch (e) {
            print('Team member not found in branch data: $e');
            // If team member not found, default to no edit permissions
            canEdit = false;
          }
        } else {
          print('Branch admin login successful for: $branchEmail');
          // Branch admin can always edit
          canEdit = true;
        }
        
        print('Branch Name: ${branchData['branch_name'] ?? 'Unknown'}');
        print('Access Token: ${userData['access_token'] ?? 'No token'}');
        
        // Navigate to branch dashboard (works for both branch admin and team members)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BranchDashboardPage(
              branchData: userData,
              accessToken: userData['access_token'],
              canEdit: canEdit,
            ),
          ),
        );
        
        // Clear form
        _emailController.clear();
        _passwordController.clear();
      } else {
        // Login failed - error message already formatted by API service
        _showSnackBar(result['message'] ?? 'Login failed');
        print('Login error: ${result['error']}');
        print('Status code: ${result['statusCode']}');
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
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
