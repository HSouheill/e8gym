import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

/// Centralized service for managing app background images
/// Ensures consistent caching and loading across all pages
class BackgroundImageService {
  // Use a single consistent cache key for all pages
  static const String _cacheKey = 'app_background_url';
  
  /// Normalize a background URL to full URL format
  static String? normalizeUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    String p = path;
    
    // Ensure it begins with a leading slash
    if (!p.startsWith('/')) p = '/$p';
    
    // If backend returns '/app/...' or 'app/...', route via '/uploads/app/...'
    if (p.startsWith('/app/')) {
      p = '/uploads$p'; // becomes '/uploads/app/...'
    } else if (p.startsWith('/uploads/app/')) {
      // already normalized
    }
    
    return '$base$p';
  }
  
  /// Extract background image path from API response data
  static String? extractBackgroundFromData(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final candidates = [
        'backgroundImage',
        'background_image',
        'BackgroundImage',
        'backgroundimage',
        'background',
      ];
      for (final key in candidates) {
        final val = data[key];
        if (val is String && val.isNotEmpty) return val;
      }
    }
    return null;
  }
  
  /// Load background image URL from API and cache it
  /// Returns the normalized URL or null if not found
  static Future<String?> loadBackgroundImage(String accessToken) async {
    try {
      // First try to get from API
      final resp = await ApiService.getAppSettings(accessToken);
      if (resp['success'] == true) {
        final backgroundPath = extractBackgroundFromData(resp['data']);
        if (backgroundPath != null && backgroundPath.isNotEmpty) {
          final normalizedUrl = normalizeUrl(backgroundPath);
          if (normalizedUrl != null) {
            // Cache the URL
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_cacheKey, normalizedUrl);
            return normalizedUrl;
          }
        }
      }
    } catch (e) {
      print('Error loading background image from API: $e');
    }
    
    // Fallback to cached value if API didn't return a background
    return await getCachedBackgroundUrl();
  }
  
  /// Load background image URL from API (no token required for public endpoints)
  /// Returns the normalized URL or null if not found
  static Future<String?> loadBackgroundImagePublic() async {
    try {
      // Try to get from API without token
      final resp = await ApiService.getAppSettings('');
      if (resp['success'] == true) {
        final backgroundPath = extractBackgroundFromData(resp['data']);
        if (backgroundPath != null && backgroundPath.isNotEmpty) {
          final normalizedUrl = normalizeUrl(backgroundPath);
          if (normalizedUrl != null) {
            // Cache the URL
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_cacheKey, normalizedUrl);
            return normalizedUrl;
          }
        }
      }
    } catch (e) {
      print('Error loading background image from API: $e');
    }
    
    // Fallback to cached value if API didn't return a background
    return await getCachedBackgroundUrl();
  }
  
  /// Get cached background URL
  static Future<String?> getCachedBackgroundUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    } catch (e) {
      print('Error getting cached background URL: $e');
    }
    return null;
  }
  
  /// Set and cache background URL (used after upload)
  /// This ensures all pages can immediately access the new background
  static Future<void> setBackgroundUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, url);
      // Also set the alternative key for backward compatibility
      await prefs.setString('background_image_url', url);
    } catch (e) {
      print('Error setting background URL: $e');
    }
  }
  
  /// Clear cached background URL
  static Future<void> clearBackgroundUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove('background_image_url'); // Also clear alternative key
    } catch (e) {
      print('Error clearing background URL: $e');
    }
  }
}

