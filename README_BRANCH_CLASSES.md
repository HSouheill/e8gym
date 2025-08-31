# Branch Classes Integration

This document describes the implementation of branch classes functionality for the E8Gym Flutter application.

## Overview

The branch classes feature allows branch administrators to:
- View all classes assigned to their branch
- View detailed information about each class
- Edit class schedules (add, modify, remove schedule entries)
- Manage class timing and availability

**All functionality is now integrated directly into the BranchDashboardPage for better user experience.**

## Backend Integration

The feature integrates with the following backend endpoints:

### Branch Class Management Endpoints

1. **GET /api/branch/classes** - Get all classes for the authenticated branch
2. **GET /api/branch/classes/:classId** - Get specific class details
3. **PUT /api/branch/classes/:classId/schedule** - Update class schedule

### Authentication

All endpoints require:
- JWT authentication (`Bearer` token)
- `BranchAdmin` role

## Frontend Implementation

### Models

#### `BranchClassResponse`
```dart
class BranchClassResponse {
  final String id;
  final String name;
  final String description;
  final int duration;
  final int capacity;
  final List<ClassSchedule> schedule;
  final String instructor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### `BranchClassListResponse`
```dart
class BranchClassListResponse {
  final List<BranchClassResponse> classes;
  final int total;
  final int page;
  final int limit;
}
```

#### `UpdateClassScheduleRequest`
```dart
class UpdateClassScheduleRequest {
  final List<ClassSchedule> schedule;
}
```

### Main Page

#### BranchDashboardPage (`lib/branch_dashboard_page.dart`)
- **Integrated Dashboard**: Single page with tabbed interface
- **Dashboard Tab**: Shows branch information and quick actions
- **Classes Tab**: Displays all classes with management capabilities
- **Class Management**: View details, edit schedules directly in dialogs
- **Real-time Updates**: Automatic refresh after schedule changes
- **Error Handling**: Comprehensive error states and user feedback

### Features

#### Tabbed Interface
- **Dashboard Tab**: Branch info, quick actions, session info
- **Classes Tab**: List of all classes with management options
- **Dynamic Class Count**: Shows number of classes in tab title

#### Class Management
- **View Classes**: List all classes with status, instructor, capacity
- **View Details**: Comprehensive class information in dialog
- **Edit Schedule**: Add, edit, remove schedule entries with validation
- **Time Validation**: Prevents overlapping schedules and invalid times
- **Real-time Updates**: Automatic refresh after changes

#### Schedule Management
- **Add Schedule**: Add new time slots for specific days
- **Edit Schedule**: Modify existing schedule entries
- **Remove Schedule**: Delete unwanted schedule entries
- **Validation**: Prevents overlapping schedules on the same day
- **Time Validation**: Ensures end time is after start time

### API Service Methods

#### `ApiService.getBranchClasses()`
```dart
static Future<Map<String, dynamic>> getBranchClasses(
  String accessToken, {
  int page = 1,
  int limit = 20,
}) async
```

#### `ApiService.getBranchClass()`
```dart
static Future<Map<String, dynamic>> getBranchClass(
  String classId,
  String accessToken,
) async
```

#### `ApiService.updateBranchClassSchedule()`
```dart
static Future<Map<String, dynamic>> updateBranchClassSchedule(
  String classId,
  UpdateClassScheduleRequest scheduleData,
  String accessToken,
) async
```

## User Experience

### Navigation Flow
1. **Branch Login**: User logs in as branch admin
2. **Dashboard Access**: Navigate to branch dashboard
3. **Tab Navigation**: Switch between Dashboard and Classes tabs
4. **Class Management**: View and edit classes directly in dialogs
5. **Schedule Updates**: Make changes and save with immediate feedback

### Interface Design
- **Consistent Design**: Matches the app's design language with gradient backgrounds
- **Tabbed Layout**: Clean separation between dashboard and class management
- **Dialog-based Editing**: Intuitive schedule editing without page navigation
- **Loading States**: Shows progress indicators during API calls
- **Error Handling**: Displays user-friendly error messages
- **Success Feedback**: Confirms successful operations

## Validation Rules

### Schedule Validation
1. **Time Order**: End time must be after start time
2. **No Overlaps**: Schedules on the same day cannot overlap
3. **Valid Days**: Day of week must be 0-6 (Sunday-Saturday)
4. **Non-empty**: At least one schedule entry required

### Class Data Validation
1. **Capacity**: Must be between 1 and 100 students
2. **Duration**: Must be between 1 and 480 minutes (8 hours)
3. **Required Fields**: Name, description, instructor are required

## Error Handling

### Network Errors
- Connection timeout handling
- Server error responses
- Offline state management

### Validation Errors
- Client-side validation before API calls
- Server-side validation error display
- User-friendly error messages

### Authentication Errors
- Token expiration handling
- Unauthorized access prevention
- Automatic logout on auth failures

## Usage Flow

1. **Branch Login**: User logs in as branch admin
2. **Dashboard Access**: Navigate to branch dashboard
3. **Classes Tab**: Tap on "Classes" tab to view all classes
4. **View Details**: Tap "View Details" for comprehensive information
5. **Edit Schedule**: Tap "Edit Schedule" to modify class timing
6. **Save Changes**: Confirm schedule updates in dialog

## Security Considerations

- **JWT Authentication**: All requests require valid access token
- **Role-based Access**: Only `BranchAdmin` role can access these endpoints
- **Data Isolation**: Branch can only access their own classes
- **Input Validation**: Both client and server-side validation

## Future Enhancements

### Potential Features
1. **Bulk Schedule Operations**: Edit multiple classes at once
2. **Schedule Templates**: Pre-defined schedule patterns
3. **Calendar View**: Visual calendar interface for schedule management
4. **Conflict Detection**: Advanced conflict detection algorithms
5. **Schedule Analytics**: Usage statistics and insights
6. **Export Functionality**: Export schedules to calendar apps

### Technical Improvements
1. **Caching**: Implement local caching for better performance
2. **Offline Support**: Basic offline functionality
3. **Real-time Updates**: WebSocket integration for live updates
4. **Advanced Filtering**: Filter classes by various criteria
5. **Search Functionality**: Search within class names and descriptions

## Testing

### Manual Testing Checklist
- [ ] Login as branch admin
- [ ] Navigate to dashboard
- [ ] Switch between Dashboard and Classes tabs
- [ ] View class details in dialog
- [ ] Add new schedule entry
- [ ] Edit existing schedule
- [ ] Remove schedule entry
- [ ] Validate time conflicts
- [ ] Test error scenarios
- [ ] Verify real-time updates

### API Testing
- [ ] Test all endpoints with valid authentication
- [ ] Test with invalid/expired tokens
- [ ] Test with invalid class IDs
- [ ] Test schedule validation rules
- [ ] Test error response handling

## Dependencies

### Required Packages
- `http`: For API communication
- `flutter/material.dart`: UI components
- Custom models and services

### File Structure
```
lib/
├── models/
│   ├── branch_class_models.dart
│   └── standalone_class_models.dart
├── services/
│   └── api_service.dart
├── utils/
│   └── validation_utils.dart
└── branch_dashboard_page.dart
```

## Configuration

### API Configuration
Update `lib/config/api_config.dart` with the correct endpoints:

```dart
static const String getBranchClasses = '/api/branch/classes';
static const String getBranchClass = '/api/branch/classes';
static const String updateBranchClassSchedule = '/api/branch/classes';
```

### Environment Setup
Ensure the correct base URL is set in `ApiConfig.currentEnvironment`:
- `dev`: Android emulator
- `local`: iOS simulator  
- `network`: Physical device
- `production`: Production environment
