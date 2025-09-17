import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/storage_service.dart';
import 'models/auth_models.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    // Start animation
    _animationController.forward();

    // Check authentication status and navigate accordingly
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Wait for minimum splash screen duration first
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Initialize storage service with timeout
      await _storageService.init().timeout(
        const Duration(seconds: 5), // Increased timeout for release builds
        onTimeout: () {
          // If storage init times out, continue without it
          if (kDebugMode) {
            print('Storage initialization timed out');
          }
        },
      );
      
      String? accessToken;
      UserResponse? userData;
      
      try {
        accessToken = await _storageService.getAccessToken();
        userData = await _storageService.getUserData();
      } catch (e) {
        // If getting stored data fails, continue without it
        if (kDebugMode) {
          print('Error getting stored data: $e');
        }
        accessToken = null;
        userData = null;
      }
      
      if (mounted) {
        if (accessToken != null && userData != null) {
          // User is logged in, navigate to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // User is not logged in, navigate to login
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // If there's any error, navigate to login
      if (kDebugMode) {
        print('Splash screen error: $e');
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            try {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Logo with error handling
                    Image.asset(
                      'assets/logo/Main_Logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to a simple icon if image fails to load
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8BB0C),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // App Name
                    const Text(
                      'E8Gym',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF8BB0C),
                        letterSpacing: 2.0,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline
                    const Text(
                      'Place for Athletes',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
            } catch (e) {
              // Fallback UI if there's an error
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Color(0xFFF8BB0C),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'E8Gym',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF8BB0C),
                      ),
                    ),
                    SizedBox(height: 10),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
