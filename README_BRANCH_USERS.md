# Branch Users Integration

This document describes the implementation of branch user management functionality for the E8Gym Flutter application.

## Overview

The branch users feature allows branch administrators to:
- View all users who have booked classes at their branch
- View detailed user information and statistics
- Search and filter users by name, email, and date range
- View individual user booking history
- Access user statistics and analytics

## Backend Integration

The feature integrates with the following backend endpoints:

### Branch User Management Endpoints

1. **GET /api/branch/users** - Get all users at the branch with pagination and filtering
2. **GET /api/branch/users/stats** - Get branch user statistics
3. **GET /api/branch/users/:userId** - Get specific user detail with booking history
4. **GET /api/branch/users/:userId/bookings** - Get all bookings for a specific user

### Authentication

All endpoints require:
- JWT authentication (`Bearer` token)
- `BranchAdmin` role

### Query Parameters

#### Get Branch Users
- `page` (int): Page number for pagination (default: 1)
- `limit` (int): Number of users per page (default: 10, max: 100)
- `search` (string): Search by user name or email
- `date_from` (string): Filter users by first booking date (YYYY-MM-DD)
- `date_to` (string): Filter users by last booking date (YYYY-MM-DD)

#### Get User Bookings
- `page` (int): Page number for pagination (default: 1)
- `limit` (int): Number of bookings per page (default: 10, max: 100)
- `status` (string): Filter by booking status
- `date_from` (string): Filter by booking date (YYYY-MM-DD)
- `date_to` (string): Filter by booking date (YYYY-MM-DD)
- `class_date` (string): Filter by specific class date (YYYY-MM-DD)

## Frontend Implementation

### Models

#### `BranchUserResponse`
```dart
class BranchUserResponse {
  final String id;
  final String userId;
  final String branchId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final DateTime? dateOfBirth;
  final bool isActive;
  final bool isVerified;
  final DateTime? firstBooked;
  final DateTime? lastBooked;
  final int totalBookings;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### `BranchUserStatsResponse`
```dart
class BranchUserStatsResponse {
  final int totalUsers;
  final int activeUsers;
  final int newUsersThisMonth;
  final int totalBookings;
  final double averageBookingsPerUser;
  final Map<String, int> bookingsByStatus;
  final Map<String, int> bookingsByMonth;
}
```

#### `BranchUserBooking`
```dart
class BranchUserBooking {
  final String id;
  final String userId;
  final String classId;
  final String classType;
  final String? branchId;
  final String scheduleId;
  final String status;
  final DateTime bookedAt;
  final DateTime classDate;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String className;
  final String instructor;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
}
```

### Main Pages

#### BranchUsersPage (`lib/branch_users_page.dart`)
- **User List**: Displays all users with search and filtering capabilities
- **Statistics Cards**: Shows key metrics (total users, active users, new users, avg bookings)
- **Search & Filters**: Real-time search by name/email and date range filtering
- **Pagination**: Load more functionality for large user lists
- **User Cards**: Compact display of user information with status indicators

#### BranchUserDetailPage (embedded in BranchUsersPage)
- **User Profile**: Detailed user information with avatar and contact details
- **Booking History**: Complete list of user's bookings with status and timing
- **Pagination**: Load more bookings functionality
- **Status Indicators**: Visual status badges for bookings

### Integration with Branch Dashboard

#### Updated BranchDashboardPage (`lib/branch_dashboard_page.dart`)
- **New Users Tab**: Added third tab for user management
- **Quick Actions**: Added "Users" action card in dashboard
- **Navigation**: Direct access to BranchUsersPage from dashboard

### Features

#### User Management
- **User List View**: Paginated list of all branch users
- **Search Functionality**: Real-time search by name or email
- **Date Filtering**: Filter users by booking date range
- **User Statistics**: Overview of user metrics and trends

#### User Details
- **Profile Information**: Complete user profile with contact details
- **Status Indicators**: Active/Inactive and Verified/Unverified status
- **Booking History**: Complete booking timeline with status
- **Booking Details**: Class information, timing, and booking dates

#### Statistics Dashboard
- **Total Users**: Count of all users at the branch
- **Active Users**: Users with recent activity
- **New Users This Month**: Recent user registrations
- **Average Bookings**: Average bookings per user
- **Visual Indicators**: Color-coded status badges

### UI/UX Features

#### Design Consistency
- **Gradient Background**: Consistent with app theme
- **Card-based Layout**: Clean, organized information display
- **Status Badges**: Color-coded indicators for user and booking status
- **Responsive Design**: Adapts to different screen sizes

#### User Experience
- **Pull-to-Refresh**: Refresh data by pulling down
- **Load More**: Infinite scrolling for large datasets
- **Search Debouncing**: Optimized search performance
- **Error Handling**: Graceful error states with retry options
- **Loading States**: Clear loading indicators

#### Navigation
- **Back Navigation**: Consistent back button behavior
- **Tab Navigation**: Easy switching between dashboard sections
- **Deep Linking**: Direct access to user details

## Usage

### For Branch Administrators

1. **Access User Management**:
   - Navigate to Branch Dashboard
   - Click on "Users" tab or "Users" quick action card

2. **View User List**:
   - See all users who have booked at the branch
   - Use search to find specific users
   - Apply date filters to view users by activity period

3. **View User Details**:
   - Tap on any user card to view detailed information
   - See complete booking history
   - View user status and verification information

4. **Monitor Statistics**:
   - View key metrics at the top of the users page
   - Track user growth and engagement
   - Monitor booking patterns

### API Integration

The feature is fully integrated with the backend API and handles:
- **Authentication**: Automatic token management
- **Error Handling**: Graceful error states and retry mechanisms
- **Pagination**: Efficient data loading for large datasets
- **Real-time Updates**: Fresh data on page refresh

## Future Enhancements

Potential improvements for the branch user management feature:

1. **User Communication**: Send notifications or messages to users
2. **Advanced Filtering**: Filter by booking status, class type, etc.
3. **Export Functionality**: Export user lists and booking data
4. **User Analytics**: Detailed analytics and reporting
5. **Bulk Operations**: Perform actions on multiple users
6. **User Notes**: Add internal notes about users
7. **Integration with CRM**: Connect with customer relationship management systems

## Technical Notes

### Performance Considerations
- **Pagination**: Efficient loading of large user lists
- **Search Optimization**: Debounced search to reduce API calls
- **Caching**: Consider implementing local caching for frequently accessed data
- **Image Optimization**: Avatar generation without network requests

### Security Considerations
- **Role-based Access**: Only BranchAdmin can access user data
- **Data Privacy**: Ensure user data is handled securely
- **Token Management**: Proper JWT token handling and refresh

### Error Handling
- **Network Errors**: Graceful handling of connection issues
- **API Errors**: Clear error messages for different failure scenarios
- **Data Validation**: Proper validation of API responses
- **Fallback States**: Appropriate UI states for error conditions
