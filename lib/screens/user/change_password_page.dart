import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/auth_models.dart';
import '../../utils/app_colors.dart';

class ChangePasswordPage extends StatefulWidget {
  final String accessToken;

  const ChangePasswordPage({
    super.key,
    required this.accessToken,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create change password request
      final request = ChangePasswordRequest(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      final result = await ApiService.changePassword(request, widget.accessToken);

      if (result['success']) {
        // Clear form
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Password changed successfully', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate back after successful password change
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to change password', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing password: $e', style: const TextStyle(color: Colors.black)),
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
      body: Container(
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
                        'Change Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Security Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'For security reasons, you will need to enter your current password to change it.',
                            style: TextStyle(
                              color: Colors.blue.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current Password
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            label: 'Current Password',
                            hint: 'Enter your current password',
                            icon: Icons.lock,
                            obscureText: _obscureCurrentPassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Current password is required';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // New Password
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: 'New Password',
                            hint: 'Enter your new password',
                            icon: Icons.lock_outline,
                            obscureText: _obscureNewPassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'New password is required';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters long';
                              }
                              if (value == _currentPasswordController.text) {
                                return 'New password must be different from current password';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Confirm New Password
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirm New Password',
                            hint: 'Confirm your new password',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Password Requirements
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Password Requirements:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildRequirement('At least 8 characters long'),
                                _buildRequirement('Different from your current password'),
                                _buildRequirement('Use a combination of letters, numbers, and symbols'),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Change Password Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
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
                                      'Change Password',
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
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
        ),
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

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
