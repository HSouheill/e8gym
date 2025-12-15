import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/auth_models.dart';
import '../utils/app_colors.dart';

class UserProfilePage extends StatefulWidget {
  final String accessToken;
  final UserResponse? currentUser;

  const UserProfilePage({
    super.key,
    required this.accessToken,
    this.currentUser,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _isLoadingProfile = false;
  DateTime? _selectedDateOfBirth;
  UserResponse? _currentUser;
  
  // Background image
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _loadBackgroundImage();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    // If we already have user data from widget, initialize fields first
    if (_currentUser != null) {
      _initializeFields();
    }
    
    // Always fetch fresh data from API
    setState(() {
      _isLoadingProfile = true;
    });
    
    try {
      final result = await ApiService.getUserProfile(widget.accessToken);
      
      if (result['success'] && result['data'] != null) {
        final userData = UserResponse.fromJson(result['data']);
        setState(() {
          _currentUser = userData;
        });
        _initializeFields();
      } else {
        // If API call fails but we have widget.currentUser, use that
        if (_currentUser == null && widget.currentUser != null) {
          setState(() {
            _currentUser = widget.currentUser;
          });
          _initializeFields();
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      // If API call fails but we have widget.currentUser, use that
      if (_currentUser == null && widget.currentUser != null) {
        setState(() {
          _currentUser = widget.currentUser;
        });
        _initializeFields();
      }
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _countryCodeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    if (_currentUser != null) {
      _fullNameController.text = _currentUser!.fullName;
      _phoneNumberController.text = _currentUser!.phoneNumber ?? '';
      _countryCodeController.text = _currentUser!.countryCode ?? '';
      _selectedDateOfBirth = _currentUser!.dateOfBirth;
      
      // Set height and weight if available
      if (_currentUser!.height != null) {
        _heightController.text = _currentUser!.height!.toString();
      }
      if (_currentUser!.weight != null) {
        _weightController.text = _currentUser!.weight!.toString();
      }
    }
  }

  Future<void> _loadBackgroundImage() async {
    try {
      // First try to get from API
      final result = await ApiService.getAppSettings(widget.accessToken);
      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        String? backgroundImage;
        
        // Try different possible keys for background image
        if (data['background_image'] != null) {
          backgroundImage = data['background_image'];
        } else if (data['backgroundImage'] != null) {
          backgroundImage = data['backgroundImage'];
        } else if (data['background'] != null) {
          backgroundImage = data['background'];
        }
        
        if (backgroundImage != null && backgroundImage.isNotEmpty) {
          // Normalize the URL
          String normalizedUrl = _normalizeUrl(backgroundImage);
          setState(() {
            _backgroundImageUrl = normalizedUrl;
          });
          
          // Cache the URL
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('background_image_url', normalizedUrl);
          return;
        }
      }
      
      // Fallback to cached URL
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('background_image_url');
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
        });
      }
    } catch (e) {
      print('Error loading background image: $e');
      // Fallback to cached URL
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('background_image_url');
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
        });
      }
    }
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // Handle relative paths
    if (url.startsWith('/app/')) {
      return 'https://e8gym.online/uploads$url';
    } else if (url.startsWith('app/')) {
      return 'https://e8gym.online/uploads/$url';
    } else if (url.startsWith('/uploads/')) {
      return 'https://e8gym.online$url';
    } else if (url.startsWith('uploads/')) {
      return 'https://e8gym.online/$url';
    }
    
    return 'https://e8gym.online/uploads/$url';
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create update request
      final request = UpdateUserDataRequest(
        fullName: _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : null,
        phoneNumber: _phoneNumberController.text.trim().isNotEmpty ? _phoneNumberController.text.trim() : null,
        countryCode: _countryCodeController.text.trim().isNotEmpty ? _countryCodeController.text.trim() : null,
        dateOfBirth: _selectedDateOfBirth,
        height: _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null,
        weight: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
      );

      final result = await ApiService.updateUserData(request, widget.accessToken);

      if (result['success']) {
        // Update current user data
        final updatedUser = UserResponse.fromJson(result['data']);
        setState(() {
          _currentUser = updatedUser;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profile updated successfully'),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update profile', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Base gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white70],
              ),
            ),
          ),
          
          // Static background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Dynamic background image overlay
          if (_backgroundImageUrl != null)
            Positioned.fill(
              child: Image.network(
                _backgroundImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          
          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0x50000000),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Profile Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Loading indicator for profile fetch
                  if (_isLoadingProfile)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  
                  // Form
                  Expanded(
                    child: _isLoadingProfile
                        ? const SizedBox.shrink()
                        : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name
                          _buildTextField(
                            controller: _fullNameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Full name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Phone Number
                          _buildTextField(
                            controller: _phoneNumberController,
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (value.trim().length < 10) {
                                  return 'Phone number must be at least 10 digits';
                                }
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Country Code
                          _buildTextField(
                            controller: _countryCodeController,
                            label: 'Country Code',
                            hint: 'e.g., +1, +44, +91',
                            icon: Icons.flag,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (!value.trim().startsWith('+')) {
                                  return 'Country code must start with +';
                                }
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Date of Birth
                          _buildDateField(),
                          
                          const SizedBox(height: 16),
                          
                          // Height
                          _buildTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            hint: 'Enter your height in centimeters',
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final height = double.tryParse(value.trim());
                                if (height == null) {
                                  return 'Please enter a valid height';
                                }
                                if (height < 50 || height > 300) {
                                  return 'Height must be between 50 and 300 cm';
                                }
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Weight
                          _buildTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            hint: 'Enter your weight in kilograms',
                            icon: Icons.monitor_weight,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final weight = double.tryParse(value.trim());
                                if (weight == null) {
                                  return 'Please enter a valid weight';
                                }
                                if (weight < 20 || weight > 500) {
                                  return 'Weight must be between 20 and 500 kg';
                                }
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Update Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Update Profile',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateOfBirth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDateOfBirth != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedDateOfBirth!)
                        : 'Select your date of birth',
                    style: TextStyle(
                      color: _selectedDateOfBirth != null ? Colors.white : Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
