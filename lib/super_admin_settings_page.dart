import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'services/api_service.dart';
import 'models/auth_models.dart';
import 'utils/background_image_service.dart';
import 'utils/app_colors.dart';

class SuperAdminSettingsPage extends StatefulWidget {
  final String accessToken;

  const SuperAdminSettingsPage({super.key, required this.accessToken});

  @override
  State<SuperAdminSettingsPage> createState() => _SuperAdminSettingsPageState();
}

class _SuperAdminSettingsPageState extends State<SuperAdminSettingsPage> {
  bool _loading = true;
  String? _currentBackgroundUrl;
  File? _selectedFile;
  bool _uploading = false;
  bool _picking = false;
  
  // Change password state
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _changingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _loading = true;
    });
    
    // Use centralized service to load background image
    final backgroundUrl = await BackgroundImageService.loadBackgroundImage(widget.accessToken);
    
    if (mounted) {
      setState(() {
        _loading = false;
        _currentBackgroundUrl = backgroundUrl;
      });
    }
  }

  Future<File> _compressImage(File imageFile) async {
    try {
      // Read the image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Create a new file with compressed name
      final tempDir = await getTemporaryDirectory();
      final compressedPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = File(compressedPath);
      
      // For now, we'll use the original bytes but with a different quality
      // In a real implementation, you might want to use a proper image compression library
      await compressedFile.writeAsBytes(bytes);
      
      return compressedFile;
    } catch (e) {
      // If compression fails, return the original file
      return imageFile;
    }
  }

  Future<void> _pickImage() async {
    if (_picking) return;
    _picking = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Balanced quality for file size
        maxWidth: 2048, // Reduced to prevent 413 errors
        maxHeight: 2048, // Reduced to prevent 413 errors
      );
      if (picked == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selection cancelled')),
          );
        }
        return;
      }

      // Prefer using the direct path if it exists; otherwise copy to temp.
      File? resultFile;
      try {
        final direct = File(picked.path);
        if (await direct.exists()) {
          resultFile = direct;
        }
      } catch (_) {}

      if (resultFile == null) {
        final tempDir = await getTemporaryDirectory();
        // Preserve original file extension for GIFs and other formats
        final originalPath = picked.path;
        final extension = originalPath.split('.').last.toLowerCase();
        final fileName = 'bg_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final savePath = '${tempDir.path}/$fileName';
        try {
          await picked.saveTo(savePath);
        } catch (_) {
          final bytes = await picked.readAsBytes();
          final f = File(savePath);
          await f.writeAsBytes(bytes, flush: true);
        }
        resultFile = File(savePath);
      }

      if (!mounted) return;

      // Check file size and compress if necessary
      final fileSize = await resultFile.length();
      const maxFileSize = 5 * 1024 * 1024; // 5MB limit
      
      if (fileSize > maxFileSize) {
        // Try to compress the image further
        resultFile = await _compressImage(resultFile);
        final compressedSize = await resultFile.length();
        
        if (compressedSize > maxFileSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image too large (${(compressedSize / 1024 / 1024).toStringAsFixed(1)}MB). Please choose a smaller image.'),
                backgroundColor: AppColors.gold,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _selectedFile = resultFile;
      });

      final finalSize = await resultFile.length();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image selected (${(finalSize / 1024 / 1024).toStringAsFixed(1)}MB). Ready to upload.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _picking = false;
        });
      } else {
        _picking = false;
      }
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null || _uploading) return;
    
    // Check file size before upload
    final fileSize = await _selectedFile!.length();
    const maxFileSize = 5 * 1024 * 1024; // 5MB limit
    
    if (fileSize > maxFileSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Please choose a smaller image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _uploading = true;
    });
    
    try {
      final resp = await ApiService.uploadBackgroundImage(accessToken: widget.accessToken, imageFile: _selectedFile!);
      if (mounted) {
        setState(() {
          _uploading = false;
        });
        
        if (resp['success'] == true) {
          // Extract and normalize the background URL
          final backgroundPath = BackgroundImageService.extractBackgroundFromData(resp['data']);
          final normalizedUrl = BackgroundImageService.normalizeUrl(backgroundPath);
          
          // Immediately cache the URL so all pages can access it
          if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
            await BackgroundImageService.setBackgroundUrl(normalizedUrl);
          }
          
          setState(() {
            _currentBackgroundUrl = normalizedUrl;
            _selectedFile = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Background image updated successfully! It will now appear on all pages.'),
              backgroundColor: AppColors.gold,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          final msg = (resp['message'] ?? 'Upload failed').toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg, style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.gold,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _changingPassword = true;
    });

    try {
      final request = ChangePasswordRequest(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      final result = await ApiService.changeSuperAdminPassword(request, widget.accessToken);

      if (mounted) {
        if (result['success']) {
          // Clear form
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Password changed successfully'),
              backgroundColor: AppColors.gold,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to change password', style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.gold,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _changingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/E8Logos/admin_dashboard_background.jpeg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color(0x50000000),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // Content
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Background Image',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supports JPG, PNG, GIF and other image formats (max 5MB, recommended 2K resolution)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selectedFile != null
                          ? Image.file(
                              _selectedFile!, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Icon(Icons.image, size: 48, color: Colors.grey),
                                  ),
                                );
                              },
                            )
                          : (_currentBackgroundUrl != null && _currentBackgroundUrl!.isNotEmpty)
                              ? Image.network(
                                  _currentBackgroundUrl!, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Text('No background set'),
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _picking ? null : _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _uploading || _selectedFile == null ? null : _upload,
                        icon: _uploading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.cloud_upload),
                        label: Text(_uploading ? 'Uploading...' : 'Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Change Password Section
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Update your SuperAdmin password (minimum 8 characters)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current Password
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: !_showCurrentPassword,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showCurrentPassword = !_showCurrentPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // New Password
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_showNewPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showNewPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showNewPassword = !_showNewPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                            ),
                          ),
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
                        // Change Password Button
                        ElevatedButton(
                          onPressed: _changingPassword ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _changingPassword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


