# Admin Integration System

This document describes the integration between the Flutter frontend and Go backend for the E8Gym admin system.

## Overview

The system provides a complete admin authentication and management flow:
1. **Admin Login Page** - For both regular admins and super admins
2. **Create Admin Page** - For super admins to create new admin accounts
3. **Backend Integration** - HTTP API calls to Go backend endpoints

## Features

### Admin Login Page (`lib/admin_login_page.dart`)
- **Admin Type Selection**: Choose between "Admin" and "Super Admin"
- **Username/Email Field**: For admin credentials
- **Password Field**: Secure password input
- **Backend Integration**: Makes HTTP requests to Go backend
- **Loading States**: Visual feedback during API calls
- **Error Handling**: User-friendly error messages

### Create Admin Page (`lib/create_admin_page.dart`)
- **Admin Type Selection**: Create "Admin" or "Super Admin" accounts
- **User Information**: Full name, email, password fields
- **Permission Management**: Granular permissions with checkboxes
- **Form Validation**: Input validation and error handling
- **Success Feedback**: Confirmation messages and form reset

### API Service (`lib/services/api_service.dart`)
- **HTTP Client**: Uses `http` package for API calls
- **Endpoint Management**: Centralized API endpoint configuration
- **Error Handling**: Comprehensive error handling and response parsing
- **Response Formatting**: Consistent response structure

### Configuration (`lib/config/api_config.dart`)
- **Environment Management**: Easy switching between dev/staging/production
- **URL Configuration**: Centralized base URL management
- **Timeout Settings**: Configurable connection and receive timeouts
- **Header Management**: Default headers for all API requests

## Backend Integration

### SuperAdmin Login Endpoint
```
POST /superadmin/login
Content-Type: application/json

{
  "email": "superadmin@e8gym.com",
  "password": "password123"
}
```

### Response Format
```json
{
  "success": true,
  "message": "SuperAdmin login successful",
  "data": {
    "user": {
      "id": "user_id",
      "email": "superadmin@e8gym.com",
      "role": "super_admin",
      "full_name": "Super Admin"
    },
    "access_token": "jwt_token_here",
    "token_type": "Bearer",
    "expires_in": 86400
  }
}
```

## Setup Instructions

### 1. Update Backend URL
Edit `lib/config/api_config.dart`:
```dart
static const String currentEnvironment = 'dev'; // or 'staging', 'production'
```

### 2. Configure Go Backend
Ensure your Go backend is running and accessible at the configured URL.

### 3. Environment Variables
Set the following environment variables in your Go backend:
```bash
SUPERADMIN_EMAIL=your_superadmin_email
SUPERADMIN_PASSWORD=your_superadmin_password
```

## Usage Flow

### Super Admin Login
1. Navigate to admin login page
2. Select "Super Admin" from dropdown
3. Enter credentials
4. System calls `/superadmin/login` endpoint
5. On success, redirects to create admin page

### Regular Admin Login
1. Navigate to admin login page
2. Select "Admin" from dropdown
3. Enter credentials
4. System calls `/admin/login` endpoint
5. On success, can access admin dashboard

### Creating New Admins
1. Super admin logs in successfully
2. Navigate to create admin page
3. Fill out admin details and permissions
4. Submit form to create new admin account

## Error Handling

The system handles various error scenarios:
- **Network Errors**: Connection timeouts, server unavailable
- **Authentication Errors**: Invalid credentials, account deactivated
- **Validation Errors**: Missing fields, invalid email format
- **Server Errors**: Internal server errors, database issues

## Security Features

- **Password Validation**: Minimum length requirements
- **Input Sanitization**: Prevents common injection attacks
- **Secure Headers**: Proper Content-Type and Accept headers
- **Token Management**: JWT token handling for authenticated sessions

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  flutter_svg: ^2.0.9
```

## Testing

### Local Development
1. Start Go backend on `localhost:8080`
2. Run Flutter app
3. Test admin login with valid credentials

### Network Testing
- Test with different network conditions
- Verify timeout handling
- Check error message display

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check if Go backend is running
   - Verify port number in configuration

2. **CORS Errors**
   - Ensure backend allows requests from Flutter app
   - Check header configuration

3. **Authentication Failures**
   - Verify environment variables in Go backend
   - Check email/password format

4. **Loading State Issues**
   - Ensure loading state is properly reset
   - Check for unhandled exceptions

## Future Enhancements

- **Token Storage**: Implement secure token storage
- **Session Management**: Add session timeout handling
- **Offline Support**: Cache admin data for offline access
- **Biometric Authentication**: Add fingerprint/face ID support
- **Multi-Factor Authentication**: Implement 2FA for admin accounts
