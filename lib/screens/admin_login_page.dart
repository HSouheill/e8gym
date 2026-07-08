import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'branch/branch_forgot_password_page.dart';
import 'branch/branch_dashboard_page.dart';
import 'super_admin/super_admin_dashboard_page.dart';
import '../main.dart';
import '../utils/app_colors.dart';
import 'package:flutter/foundation.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedAdminType = 'Super Admin';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Determine device size category
    final isSmallDevice = screenWidth < 400 || screenHeight < 700;
    final isLargeDevice = screenWidth > 600 || screenHeight > 1000;
    
    // Specific iPad 13-inch detection (iPad Pro 12.9" has resolution around 1024x1366)
    final isIPad13Inch = screenWidth >= 1000 && screenHeight >= 1300;
    
    final isBranchRelatedLogin = _selectedAdminType == 'Branch Admin';

    // Responsive sizing calculations
    final horizontalPadding = isIPad13Inch
        ? screenWidth * 0.05  // 5% for iPad 13-inch (minimal padding for full screen)
        : isSmallDevice 
            ? screenWidth * 0.06  // 6% for small devices
            : isLargeDevice 
                ? screenWidth * 0.03  // 3% for large devices
                : screenWidth * 0.04; // 4% for medium devices
    
    final spacingSmall = isIPad13Inch
        ? screenHeight * 0.005  // 0.5% for iPad 13-inch (extremely reduced)
        : isSmallDevice 
            ? screenHeight * 0.012  // 1.2% for small devices
            : isLargeDevice 
                ? screenHeight * 0.018  // 1.8% for large devices
                : screenHeight * 0.015; // 1.5% for medium devices
    
    final spacingMedium = isIPad13Inch
        ? screenHeight * 0.008  // 0.8% for iPad 13-inch (extremely reduced)
        : isSmallDevice 
            ? screenHeight * 0.018  // 1.8% for small devices
            : isLargeDevice 
                ? screenHeight * 0.025  // 2.5% for large devices
                : screenHeight * 0.02; // 2% for medium devices
    
    final spacingLarge = isIPad13Inch
        ? screenHeight * 0.012  // 1.2% for iPad 13-inch (extremely reduced)
        : isSmallDevice 
            ? screenHeight * 0.025  // 2.5% for small devices
            : isLargeDevice 
                ? screenHeight * 0.035  // 3.5% for large devices
                : screenHeight * 0.03; // 3% for medium devices
    
    // Responsive font sizes
    final fontSizeSmall = isIPad13Inch
        ? screenWidth * 0.028  // 1.8% for iPad 13-inch (much reduced)
        : isSmallDevice 
            ? screenWidth * 0.040  // 3.5% for small devices
            : isLargeDevice 
                ? screenWidth * 0.030  // 2.5% for large devices
                : screenWidth * 0.04; // 3% for medium devices
    
    final fontSizeMedium = isIPad13Inch
        ? screenWidth * 0.030  // 3% for iPad 13-inch (increased for better screen utilization)
        : isSmallDevice 
            ? screenWidth * 0.050  // 4.5% for small devices
            : isLargeDevice 
                ? screenWidth * 0.040  // 3.5% for large devices
                : screenWidth * 0.05; // 4% for medium devices
    
    final fontSizeLarge = isIPad13Inch
        ? screenWidth * 0.045  // 4.5% for iPad 13-inch (increased for better screen utilization)
        : isSmallDevice 
            ? screenWidth * 0.060  // 5.5% for small devices
            : isLargeDevice 
                ? screenWidth * 0.050  // 4.5% for large devices
                : screenWidth * 0.06; // 5% for medium devices
    
    // Responsive icon sizes
    final iconSizeMedium = isIPad13Inch
        ? screenWidth * 0.025  // 2.5% for iPad 13-inch (much reduced)
        : isSmallDevice 
            ? screenWidth * 0.050  // 4.5% for small devices
            : isLargeDevice 
                ? screenWidth * 0.040  // 3.5% for large devices
                : screenWidth * 0.05; // 4% for medium devices
    
    // Responsive button sizes - reduced for smaller button
    final buttonHeight = isIPad13Inch
        ? screenHeight * 0.06  // 5% for iPad 13-inch
        : isSmallDevice 
            ? screenHeight * 0.07  // 6% for small devices
            : isLargeDevice 
                ? screenHeight * 0.06   // 5% for large devices
                : screenHeight * 0.07; // 6% for medium devices
    
    final buttonWidth = isIPad13Inch
        ? screenWidth * 0.6  // 50% for iPad 13-inch
        : isSmallDevice 
            ? screenWidth * 0.6   // 50% for small devices
            : isLargeDevice 
                ? screenWidth * 0.6   // 40% for large devices
                : screenWidth * 0.60; // 45% for medium devices
    
    final backButtonSize = isIPad13Inch
        ? screenWidth * 0.07  // 5% for iPad 13-inch (much reduced)
        : isSmallDevice 
            ? screenWidth * 0.12  // 12% for small devices
            : isLargeDevice 
                ? screenWidth * 0.08  // 8% for large devices
                : screenWidth * 0.1; // 10% for medium devices

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white70],
          ),
        ),
        child: Stack(
          children: [
            // Static background
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0x90000000), // Dark overlay for better text readability
                  BlendMode.darken,
                ),
                child: Image.asset(
                  'assets/E8Logos/admin_login_background.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Return a dark container with gradient if image fails to load
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1a1a1a), Color(0xFF000000)],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Dark overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xA0000000), // Even darker overlay
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 0,
                  bottom: 50,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                    // Back button - Responsive sizing for better accessibility
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 0),
                          width: backButtonSize,
                          height: backButtonSize,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Colors.white70],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: backButtonSize * 0.6, // 60% of button size for icon
                          ),
                        ),
                      ),
                    ),
                    
                    // E8 Logo
                    Center(
                      child: Image.asset(
                        'assets/E8Logos/E8_Short_Logo.png',
                        width: screenWidth * (isIPad13Inch ? 0.25 : isSmallDevice ? 0.35 : isLargeDevice ? 0.25 : 0.3),
                        // height: screenWidth * (isIPad13Inch ? 0.25 : isSmallDevice ? 0.35 : isLargeDevice ? 0.25 : 0.3),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Show a placeholder if image fails to load
                          final logoSize = screenWidth * (isIPad13Inch ? 0.25 : isSmallDevice ? 0.35 : isLargeDevice ? 0.25 : 0.3);
                          return Container(
                            width: logoSize,
                            height: logoSize,
                            color: Colors.transparent,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white70,
                              size: logoSize * 0.3,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // SizedBox(height: spacingMedium),
                    
                    // Admin Login title
                    Text(
                      'ADMIN LOGIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    SizedBox(height: spacingSmall),
                    
                    // // Subtitle
                    // Text(
                    //   'Access administrative controls',
                    //   style: TextStyle(
                    //     color: Colors.white,
                    //     fontSize: fontSizeMedium,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    
                    SizedBox(height: isIPad13Inch ? spacingMedium : spacingLarge),
                    // SizedBox(height: 100),
                    // Admin type selection - Responsive sizing
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.all(screenWidth * (isIPad13Inch ? 0.01 : isSmallDevice ? 0.02 : isLargeDevice ? 0.015 : 0.018)),
                            child: Icon(
                              Icons.shield,
                              color: Colors.white,
                              size: iconSizeMedium,
                            ),
                          ),
                          SizedBox(width: screenWidth * (isIPad13Inch ? 0.02 : 0.04)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Type',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSizeSmall,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedAdminType,
                                    dropdownColor: Colors.black87,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: fontSizeMedium,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: ['Super Admin', 'Branch Admin'].map((String value) {
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isIPad13Inch ? spacingSmall : spacingMedium),
                    SizedBox(height: 20),
                    // Email field - Responsive sizing
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.all(screenWidth * (isIPad13Inch ? 0.01 : isSmallDevice ? 0.02 : isLargeDevice ? 0.015 : 0.018)),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: iconSizeMedium,
                            ),
                          ),
                          SizedBox(width: screenWidth * (isIPad13Inch ? 0.02 : 0.04)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSizeSmall,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextField(
                                    controller: _usernameController,
                                    enabled: !_isLoading,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofocus: false,
                                    style: TextStyle(color: Colors.white, fontSize: fontSizeSmall),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email',
                                      hintStyle: TextStyle(color: Colors.white70, fontSize: fontSizeSmall),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isIPad13Inch ? spacingSmall : spacingMedium),
                                        SizedBox(height: 20),

                    // Password field - Responsive sizing
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.all(screenWidth * (isIPad13Inch ? 0.01 : isSmallDevice ? 0.02 : isLargeDevice ? 0.015 : 0.018)),
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: iconSizeMedium,
                            ),
                          ),
                          SizedBox(width: screenWidth * (isIPad13Inch ? 0.02 : 0.04)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSizeSmall,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextField(
                                    controller: _passwordController,
                                    enabled: !_isLoading,
                                    obscureText: _obscurePassword,
                                    keyboardType: TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.done,
                                    autofocus: false,
                                    onSubmitted: (_) {
                                      if (!_isLoading) {
                                        _handleLogin();
                                      }
                                    },
                                    style: TextStyle(color: Colors.white, fontSize: fontSizeSmall),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your password',
                                      hintStyle: TextStyle(color: Colors.white70, fontSize: fontSizeSmall),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Add show/hide password toggle button - Responsive sizing
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * (isIPad13Inch ? 0.01 : isSmallDevice ? 0.02 : isLargeDevice ? 0.015 : 0.018)),
                              child: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                                size: iconSizeMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),

                    // Login button - Responsive sizing for better accessibility
                    Center(
                      child: SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            await _handleLogin();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                                    strokeWidth: screenWidth * (isSmallDevice ? 0.03 : isLargeDevice ? 0.008 : 0.0010),
                                  ),
                                )
                              : Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: spacingMedium),

                    // Forgot Password link (only for Branch Admin) - Improved accessibility for iPad
                    if (isBranchRelatedLogin) ...[
                      SizedBox(height: spacingSmall),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.008, // 0.8% vertical padding for larger touch target
                            horizontal: screenWidth * 0.02, // 2% horizontal padding
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BranchForgotPasswordPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.005, // 0.5% vertical padding
                                horizontal: screenWidth * 0.015, // 1.5% horizontal padding
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSizeSmall * (isSmallDevice ? 0.85 : isLargeDevice ? 0.75 : 0.8),
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Extra spacing for better scrolling - Responsive sizing
                    SizedBox(height: spacingLarge * 2),

                    ],
                  ),
                ),
              ),
            ),
          ],
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
      final isBranchRelatedLogin = _selectedAdminType == 'Branch Admin';
      
      if (_selectedAdminType == 'Super Admin') {
        // Add debug logging for SuperAdmin login
        if (kDebugMode) print('=== SuperAdmin Login Debug ===');
        if (kDebugMode) print('Username/Email: ${_usernameController.text}');
        if (kDebugMode) print('Password: ${_passwordController.text.isNotEmpty ? '[HIDDEN]' : '[EMPTY]'}');
        if (kDebugMode) print('Calling ApiService.superAdminLogin...');
        
        // Call SuperAdmin login API
        result = await ApiService.superAdminLogin(
          _usernameController.text,
          _passwordController.text,
        );
        
        if (kDebugMode) print('SuperAdmin login result: $result');
      } else if (isBranchRelatedLogin) {
        // Call Branch Admin login API (supports both branch admin and team member login)
        if (kDebugMode) print('Attempting Branch Admin/Team Member login for ${_usernameController.text}');
        result = await ApiService.branchLogin(
          _usernameController.text,
          _passwordController.text,
        );
        
        // Log additional details for debugging
        if (result['success']) {
          if (kDebugMode) print('Branch login successful');
          final branchData = result['data'];
          if (branchData != null && branchData['branch'] != null) {
            final branch = branchData['branch'];
            if (kDebugMode) print('Branch Name: ${branch['branch_name']}');
            if (kDebugMode) print('Branch Email: ${branch['email']}');
            // Check if this is a team member login by comparing login email with branch email
            final loginEmail = _usernameController.text.toLowerCase();
            final branchEmail = (branch['email'] as String?)?.toLowerCase() ?? '';
            if (loginEmail != branchEmail) {
              if (kDebugMode) print('Login as team member: $loginEmail');
            } else {
              if (kDebugMode) print('Login as branch admin: $loginEmail');
            }
          }
        } else {
          if (kDebugMode) print('Branch login failed: ${result['message']}');
          if (kDebugMode) print('Error details: ${result['error']}');
          if (kDebugMode) print('Status code: ${result['statusCode']}');
        }
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
        
        if (isBranchRelatedLogin) {
          final branchData = userData['branch'];
          final branchEmail = branchData['email'];
          final loginEmail = _usernameController.text.toLowerCase();
          
          // Determine if this is a team member login or branch admin login
          final isTeamMemberLogin = loginEmail != branchEmail.toLowerCase();
          
          // Determine user role and permissions
          bool canEdit = true; // Branch admin can always edit
          String? userRole;
          
          if (isTeamMemberLogin) {
            if (kDebugMode) print('Team member login successful for: $loginEmail');
            // Find the team member in the branch data
            final teamMembers = branchData['team_members'] as List? ?? [];
            try {
              final teamMember = teamMembers.firstWhere(
                (member) => (member['email'] as String?)?.toLowerCase() == loginEmail,
              ) as Map<String, dynamic>?;
              if (teamMember != null) {
                if (kDebugMode) print('Team Member Name: ${teamMember['full_name']}');
                userRole = teamMember['role'] as String?;
                if (kDebugMode) print('Team Member Role: $userRole');
                // Viewers cannot edit, only admins can
                canEdit = userRole?.toLowerCase() != 'viewer';
                if (kDebugMode) print('Can Edit: $canEdit');
              }
            } catch (e) {
              if (kDebugMode) print('Team member not found in branch data: $e');
              // If team member not found, default to no edit permissions
              canEdit = false;
            }
          } else {
            if (kDebugMode) print('Branch admin login successful for: $branchEmail');
            // Branch admin can always edit
            canEdit = true;
          }
          
          if (kDebugMode) print('Branch Name: ${branchData['branch_name']}');
          if (kDebugMode) print('Access Token: ${userData['access_token']}');
          
          // Navigate to branch dashboard (works for both branch admin and team members)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BranchDashboardPage(
                branchData: userData,
                accessToken: userData['access_token'],
                canEdit: canEdit,
              ),
            ),
          );
        } else if (_selectedAdminType == 'Super Admin') {
          if (kDebugMode) print('Super Admin login successful for: ${userData['user']['email']}');
          if (kDebugMode) print('Access Token: ${userData['access_token']}');
          
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
          if (kDebugMode) print('Regular admin login successful for: ${userData['user']['email']}');
          if (kDebugMode) print('Access Token: ${userData['access_token']}');
        }
        
        // Clear form
        _usernameController.clear();
        _passwordController.clear();
      } else {
        // Login failed
        _showSnackBar(result['message'] ?? 'Login failed');
        if (kDebugMode) print('Login error: ${result['error']}');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
      if (kDebugMode) print('Exception during login: $e');
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