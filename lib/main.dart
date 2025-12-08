import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'splash_screen.dart';
import 'signup_page.dart';
import 'admin_login_page.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'user_dashboard.dart';
import 'models/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Enable better error handling for release builds
  FlutterError.onError = (FlutterErrorDetails details) {
    // In release mode, don't show the red screen
    if (kReleaseMode) {
      print('Flutter error: ${details.exception}');
    } else {
      FlutterError.presentError(details);
    }
  };

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stackTrace) {
    // Log error but don't crash the app
    print('App error: $error');
    print('Stack trace: $stackTrace');
    
    // In release mode, try to recover gracefully
    if (kReleaseMode) {
      // Could add crash reporting here
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endurance Eight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const UserDashboard(),
      },
      builder: (context, child) {
        return child!;
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    // Load background image asynchronously to prevent blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBackgroundImage();
    });
  }

  Future<void> _loadBackgroundImage() async {
    try {
      // First try to get from API with timeout
      final resp = await ApiService.getAppSettings('').timeout(
        const Duration(seconds: 10), // Increased timeout for release builds
        onTimeout: () => {'success': false, 'message': 'Timeout'},
      );
      
      if (resp['success'] == true && resp['data'] != null) {
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
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('app_background_url', fullUrl);
          } catch (_) {
            // Ignore caching errors
          }
          return;
        }
      }
      
      // Fallback to cached value if API didn't return a background
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedUrl = prefs.getString('app_background_url');
        if (mounted && cachedUrl != null && cachedUrl.isNotEmpty) {
          setState(() {
            _backgroundImageUrl = cachedUrl;
          });
        }
      } catch (_) {
        // Ignore caching errors
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text('Please enter both email and password', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginRequest = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final response = await _authService.login(loginRequest);

      // Save tokens and user data
      await _storageService.init();
      await _storageService.saveAuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await _storageService.saveUserData(response.user);

      setState(() {
        _isLoading = false;
      });

      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Login failed. Please try again.';
      if (e is AuthException) {
        errorMessage = e.message;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Responsive sizing calculations
    final horizontalPadding = screenWidth * 0.05; // 5% of screen width
    final spacingSmall = screenHeight * 0.01; // 1% of screen height (reduced)
    final spacingMedium = screenHeight * 0.015; // 1.5% of screen height (reduced)
    final spacingLarge = screenHeight * 0.02; // 2% of screen height (reduced)
    
    // Responsive font sizes - increased for better readability
    final fontSizeSmall = screenWidth * 0.03; // 3% of screen width
    final fontSizeMedium = screenWidth * 0.04; // 5% of screen width
    final fontSizeLarge = screenWidth * 0.065; // 6.5% of screen width
    
    // Responsive icon sizes
    final iconSizeSmall = screenWidth * 0.03; // 4% of screen width
    final iconSizeMedium = screenWidth * 0.04; // 5% of screen width
    
    // Responsive container sizes - optimized for better fit
    final profileIconSize = screenWidth * 0.08; // 8% of screen width (reduced)
    final buttonHeight = screenHeight * 0.08; // 8% of screen height (increased)
    final buttonWidth = screenWidth * 0.6; // 60% of screen width (increased)

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white70],
              ),
            ),
          ),
          // Static background fallback
          Positioned.fill(
            child: Image.asset(
              'assets/background/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // If background image fails, show gradient only
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white70],
                    ),
                  ),
                );
              },
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
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x50000000),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                  // Top right profile icon
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                        );
                      },
                      child: Container(
                        // margin: EdgeInsets.only(top: topPadding),
                        width: profileIconSize,
                        height: profileIconSize,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.white70],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.black,
                          size: iconSizeMedium,
                        ),
                      ),
                    ),
                  ),
                  
                  // E8 Logo - positioned directly below profile icon with no spacing
                  SizedBox(height: 0),
                  Center(
                    child: Image.asset(
                      'assets/E8Logos/E8_Short_Logo.png',
                      width: screenWidth * 0.3,
                      // height: screenWidth * 0.3,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Show a placeholder if image fails to load
                        return Container(
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          color: Colors.transparent,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white70,
                            size: screenWidth * 0.1,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // SizedBox(height: spacingMedium),
                  
                  // SizedBox(height: spacingMedium),
                  
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
                      fontSize: fontSizeMedium,
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
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.white70],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(screenWidth * 0.008),
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: iconSizeSmall,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Gym - "Place for Athletes"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizeSmall,
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
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.white70],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(screenWidth * 0.008),
                        child: Icon(
                          Icons.local_drink,
                          color: Colors.white,
                          size: iconSizeSmall,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Products & Services - "Made for Athletes"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizeSmall,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: spacingLarge),
                  
                  // Login section
                  Text(
                    'Log in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: spacingMedium),
                  
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(screenWidth * 0.015),
                          child: Icon(
                            Icons.email,
                            color: Colors.white,
                            size: iconSizeMedium,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            style: TextStyle(color: Colors.white, fontSize: fontSizeMedium),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(color: Colors.white70, fontSize: fontSizeMedium),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: spacingMedium),
                  
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(screenWidth * 0.015),
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: iconSizeMedium,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: Colors.white, fontSize: fontSizeMedium),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.white70, fontSize: fontSizeMedium),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white, Colors.white70],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.all(screenWidth * 0.015),
                            child: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white,
                              size: iconSizeSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Login button
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: screenWidth * 0.008,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/img/Button.svg',
                              width: buttonWidth * 0.9,
                              height: buttonHeight * 0.8,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  
                  SizedBox(height: spacingMedium),
                  
                  // Create account link - Improved accessibility for iPad
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.01, // 1% vertical padding for larger touch target
                      horizontal: screenWidth * 0.02, // 2% horizontal padding
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSizeSmall,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupPage()),
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
                              'Create new account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSizeSmall,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: spacingMedium),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}