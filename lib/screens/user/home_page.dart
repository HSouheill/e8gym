import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../utils/secure_logger.dart';
import '../../utils/secure_error_handler.dart';
import 'user_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  String? _userName;
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  Future<void> _loadUserData() async {
    try {
      await _storageService.init();
      final user = await _storageService.getUserData();
      SecureLogger.debug('User data loaded', data: {'user_name': user?.fullName});
      if (user != null) {
        setState(() {
          _userName = user.fullName;
        });
      }
    } catch (e) {
      SecureLogger.error('Error loading user data', error: e);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
      await _storageService.clearAuthData();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = SecureErrorHandler.sanitizeErrorMessage('Logout failed', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
          ),
        );
      }
    }
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
        child: Stack(
          children: [
            // Static background fallback
            Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Header with logout button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // User greeting
                  if (_userName != null)
                    Text(
                      'Hello, $_userName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // Main content
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 80,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Welcome to Endurance Eight',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your account has been created successfully!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to classes page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UserDashboard(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'View Classes',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to products & services
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'Products',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
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
    ),
  );
}
}