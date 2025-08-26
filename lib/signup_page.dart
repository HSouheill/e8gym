import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../utils/validation_utils.dart';
import '../services/storage_service.dart';

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
  String? _selectedDateOfBirth;
  DateTime? _parsedDateOfBirth;

  @override
  void initState() {
    super.initState();
    _countryCodeController.text = '+961'; // Lebanese country code
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

    if (_parsedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Print the date being sent
      print('Date being sent: ${_parsedDateOfBirth!.toUtc().toIso8601String()}');
      
      final signupRequest = SignupRequest(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        countryCode: _countryCodeController.text.trim(),
        dateOfBirth: _parsedDateOfBirth!,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to login page (main.dart)
      try {
        Navigator.pop(context);
        // Show additional success message on login page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! You can now log in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                    const SizedBox(height: 40),
                    
                    // Welcome text
                    const Text(
                      'WELCOME TO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'ENDURANCE EIGHT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Brand description
                    const Text(
                      'Endurance Eight is a sports brand, dedicated to elevating the standards in the sports industry, through our E8 Gym and E8 online products and services',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Explore section
                    const Text(
                      'Explore our:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Gym option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8BB0C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Gym - "Place for Athletes"',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Products & Services option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8BB0C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.local_drink,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Products & Services - "Place for Athletes"',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Create new account section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create new account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Full Name field
                    _buildInputField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      icon: Icons.person,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Email field
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Password field
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Phone Number field
                    _buildPhoneField(),
                    
                    const SizedBox(height: 24),
                    
                    // Date of Birth field
                    _buildDateField(),
                    
                    const SizedBox(height: 50),
                    
                    // Sign Up button
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 90,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleSignup,
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/img/SignUpButton.svg',
                                width: MediaQuery.of(context).size.width * 0.6,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    
                    
                    const SizedBox(height: 40),
                    
                    // Back to login link
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                color: const Color(0xFFF8BB0C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
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
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: isPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
                errorStyle: const TextStyle(color: Colors.red),
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
                      return 'Password must be at least 8 characters with uppercase, lowercase, and number';
                    }
                    break;
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
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
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.flag,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Country code field
          Container(
            width: 80,
            child: TextFormField(
              controller: _countryCodeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '+961',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                errorStyle: TextStyle(color: Colors.red),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Country code is required';
                }
                if (!ValidationUtils.isValidCountryCode(value.trim())) {
                  return 'Please enter a valid country code (e.g., +961)';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          // Phone number field
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Phone number',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                errorStyle: TextStyle(color: Colors.red),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
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

  Widget _buildDateField() {
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
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: TextFormField(
                controller: _dateOfBirthController,
                enabled: false,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Date of Birth',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  errorStyle: TextStyle(color: Colors.red),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Date of birth is required';
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
}
