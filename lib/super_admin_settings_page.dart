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
  
  // Background images for each dashboard type
  String? _superAdminBackgroundUrl;
  String? _branchBackgroundUrl;
  String? _userBackgroundUrl;
  
  // Selected files for each dashboard type
  File? _selectedSuperAdminFile;
  File? _selectedBranchFile;
  File? _selectedUserFile;
  
  // Upload/pick states for each dashboard type
  bool _uploadingSuperAdmin = false;
  bool _uploadingBranch = false;
  bool _uploadingUser = false;
  bool _pickingSuperAdmin = false;
  bool _pickingBranch = false;
  bool _pickingUser = false;
  
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
    
    // Load background images for each dashboard type
    final superAdminUrl = await BackgroundImageService.loadBackgroundImage(
      widget.accessToken, 
      dashboardType: 'superadmin',
    );
    final branchUrl = await BackgroundImageService.loadBackgroundImage(
      widget.accessToken, 
      dashboardType: 'branch',
    );
    final userUrl = await BackgroundImageService.loadBackgroundImage(
      widget.accessToken, 
      dashboardType: 'user',
    );
    
    if (mounted) {
      setState(() {
        _loading = false;
        _superAdminBackgroundUrl = superAdminUrl;
        _branchBackgroundUrl = branchUrl;
        _userBackgroundUrl = userUrl;
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

  Future<void> _pickImage(String dashboardType) async {
    // Set the appropriate picking state
    switch (dashboardType) {
      case 'superadmin':
        if (_pickingSuperAdmin) return;
        setState(() => _pickingSuperAdmin = true);
        break;
      case 'branch':
        if (_pickingBranch) return;
        setState(() => _pickingBranch = true);
        break;
      case 'user':
        if (_pickingUser) return;
        setState(() => _pickingUser = true);
        break;
      default:
        return;
    }
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
          _resetPickingState(dashboardType);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selection cancelled', style: TextStyle(color: Colors.black)),
              backgroundColor: AppColors.snackbarBackground,
            ),
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
                content: Text('Image too large (${(compressedSize / 1024 / 1024).toStringAsFixed(1)}MB). Please choose a smaller image.', style: const TextStyle(color: Colors.black)),
                backgroundColor: AppColors.snackbarBackground,
              ),
            );
          }
          return;
        }
      }

      // Set the selected file based on dashboard type
      setState(() {
        switch (dashboardType) {
          case 'superadmin':
            _selectedSuperAdminFile = resultFile;
            break;
          case 'branch':
            _selectedBranchFile = resultFile;
            break;
          case 'user':
            _selectedUserFile = resultFile;
            break;
        }
      });

      final finalSize = await resultFile.length();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image selected (${(finalSize / 1024 / 1024).toStringAsFixed(1)}MB). Ready to upload.', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
        ),
      );
    } finally {
      if (mounted) {
        _resetPickingState(dashboardType);
      } else {
        _resetPickingState(dashboardType);
      }
    }
  }
  
  void _resetPickingState(String dashboardType) {
    switch (dashboardType) {
      case 'superadmin':
        _pickingSuperAdmin = false;
        break;
      case 'branch':
        _pickingBranch = false;
        break;
      case 'user':
        _pickingUser = false;
        break;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _upload(String dashboardType) async {
    File? selectedFile;
    bool isUploading;
    
    // Get the appropriate file and upload state
    switch (dashboardType) {
      case 'superadmin':
        selectedFile = _selectedSuperAdminFile;
        isUploading = _uploadingSuperAdmin;
        if (selectedFile == null || isUploading) return;
        setState(() => _uploadingSuperAdmin = true);
        break;
      case 'branch':
        selectedFile = _selectedBranchFile;
        isUploading = _uploadingBranch;
        if (selectedFile == null || isUploading) return;
        setState(() => _uploadingBranch = true);
        break;
      case 'user':
        selectedFile = _selectedUserFile;
        isUploading = _uploadingUser;
        if (selectedFile == null || isUploading) return;
        setState(() => _uploadingUser = true);
        break;
      default:
        return;
    }
    
    // Check file size before upload
    final fileSize = await selectedFile.length();
    const maxFileSize = 5 * 1024 * 1024; // 5MB limit
    
    if (fileSize > maxFileSize) {
      _resetUploadingState(dashboardType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Please choose a smaller image.', style: const TextStyle(color: Colors.black)),
          backgroundColor: AppColors.snackbarBackground,
        ),
      );
      return;
    }
    
    try {
      final resp = await ApiService.uploadBackgroundImage(
        accessToken: widget.accessToken, 
        imageFile: selectedFile,
        dashboardType: dashboardType,
      );
      if (mounted) {
        _resetUploadingState(dashboardType);
        
        if (resp['success'] == true) {
          // Extract background path from API response
          // Backend returns BackgroundImage field directly in the response
          String? backgroundPath;
          final responseData = resp['data'];
          
          if (responseData is String) {
            backgroundPath = responseData;
          } else if (responseData is Map) {
            // Try various possible keys
            backgroundPath = responseData['BackgroundImage'] ?? 
                            responseData['backgroundImage'] ?? 
                            responseData['background_image'] ??
                            responseData['imagePath'] ??
                            responseData['image_path'];
          }
          
          if (backgroundPath == null || backgroundPath.isEmpty) {
            // Try extracting using the service method as fallback
            backgroundPath = BackgroundImageService.extractBackgroundFromData(
              resp['data'], 
              dashboardType: null, // Don't use dashboard type for upload response
            );
          }
          
          final normalizedUrl = BackgroundImageService.normalizeUrl(backgroundPath);
          
          // Immediately cache the URL for this dashboard type
          if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
            await BackgroundImageService.setBackgroundUrl(normalizedUrl, dashboardType: dashboardType);
            
            // Update the appropriate background URL and clear selected file
            setState(() {
              switch (dashboardType) {
                case 'superadmin':
                  _superAdminBackgroundUrl = normalizedUrl;
                  _selectedSuperAdminFile = null;
                  break;
                case 'branch':
                  _branchBackgroundUrl = normalizedUrl;
                  _selectedBranchFile = null;
                  break;
                case 'user':
                  _userBackgroundUrl = normalizedUrl;
                  _selectedUserFile = null;
                  break;
              }
            });
          } else {
            // If URL extraction failed, show error but keep the selected file
            print('Failed to extract image URL. Response data: ${resp['data']}');
            print('Background path extracted: $backgroundPath');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload succeeded but failed to extract image URL. Please try again.', style: const TextStyle(color: Colors.black)),
                backgroundColor: AppColors.snackbarBackground,
                duration: const Duration(seconds: 5),
              ),
            );
            // Don't clear selected file so user can try uploading again
            return;
          }
          
          final dashboardName = dashboardType == 'superadmin' 
              ? 'Super Admin' 
              : dashboardType == 'branch' 
                  ? 'Branch' 
                  : 'User';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$dashboardName dashboard background updated successfully!', style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.snackbarBackground,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          final msg = (resp['message'] ?? 'Upload failed').toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg, style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.snackbarBackground,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _resetUploadingState(dashboardType);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
          ),
        );
      }
    }
  }
  
  void _resetUploadingState(String dashboardType) {
    switch (dashboardType) {
      case 'superadmin':
        _uploadingSuperAdmin = false;
        break;
      case 'branch':
        _uploadingBranch = false;
        break;
      case 'user':
        _uploadingUser = false;
        break;
    }
    if (mounted) {
      setState(() {});
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
              content: Text(result['message'] ?? 'Password changed successfully', style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.snackbarBackground,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to change password', style: const TextStyle(color: Colors.black)),
              backgroundColor: AppColors.snackbarBackground,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppColors.snackbarBackground,
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
                  // Super Admin Dashboard Background Section
                  _buildDashboardBackgroundSection(
                    'Super Admin Dashboard',
                    'superadmin',
                    _superAdminBackgroundUrl,
                    _selectedSuperAdminFile,
                    _pickingSuperAdmin,
                    _uploadingSuperAdmin,
                  ),
                  const SizedBox(height: 32),
                  
                  // Branch Dashboard Background Section
                  _buildDashboardBackgroundSection(
                    'Branch Dashboard',
                    'branch',
                    _branchBackgroundUrl,
                    _selectedBranchFile,
                    _pickingBranch,
                    _uploadingBranch,
                  ),
                  const SizedBox(height: 32),
                  
                  // User Dashboard Background Section
                  _buildDashboardBackgroundSection(
                    'User Dashboard',
                    'user',
                    _userBackgroundUrl,
                    _selectedUserFile,
                    _pickingUser,
                    _uploadingUser,
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
  
  Widget _buildDashboardBackgroundSection(
    String title,
    String dashboardType,
    String? currentBackgroundUrl,
    File? selectedFile,
    bool picking,
    bool uploading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
            child: selectedFile != null
                ? Image.file(
                    selectedFile, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading selected file: $error');
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                      );
                    },
                  )
                : (currentBackgroundUrl != null && currentBackgroundUrl.isNotEmpty)
                    ? Image.network(
                        currentBackgroundUrl, 
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading network image from $currentBackgroundUrl: $error');
                          return Container(
                            color: Colors.grey.shade100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Failed to load image',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No background set'),
                            ],
                          ),
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: picking ? null : () => _pickImage(dashboardType),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: uploading || selectedFile == null 
                  ? null 
                  : () => _upload(dashboardType),
              icon: uploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(uploading ? 'Uploading...' : 'Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


