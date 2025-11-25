import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../utils/validation_utils.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();

  // Form validation
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  DateTime? _parsedDateOfBirth;
  bool _obscurePassword = true;
  
  // Branch selection
  List<BranchResponse> _branches = [];
  BranchResponse? _selectedBranch;
  bool _isLoadingBranches = false;
  
  // Policy acceptance
  bool _acceptPolicies = false;
  
  // Background image
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    // Country code is now optional, so we don't pre-fill it
    _loadBranches();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      // First try to get from API
      final resp = await ApiService.getAppSettings('');
      if (resp['success'] == true) {
        final data = resp['data'];
        String? backgroundPath;
        
        // Extract background image path from various possible keys
        if (data is Map) {
          backgroundPath = data['background_image'] ?? 
                          data['BackgroundImage'] ?? 
                          data['backgroundImage'];
        }
        
        if (backgroundPath != null && backgroundPath.isNotEmpty) {
          // Normalize the URL (convert /app/ to /uploads/app/)
          String normalizedUrl = backgroundPath;
          if (backgroundPath.startsWith('app/')) {
            normalizedUrl = 'uploads/$backgroundPath';
          } else if (!backgroundPath.startsWith('http')) {
            normalizedUrl = backgroundPath.startsWith('/') ? backgroundPath : '/$backgroundPath';
          }
          
          final fullUrl = normalizedUrl.startsWith('http') 
              ? normalizedUrl 
              : 'https://e8gym.online/$normalizedUrl';
          
          if (mounted) {
            setState(() {
              _backgroundImageUrl = fullUrl;
            });
          }
          
          // Cache the URL for future use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_background_url', fullUrl);
          return;
        }
      }
      
      // Fallback to cached value if API didn't return a background
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('app_background_url');
      if (mounted && cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
        });
      }
    } catch (e) {
      // Fallback to cached value on error
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedUrl = prefs.getString('app_background_url');
        if (mounted && cachedUrl != null && cachedUrl.isNotEmpty) {
          setState(() {
            _backgroundImageUrl = cachedUrl;
          });
        }
      } catch (_) {
        // Ignore errors, fallback to default background
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoadingBranches = true;
    });

    try {
      print('=== Loading Branches for Signup ===');
      final response = await ApiService.getBranchesForSignup();
      print('Branch API response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final branchesData = response['data']['branches'] as List<dynamic>;
        print('Found ${branchesData.length} branches');
        setState(() {
          _branches = branchesData.map((branch) => BranchResponse.fromJson(branch)).toList();
        });
        print('Branches loaded successfully: ${_branches.map((b) => b.branchName).toList()}');
      } else {
        print('Failed to load branches: ${response['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load branches: ${response['message']}'),
              backgroundColor: Colors.orange,
            
            )
          );
        }
      }
    } catch (e) {
      print('Error loading branches: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading branches: $e'),
            backgroundColor: Colors.red,
            ),
          
        );
      }
    } finally {
      setState(() {
        _isLoadingBranches = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF8BB0C),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Create a UTC date at midnight to avoid timezone issues
        _parsedDateOfBirth = DateTime.utc(picked.year, picked.month, picked.day);
        _dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  /// Handle signup process
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptPolicies) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Privacy Policy and Terms & Conditions to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Print the date being sent if available
      if (_parsedDateOfBirth != null) {
        print('Date being sent: ${_parsedDateOfBirth!.toUtc().toIso8601String()}');
      } else {
        print('No date of birth provided');
      }
      
      final signupRequest = SignupRequest(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        countryCode: _countryCodeController.text.trim().isNotEmpty ? _countryCodeController.text.trim() : null,
        dateOfBirth: _parsedDateOfBirth,
        branchId: _selectedBranch?.id,
      );

      final authService = AuthService();
      final response = await authService.signup(signupRequest);

      // Save tokens and user data
      final storageService = StorageService();
      await storageService.init();
      await storageService.saveAuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await storageService.saveUserData(response.user);
      
      setState(() {
        _isLoading = false;
      });

      // Show success message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Account created successfully!'),
      //     backgroundColor: Colors.green,
      //   ),
      // );

      // Navigate back to login page (main.dart)
      try {
        Navigator.pop(context);
        // Show additional success message on login page
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Account created successfully! You can now log in.'),
        //     backgroundColor: Colors.green,
        //     duration: Duration(seconds: 4),
        //   ),
        // );
      } catch (e) {
        print('Navigation error: $e'); // Debug log
        // Fallback: show error and stay on signup page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Signup failed. Please try again.';
      if (e is AuthException) {
        errorMessage = e.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Determine device size category
    final isSmallDevice = screenWidth < 400 || screenHeight < 700;
    final isLargeDevice = screenWidth > 600 || screenHeight > 1000;
    
    // Responsive sizing calculations with device-specific scaling
    final horizontalPadding = isSmallDevice 
        ? screenWidth * 0.06  // 6% for small devices
        : isLargeDevice 
            ? screenWidth * 0.03  // 3% for large devices
            : screenWidth * 0.04; // 4% for medium devices
    
    final topPadding = isSmallDevice 
        ? screenHeight * 0.02  // 2% for small devices
        : isLargeDevice 
            ? screenHeight * 0.03  // 3% for large devices
            : screenHeight * 0.025; // 2.5% for medium devices
    
    final spacingSmall = isSmallDevice 
        ? screenHeight * 0.012  // 1.2% for small devices
        : isLargeDevice 
            ? screenHeight * 0.018  // 1.8% for large devices
            : screenHeight * 0.015; // 1.5% for medium devices
    
    final spacingMedium = isSmallDevice 
        ? screenHeight * 0.018  // 1.8% for small devices
        : isLargeDevice 
            ? screenHeight * 0.025  // 2.5% for large devices
            : screenHeight * 0.02; // 2% for medium devices
    
    final spacingLarge = isSmallDevice 
        ? screenHeight * 0.025  // 2.5% for small devices
        : isLargeDevice 
            ? screenHeight * 0.035  // 3.5% for large devices
            : screenHeight * 0.03; // 3% for medium devices
    
    final spacingExtraLarge = isSmallDevice 
        ? screenHeight * 0.035  // 3.5% for small devices
        : isLargeDevice 
            ? screenHeight * 0.045  // 4.5% for large devices
            : screenHeight * 0.04; // 4% for medium devices
    
    // Responsive font sizes with device-specific scaling
    final fontSizeSmall = isSmallDevice 
        ? screenWidth * 0.040  // 3.5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.030  // 2.5% for large devices
            : screenWidth * 0.04; // 3% for medium devices
    
    final fontSizeMedium = isSmallDevice 
        ? screenWidth * 0.050  // 4.5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.040  // 3.5% for large devices
            : screenWidth * 0.05; // 4% for medium devices
    
    final fontSizeLarge = isSmallDevice 
        ? screenWidth * 0.060  // 5.5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.050  // 4.5% for large devices
            : screenWidth * 0.06; // 5% for medium devices
    
    
    // Responsive icon sizes with device-specific scaling
    final iconSizeSmall = isSmallDevice 
        ? screenWidth * 0.05  // 4% for small devices
        : isLargeDevice 
            ? screenWidth * 0.04  // 3% for large devices
            : screenWidth * 0.040; // 3.5% for medium devices
    
    final iconSizeMedium = isSmallDevice 
        ? screenWidth * 0.050  // 4.5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.040  // 3.5% for large devices
            : screenWidth * 0.05; // 4% for medium devices
    
    // Responsive container sizes with device-specific scaling
    final buttonHeight = isSmallDevice 
        ? screenHeight * 0.07  // 8% for small devices
        : isLargeDevice 
            ? screenHeight * 0.12  // 12% for large devices
            : screenHeight * 0.1; // 10% for medium devices
    
    final buttonWidth = isSmallDevice 
        ? screenWidth * 0.7  // 70% for small devices
        : isLargeDevice 
            ? screenWidth * 0.7  // 50% for large devices
            : screenWidth * 0.7; // 60% for medium devices
    
    final countryCodeWidth = isSmallDevice 
        ? screenWidth * 0.2  // 20% for small devices
        : isLargeDevice 
            ? screenWidth * 0.15  // 15% for large devices
            : screenWidth * 0.18; // 18% for medium devices

    return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Stack(
        children: [
          // Static background fallback
          Container(
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
          ),
          // Dynamic background overlay
          if (_backgroundImageUrl != null)
            Positioned.fill(
              child: Image.network(
                _backgroundImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // If network image fails, show nothing (fallback to static background)
                  return const SizedBox.shrink();
                },
              ),
            ),
          // Dark overlay
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x50000000),
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: topPadding),
                      
                      // Welcome text
                      Text(
                        'WELCOME TO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      
                      SizedBox(height: spacingSmall),
                      
                      Text(
                        'ENDURANCE EIGHT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      SizedBox(height: spacingSmall),
                      
                      // Brand description
                      Text(
                        'Endurance Eight is a sports brand, dedicated to elevating the standards in the sports industry, through our E8 Gym and E8 online products and services',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizeSmall,
                          height: 1.3,
                        ),
                      ),
                      
                      SizedBox(height: spacingMedium),
                      
                      // Explore section
                      Text(
                        'Explore our:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      SizedBox(height: spacingSmall),
                      
                      // Gym option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8BB0C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.all(screenWidth * (isSmallDevice ? 0.012 : isLargeDevice ? 0.008 : 0.01)),
                            child: Icon(
                              Icons.fitness_center,
                              color: Colors.black,
                              size: iconSizeSmall,
                            ),
                          ),
                          SizedBox(width: screenWidth * (isSmallDevice ? 0.025 : isLargeDevice ? 0.015 : 0.02)),
                          Text(
                            'Gym - "Place for Athletes"',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSizeSmall * (isSmallDevice ? 0.85 : isLargeDevice ? 0.75 : 0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: spacingSmall),
                      
                      // Products & Services option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8BB0C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.all(screenWidth * (isSmallDevice ? 0.012 : isLargeDevice ? 0.008 : 0.01)),
                            child: Icon(
                              Icons.local_drink,
                              color: Colors.black,
                              size: iconSizeSmall,
                            ),
                          ),
                          SizedBox(width: screenWidth * (isSmallDevice ? 0.025 : isLargeDevice ? 0.015 : 0.02)),
                          Text(
                            'Products & Services - "Place for Athletes"',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSizeSmall * (isSmallDevice ? 0.85 : isLargeDevice ? 0.75 : 0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: spacingLarge),
                      
                      // Create new account section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Create new account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSizeMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: spacingMedium),
                      
                      // Full Name field
                      _buildInputField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        screenWidth: screenWidth,
                        fontSizeSmall: fontSizeSmall,
                        iconSizeMedium: iconSizeMedium,
                        isSmallDevice: isSmallDevice,
                        isLargeDevice: isLargeDevice,
                      ),
                      
                      SizedBox(height: spacingMedium),
                      
                      // Email field
                      _buildInputField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        screenWidth: screenWidth,
                        fontSizeSmall: fontSizeSmall,
                        iconSizeMedium: iconSizeMedium,
                        isSmallDevice: isSmallDevice,
                        isLargeDevice: isLargeDevice,
                      ),
                      
                      SizedBox(height: spacingMedium),
                      
                      // Password field
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                        screenWidth: screenWidth,
                        fontSizeSmall: fontSizeSmall,
                        iconSizeMedium: iconSizeMedium,
                        isSmallDevice: isSmallDevice,
                        isLargeDevice: isLargeDevice,
                      ),
                      
                      SizedBox(height: spacingLarge), // Increased spacing for error message
                      
                      // Phone Number field
                      _buildPhoneField(
                        screenWidth: screenWidth,
                        fontSizeSmall: fontSizeSmall,
                        iconSizeMedium: iconSizeMedium,
                        countryCodeWidth: countryCodeWidth,
                        isSmallDevice: isSmallDevice,
                        isLargeDevice: isLargeDevice,
                      ),
                      
                      SizedBox(height: spacingMedium),
                      
                      // Date of Birth field
                      _buildDateField(
                        screenWidth: screenWidth,
                        fontSizeSmall: fontSizeSmall,
                        iconSizeMedium: iconSizeMedium,
                        isSmallDevice: isSmallDevice,
                        isLargeDevice: isLargeDevice,
                      ),
                      
                      SizedBox(height: spacingMedium),
                      
                      // Branch Selection field
                      _buildBranchField(
                        screenWidth: screenWidth,
                        fontSizeSmall: fontSizeSmall,
                        iconSizeMedium: iconSizeMedium,
                        isSmallDevice: isSmallDevice,
                        isLargeDevice: isLargeDevice,
                      ),
                      
                      SizedBox(height: spacingLarge),
                      
                      // Privacy Policy and Terms & Conditions checkboxes
                      _buildPolicyCheckboxes(
                        screenWidth: screenWidth,
                        fontSizeSmall: fontSizeSmall,
                        isSmallDevice: isSmallDevice,
                        isLargeDevice: isLargeDevice,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Sign Up button
                      SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleSignup,
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                                    strokeWidth: screenWidth * (isSmallDevice ? 0.01 : isLargeDevice ? 0.006 : 0.008),
                                  ),
                                )
                              : SvgPicture.asset(
                                  'assets/img/SignUpButton.svg',
                                  width: buttonWidth * (isSmallDevice ? 0.9 : isLargeDevice ? 0.8 : 0.83),
                                  height: buttonHeight * (isSmallDevice ? 0.4 : isLargeDevice ? 0.35 : 0.375),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      
                      SizedBox(height: spacingSmall),
                      
                      // Back to login link - Improved accessibility for iPad
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.01, // 1% vertical padding for larger touch target
                          horizontal: screenWidth * 0.02, // 2% horizontal padding
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSizeSmall * (isSmallDevice ? 0.9 : isLargeDevice ? 0.8 : 0.85),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.005, // 0.5% vertical padding
                                  horizontal: screenWidth * 0.015, // 1.5% horizontal padding
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: const Color(0xFFF8BB0C),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Log in',
                                  style: TextStyle(
                                    color: const Color(0xFFF8BB0C),
                                    fontSize: fontSizeSmall * (isSmallDevice ? 0.9 : isLargeDevice ? 0.8 : 0.85),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFFF8BB0C),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: spacingExtraLarge),
                    ],
                  ), // Column
                ), // Form
              ), // SingleChildScrollView
            ), // Padding
          ), // SafeArea
        ], // Stack children
      ), // Stack
    ), // Container
  ); // Scaffold
}

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    required double screenWidth,
    required double fontSizeSmall,
    required double iconSizeMedium,
    required bool isSmallDevice,
    required bool isLargeDevice,
  }) {
    final padding = isSmallDevice 
        ? screenWidth * 0.018  // 1.8% for small devices
        : isLargeDevice 
            ? screenWidth * 0.012  // 1.2% for large devices
            : screenWidth * 0.015; // 1.5% for medium devices
    
    final spacing = isSmallDevice 
        ? screenWidth * 0.035  // 3.5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.025  // 2.5% for large devices
            : screenWidth * 0.03; // 3% for medium devices

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF8BB0C),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8BB0C),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.all(padding),
            child: Icon(
              icon,
              color: Colors.black,
              size: iconSizeMedium,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: isPassword ? _obscurePassword : false,
              style: TextStyle(color: Colors.white, fontSize: fontSizeSmall),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(color: Colors.white70, fontSize: fontSizeSmall),
                border: InputBorder.none,
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontSize: fontSizeSmall * 0.75,
                  height: 1.4,
                ),
                errorMaxLines: 4,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                
                switch (label.toLowerCase()) {
                  case 'full name':
                    if (!ValidationUtils.isValidFullName(value.trim())) {
                      return 'Full name must be between 2 and 100 characters';
                    }
                    break;
                  case 'email':
                    if (!ValidationUtils.isValidEmail(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    break;
                  case 'password':
                    if (!ValidationUtils.isValidPassword(value)) {
                      return 'Password must be 8+ characters with:\n• Uppercase letter (A-Z)\n• Lowercase letter (a-z)\n• Number (0-9)';
                    }
                    break;
                }
                return null;
              },
            ),
          ),
          if (isPassword) ...[
            SizedBox(width: spacing),
            GestureDetector(
              onTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8BB0C),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.all(padding),
                child: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black,
                  size: iconSizeMedium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneField({
    required double screenWidth,
    required double fontSizeSmall,
    required double iconSizeMedium,
    required double countryCodeWidth,
    required bool isSmallDevice,
    required bool isLargeDevice,
  }) {
    final padding = isSmallDevice 
        ? screenWidth * 0.018  // 1.8% for small devices
        : isLargeDevice 
            ? screenWidth * 0.012  // 1.2% for large devices
            : screenWidth * 0.015; // 1.5% for medium devices
    
    final spacing = isSmallDevice 
        ? screenWidth * 0.035  // 3.5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.025  // 2.5% for large devices
            : screenWidth * 0.03; // 3% for medium devices

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF8BB0C),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8BB0C),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.all(padding),
            child: Icon(
              Icons.flag,
              color: Colors.black,
              size: iconSizeMedium,
            ),
          ),
          SizedBox(width: spacing),
          // Country code field
          SizedBox(
            width: countryCodeWidth,
            child: TextFormField(
              controller: _countryCodeController,
              style: TextStyle(color: Colors.white, fontSize: fontSizeSmall),
              decoration: InputDecoration(
                hintText: '+961',
                hintStyle: TextStyle(color: Colors.white70, fontSize: fontSizeSmall),
                border: InputBorder.none,
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontSize: fontSizeSmall * 0.8,
                  height: 1.2,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null; // Optional field
                }
                if (!ValidationUtils.isValidCountryCode(value.trim())) {
                  return 'Please enter a valid country code (e.g., +961)';
                }
                return null;
              },
            ),
          ),
          SizedBox(width: spacing),
          // Phone number field
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              style: TextStyle(color: Colors.white, fontSize: fontSizeSmall),
              decoration: InputDecoration(
                hintText: 'Phone number (Optional)',
                hintStyle: TextStyle(color: Colors.white70, fontSize: fontSizeSmall),
                border: InputBorder.none,
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontSize: fontSizeSmall * 0.8,
                  height: 1.2,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null; // Optional field
                }
                if (!ValidationUtils.isValidPhoneNumber(value.trim())) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required double screenWidth,
    required double fontSizeSmall,
    required double iconSizeMedium,
    required bool isSmallDevice,
    required bool isLargeDevice,
  }) {
    final padding = isSmallDevice 
        ? screenWidth * 0.018  // 1.8% for small devices
        : isLargeDevice 
            ? screenWidth * 0.012  // 1.2% for large devices
            : screenWidth * 0.015; // 1.5% for medium devices
    
    final spacing = isSmallDevice 
        ? screenWidth * 0.035  // 3.5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.025  // 2.5% for large devices
            : screenWidth * 0.03; // 3% for medium devices

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF8BB0C),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8BB0C),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.all(padding),
            child: Icon(
              Icons.calendar_today,
              color: Colors.black,
              size: iconSizeMedium,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: TextFormField(
                controller: _dateOfBirthController,
                enabled: false,
                style: TextStyle(color: Colors.white, fontSize: fontSizeSmall),
                decoration: InputDecoration(
                  hintText: 'Date of Birth (Optional)',
                  hintStyle: TextStyle(color: Colors.white70, fontSize: fontSizeSmall),
                  border: InputBorder.none,
                  errorStyle: TextStyle(
                    color: Colors.red,
                    fontSize: fontSizeSmall * 0.8,
                    height: 1.2,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Optional field
                  }
                  if (_parsedDateOfBirth == null) {
                    return 'Please select a valid date of birth';
                  }
                  if (!ValidationUtils.isValidDateOfBirth(_parsedDateOfBirth!)) {
                    return 'You must be at least 13 years old to register';
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchField({
    required double screenWidth,
    required double fontSizeSmall,
    required double iconSizeMedium,
    required bool isSmallDevice,
    required bool isLargeDevice,
  }) {
    final padding = isSmallDevice 
        ? screenWidth * 0.018  // 1.8% for small devices
        : isLargeDevice 
            ? screenWidth * 0.012  // 1.2% for large devices
            : screenWidth * 0.015; // 1.5% for medium devices
    
    final spacing = isSmallDevice 
        ? screenWidth * 0.035  // 3.5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.025  // 2.5% for large devices
            : screenWidth * 0.03; // 3% for medium devices

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF8BB0C),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8BB0C),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.all(padding),
            child: Icon(
              Icons.location_on,
              color: Colors.black,
              size: iconSizeMedium,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: GestureDetector(
              onTap: _isLoadingBranches ? null : _showBranchDialog,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedBranch?.branchName ?? 'Select Branch',
                        style: TextStyle(
                          color: _selectedBranch != null ? Colors.white : Colors.white70,
                          fontSize: fontSizeSmall,
                        ),
                      ),
                    ),
                    if (_isLoadingBranches)
                      SizedBox(
                        width: iconSizeMedium,
                        height: iconSizeMedium,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                        ),
                      )
                    else if (_branches.isEmpty)
                      GestureDetector(
                        onTap: _loadBranches,
                        child: Icon(
                          Icons.refresh,
                          color: Colors.white70,
                          size: iconSizeMedium,
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                        size: iconSizeMedium,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBranchDialog() async {
    if (_branches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No branches available. You can still sign up without selecting a branch.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await showDialog<BranchResponse>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Select Branch',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.05,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _branches.length + 1, // +1 for "No Branch" option
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(
                    'No Branch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, null),
                  selected: _selectedBranch == null,
                );
              }
              
              final branch = _branches[index - 1];
              return ListTile(
                title: Text(
                  branch.branchName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                subtitle: Text(
                  branch.location,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                ),
                onTap: () => Navigator.pop(context, branch),
                selected: _selectedBranch?.id == branch.id,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFFF8BB0C),
                fontSize: MediaQuery.of(context).size.width * 0.04,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null || result == null) {
      setState(() {
        _selectedBranch = result;
      });
    }
  }

  Widget _buildPolicyCheckboxes({
    required double screenWidth,
    required double fontSizeSmall,
    required bool isSmallDevice,
    required bool isLargeDevice,
  }) {
    final checkboxSize = isSmallDevice 
        ? screenWidth * 0.05  // 5% for small devices
        : isLargeDevice 
            ? screenWidth * 0.04  // 4% for large devices
            : screenWidth * 0.045; // 4.5% for medium devices
    
    final spacing = isSmallDevice 
        ? screenWidth * 0.02  // 2% for small devices
        : isLargeDevice 
            ? screenWidth * 0.015  // 1.5% for large devices
            : screenWidth * 0.018; // 1.8% for medium devices

    return Row(
      children: [
        SizedBox(
          width: checkboxSize,
          height: checkboxSize,
          child: Checkbox(
            value: _acceptPolicies,
            onChanged: (value) {
              setState(() {
                _acceptPolicies = value ?? false;
              });
            },
            activeColor: const Color(0xFFF8BB0C),
            checkColor: Colors.black,
            side: const BorderSide(color: Color(0xFFF8BB0C), width: 2),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptPolicies = !_acceptPolicies;
              });
            },
            child: RichText(
              text: TextSpan(
                text: 'I accept ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSizeSmall * (isSmallDevice ? 0.8 : isLargeDevice ? 0.7 : 0.75),
                ),
                children: [
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: const Color(0xFFF8BB0C),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSizeSmall * (isSmallDevice ? 0.8 : isLargeDevice ? 0.7 : 0.75),
                    ),
                  ),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      color: const Color(0xFFF8BB0C),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _launchURL('https://e8gym.online/privacy'),
              child: Icon(
                Icons.open_in_new,
                color: const Color(0xFFF8BB0C),
                size: fontSizeSmall * (isSmallDevice ? 0.8 : isLargeDevice ? 0.7 : 0.75),
              ),
            ),
            SizedBox(width: spacing * 0.5),
            GestureDetector(
              onTap: () => _launchURL('https://e8gym.online/terms_conditions'),
              child: Icon(
                Icons.open_in_new,
                color: const Color(0xFFF8BB0C),
                size: fontSizeSmall * (isSmallDevice ? 0.8 : isLargeDevice ? 0.7 : 0.75),
              ),
            ),
          ],
        ),
      ],
    );
  }
}