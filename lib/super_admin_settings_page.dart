import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'config/api_config.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _loading = true;
    });
    final resp = await ApiService.getAppSettings(widget.accessToken);
    if (mounted) {
      setState(() {
        _loading = false;
        if (resp['success'] == true) {
          final fetched = _normalizeUrl(_extractBackgroundFromData(resp['data']));
          _currentBackgroundUrl = fetched;
        }
      });
    }

    // Fallback to cached value if server returned empty
    if ((_currentBackgroundUrl == null || _currentBackgroundUrl!.isEmpty)) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('app_background_url');
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() {
          _currentBackgroundUrl = cached;
        });
      }
    }
  }

  String? _normalizeUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    String p = path;
    // Ensure it begins with a leading slash
    if (!p.startsWith('/')) p = '/$p';
    // If backend returns '/app/...' or 'app/...', route via '/uploads/app/...'
    if (p.startsWith('/app/')) {
      p = '/uploads$p'; // becomes '/uploads/app/...'
    } else if (p.startsWith('/uploads/app/') || p.startsWith('/uploads/app/')) {
      // already normalized
    } else if (p.startsWith('/uploads/') == false && p.startsWith('/app/') == false && p.startsWith('/uploads') == false && p.startsWith('/app') == false) {
      // Leave other custom paths as-is under base
    }
    return '$base$p';
  }

  String? _extractBackgroundFromData(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final candidates = [
        'backgroundImage',
        'background_image',
        'BackgroundImage',
        'backgroundimage',
      ];
      for (final key in candidates) {
        final val = data[key];
        if (val is String && val.isNotEmpty) return val;
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    if (_picking) return;
    _picking = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1920,
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
        final fileName = 'bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      setState(() {
        _selectedFile = resultFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selected. Ready to upload.')),
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
    setState(() {
      _uploading = true;
    });
    final resp = await ApiService.uploadBackgroundImage(accessToken: widget.accessToken, imageFile: _selectedFile!);
    if (mounted) {
      setState(() {
        _uploading = false;
      });
      final msg = (resp['message'] ?? '').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? (resp['success'] == true ? 'Updated' : 'Failed') : msg)),
      );
      if (resp['success'] == true) {
        setState(() {
          _currentBackgroundUrl = _normalizeUrl(_extractBackgroundFromData(resp['data']));
          _selectedFile = null;
        });
        // Cache for future loads
        final prefs = await SharedPreferences.getInstance();
        if (_currentBackgroundUrl != null && _currentBackgroundUrl!.isNotEmpty) {
          await prefs.setString('app_background_url', _currentBackgroundUrl!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: const Color(0xFFF8BB0C),
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Background Image',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                          ? Image.file(_selectedFile!, fit: BoxFit.cover)
                          : (_currentBackgroundUrl != null && _currentBackgroundUrl!.isNotEmpty)
                              ? Image.network(_currentBackgroundUrl!, fit: BoxFit.cover)
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
                          backgroundColor: const Color(0xFFF8BB0C),
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
                ],
              ),
            ),
    );
  }
}


