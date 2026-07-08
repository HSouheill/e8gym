import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';

/// Centralized service for managing app background images
/// Ensures consistent caching and loading across all pages
class BackgroundImageService {
  // Cache keys for different dashboard types
  static const String _superAdminCacheKey = 'superadmin_background_url';
  static const String _branchCacheKey = 'branch_background_url';
  static const String _userCacheKey = 'user_background_url';
  // Legacy cache key for backward compatibility
  static const String _cacheKey = 'app_background_url';
  
  /// Get cache key for a specific dashboard type
  static String _getCacheKey(String? dashboardType) {
    switch (dashboardType) {
      case 'superadmin':
        return _superAdminCacheKey;
      case 'branch':
        return _branchCacheKey;
      case 'user':
        return _userCacheKey;
      default:
        return _cacheKey; // Legacy/default
    }
  }
  
  /// Normalize a background URL to full URL format
  static String? normalizeUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    String p = path;
    
    // Handle full URLs that might be missing /uploads/ prefix
    if (p.startsWith('http://') || p.startsWith('https://')) {
      // Extract the path part after the domain
      final uri = Uri.tryParse(p);
      if (uri != null) {
        String pathPart = uri.path;
        
        // Check if it's a dashboard background path missing /uploads/
        if ((pathPart.startsWith('/branch-background/') || 
             pathPart.startsWith('/user-background/') || 
             pathPart.startsWith('/superadmin-background/')) &&
            !pathPart.startsWith('/uploads/')) {
          // Fix the path by adding /uploads/
          pathPart = '/uploads$pathPart';
          return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}$pathPart';
        }
      }
      // If already correct or not a dashboard background, return as-is
      return p;
    }
    
    // Handle dashboard-specific background paths (e.g., "branch-background/1765288443.png")
    // These need to be prefixed with /uploads/
    if (p.startsWith('branch-background/') || 
        p.startsWith('user-background/') || 
        p.startsWith('superadmin-background/')) {
      p = '/uploads/$p';
      return '$base$p';
    }
    
    // Ensure it begins with a leading slash
    if (!p.startsWith('/')) p = '/$p';
    
    // If backend returns '/app/...' or 'app/...', route via '/uploads/app/...'
    if (p.startsWith('/app/')) {
      p = '/uploads$p'; // becomes '/uploads/app/...'
    } else if (p.startsWith('/uploads/app/')) {
      // already normalized
    } else if (p.startsWith('/branch-background/') || 
               p.startsWith('/user-background/') || 
               p.startsWith('/superadmin-background/')) {
      // Handle paths that already have leading slash
      p = '/uploads$p'; // becomes '/uploads/branch-background/...'
    } else if (p.startsWith('/uploads/branch-background/') || 
               p.startsWith('/uploads/user-background/') || 
               p.startsWith('/uploads/superadmin-background/')) {
      // already normalized
    }
    
    return '$base$p';
  }
  
  /// Extract background image path from API response data
  /// Supports both single background and dashboard-specific backgrounds
  static String? extractBackgroundFromData(dynamic data, {String? dashboardType}) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      // First try dashboard-specific keys
      if (dashboardType != null) {
        final dashboardKeys = [
          '${dashboardType}_background_image',
          '${dashboardType}_backgroundImage',
          '${dashboardType}_BackgroundImage',
          '${dashboardType}BackgroundImage',
          '${dashboardType}Background',
        ];
        for (final key in dashboardKeys) {
          final val = data[key];
          if (val is String && val.isNotEmpty) return val;
        }
      }
      
      // Fallback to general background keys
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
  /// dashboardType: 'superadmin', 'branch', or 'user'
  /// Returns the normalized URL or null if not found
  static Future<String?> loadBackgroundImage(String accessToken, {String? dashboardType}) async {
    try {
      // First check if we have a cached value for this dashboard type
      // This prevents overwriting dashboard-specific backgrounds with generic ones from API
      if (dashboardType != null) {
        final cached = await getCachedBackgroundUrl(dashboardType: dashboardType);
        if (cached != null && cached.isNotEmpty) {
          // If we have a cached value, prefer it over API response
          // (since backend stores all backgrounds in same field)
          return cached;
        }
      }
      
      // Try to get from API with dashboard type
      final resp = await ApiService.getAppSettings(accessToken, dashboardType: dashboardType);
      if (resp['success'] == true) {
        final backgroundPath = extractBackgroundFromData(resp['data'], dashboardType: dashboardType);
        if (backgroundPath != null && backgroundPath.isNotEmpty) {
          final normalizedUrl = normalizeUrl(backgroundPath);
          if (normalizedUrl != null) {
            // Only cache if we got a dashboard-specific field, not a generic one
            // Check if the data contains dashboard-specific keys
            final data = resp['data'];
            bool isDashboardSpecific = false;
            if (data is Map && dashboardType != null) {
              final dashboardKeys = [
                '${dashboardType}_background_image',
                '${dashboardType}_backgroundImage',
                '${dashboardType}_BackgroundImage',
                '${dashboardType}BackgroundImage',
                '${dashboardType}Background',
              ];
              for (final key in dashboardKeys) {
                if (data.containsKey(key) && data[key] != null) {
                  isDashboardSpecific = true;
                  break;
                }
              }
            }
            
            // Cache the URL with dashboard-specific key only if it's dashboard-specific
            // or if no dashboard type is specified (legacy behavior)
            if (isDashboardSpecific || dashboardType == null) {
              final prefs = await SharedPreferences.getInstance();
              final cacheKey = _getCacheKey(dashboardType);
              await prefs.setString(cacheKey, normalizedUrl);
              // Also cache to legacy key for backward compatibility if no dashboard type specified
              if (dashboardType == null) {
                await prefs.setString(_cacheKey, normalizedUrl);
              }
              return normalizedUrl;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading background image from API: $e');
    }
    
    // Fallback to cached value if API didn't return a background
    return await getCachedBackgroundUrl(dashboardType: dashboardType);
  }
  
  /// Load background image URL from API (no token required for public endpoints)
  /// dashboardType: 'superadmin', 'branch', or 'user'
  /// Returns the normalized URL or null if not found
  static Future<String?> loadBackgroundImagePublic({String? dashboardType}) async {
    try {
      // First check if we have a cached value for this dashboard type
      // This prevents overwriting dashboard-specific backgrounds with generic ones from API
      if (dashboardType != null) {
        final cached = await getCachedBackgroundUrl(dashboardType: dashboardType);
        if (cached != null && cached.isNotEmpty) {
          // If we have a cached value, prefer it over API response
          // (since backend stores all backgrounds in same field)
          return cached;
        }
      }
      
      // Try to get from API without token
      final resp = await ApiService.getAppSettings('', dashboardType: dashboardType);
      if (resp['success'] == true) {
        final backgroundPath = extractBackgroundFromData(resp['data'], dashboardType: dashboardType);
        if (backgroundPath != null && backgroundPath.isNotEmpty) {
          final normalizedUrl = normalizeUrl(backgroundPath);
          if (normalizedUrl != null) {
            // Only cache if we got a dashboard-specific field, not a generic one
            // Check if the data contains dashboard-specific keys
            final data = resp['data'];
            bool isDashboardSpecific = false;
            if (data is Map && dashboardType != null) {
              final dashboardKeys = [
                '${dashboardType}_background_image',
                '${dashboardType}_backgroundImage',
                '${dashboardType}_BackgroundImage',
                '${dashboardType}BackgroundImage',
                '${dashboardType}Background',
              ];
              for (final key in dashboardKeys) {
                if (data.containsKey(key) && data[key] != null) {
                  isDashboardSpecific = true;
                  break;
                }
              }
            }
            
            // Cache the URL with dashboard-specific key only if it's dashboard-specific
            // or if no dashboard type is specified (legacy behavior)
            if (isDashboardSpecific || dashboardType == null) {
              final prefs = await SharedPreferences.getInstance();
              final cacheKey = _getCacheKey(dashboardType);
              await prefs.setString(cacheKey, normalizedUrl);
              // Also cache to legacy key for backward compatibility if no dashboard type specified
              if (dashboardType == null) {
                await prefs.setString(_cacheKey, normalizedUrl);
              }
              return normalizedUrl;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading background image from API: $e');
    }
    
    // Fallback to cached value if API didn't return a background
    return await getCachedBackgroundUrl(dashboardType: dashboardType);
  }
  
  /// Get cached background URL
  /// dashboardType: 'superadmin', 'branch', or 'user'
  static Future<String?> getCachedBackgroundUrl({String? dashboardType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(dashboardType);
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Normalize the cached URL to ensure it has /uploads/ prefix if needed
        // This fixes old cached values that might not have the correct format
        return normalizeUrl(cached);
      }
      // Fallback to legacy cache if dashboard-specific cache is empty
      if (dashboardType != null) {
        final legacyCached = prefs.getString(_cacheKey);
        if (legacyCached != null && legacyCached.isNotEmpty) {
          // Normalize the legacy cached URL as well
          return normalizeUrl(legacyCached);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error getting cached background URL: $e');
    }
    return null;
  }
  
  /// Set and cache background URL (used after upload)
  /// dashboardType: 'superadmin', 'branch', or 'user'
  /// This ensures all pages can immediately access the new background
  static Future<void> setBackgroundUrl(String url, {String? dashboardType}) async {
    try {
      // Normalize the URL before caching to ensure correct format
      final normalizedUrl = normalizeUrl(url);
      if (normalizedUrl == null || normalizedUrl.isEmpty) {
        if (kDebugMode) print('Warning: Failed to normalize URL before caching: $url');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(dashboardType);
      await prefs.setString(cacheKey, normalizedUrl);
      // Also set the alternative key for backward compatibility
      if (dashboardType == null) {
        await prefs.setString('background_image_url', normalizedUrl);
        await prefs.setString(_cacheKey, normalizedUrl);
      }
    } catch (e) {
      if (kDebugMode) print('Error setting background URL: $e');
    }
  }
  
  /// Clear cached background URL
  /// dashboardType: 'superadmin', 'branch', or 'user'. If null, clears all.
  static Future<void> clearBackgroundUrl({String? dashboardType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (dashboardType != null) {
        final cacheKey = _getCacheKey(dashboardType);
        await prefs.remove(cacheKey);
      } else {
        // Clear all dashboard-specific caches
        await prefs.remove(_superAdminCacheKey);
        await prefs.remove(_branchCacheKey);
        await prefs.remove(_userCacheKey);
        await prefs.remove(_cacheKey);
        await prefs.remove('background_image_url'); // Also clear alternative key
      }
    } catch (e) {
      if (kDebugMode) print('Error clearing background URL: $e');
    }
  }
}

