# E8Gym - Endurance Eight Gym App

A Flutter application for the Endurance Eight sports brand, featuring authentication, gym management, and product services.

## Features

- **User Authentication**: Complete signup and login system
- **Professional UI**: Modern design with gold accents and dark theme
- **Form Validation**: Client-side validation matching backend requirements
- **Secure Storage**: Token management and user data persistence
- **API Integration**: RESTful API integration with Go backend

## Authentication System

The app includes a complete authentication system that integrates with your Go backend:

### Backend Endpoints Supported

- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User authentication
- `POST /api/auth/refresh` - Token refresh
- `POST /api/auth/logout` - User logout

### Features

- **Form Validation**: Matches backend validation rules
- **Age Requirement**: Users must be at least 13 years old
- **Password Strength**: Minimum 8 characters with uppercase, lowercase, and numbers
- **Phone Validation**: Country code and phone number validation
- **Secure Storage**: JWT tokens stored securely using SharedPreferences

## Project Structure

```
lib/
├── main.dart              # Main app entry point
├── signup_page.dart       # User registration page
├── home_page.dart         # Post-authentication home page
├── services/
│   ├── auth_service.dart      # Authentication API calls
│   └── storage_service.dart   # Local data storage
├── models/
│   └── auth_models.dart       # Data models for API
└── utils/
    ├── api_config.dart        # API configuration
    └── validation_utils.dart  # Form validation logic
```

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure API Endpoint

Update `lib/utils/api_config.dart` with your backend URL:

```dart
static const String baseUrl = 'http://your-backend-url:port';
```

### 3. Run the App

```bash
flutter run
```

## Dependencies

- `http: ^1.1.0` - HTTP client for API calls
- `shared_preferences: ^2.2.2` - Secure local storage
- `google_fonts: ^6.1.0` - Custom typography
- `flutter_svg: ^2.0.9` - SVG image support

## Authentication Flow

1. **Signup**: User fills out registration form with validation
2. **API Call**: Form data sent to backend signup endpoint
3. **Token Storage**: Access and refresh tokens saved locally
4. **User Data**: User information stored for app use
5. **Navigation**: User redirected to home page
6. **Logout**: Tokens cleared and user returned to login

## Form Validation Rules

- **Full Name**: 2-100 characters
- **Email**: Valid email format
- **Password**: Minimum 8 characters, uppercase + lowercase + number
- **Phone**: Valid phone number format
- **Country Code**: Valid country code (e.g., +961)
- **Date of Birth**: User must be at least 13 years old

## Security Features

- JWT token management
- Secure local storage
- Input sanitization
- Age verification
- Password strength requirements

## Backend Integration

The app is designed to work with your Go backend authentication system. Ensure your backend:

- Accepts the request format defined in `SignupRequest`
- Returns responses matching `AuthResponse`
- Implements proper JWT token handling
- Includes rate limiting and validation

## Customization

- Update colors in `Color(0xFFF8BB0C)` for brand colors
- Modify validation rules in `validation_utils.dart`
- Adjust API endpoints in `api_config.dart`
- Customize UI components in individual page files

## Support

For issues or questions about the authentication system, check:

1. API endpoint configuration
2. Network connectivity
3. Backend service status
4. Form validation errors
5. Token storage permissions
