# Google Play Console Data Safety Configuration

## Data Collection and Security

### Personal Information Collected

#### **Email Address**
- **Purpose**: Account creation, authentication, communication
- **Data Type**: Personal info
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit and at rest

#### **Name and Contact Information**
- **Purpose**: User identification, account management
- **Data Type**: Personal info
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit and at rest

#### **Phone Number**
- **Purpose**: Account verification, communication
- **Data Type**: Personal info
- **Collection**: Optional
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit and at rest

#### **Date of Birth**
- **Purpose**: Age verification (13+ requirement)
- **Data Type**: Personal info
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit and at rest

### Device Information Collected

#### **Device ID**
- **Purpose**: Security, fraud prevention, analytics
- **Data Type**: Device or other IDs
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Hashed and encrypted

#### **Device Model and OS**
- **Purpose**: App optimization, compatibility
- **Data Type**: Device or other IDs
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit

#### **App Version**
- **Purpose**: Support, updates, compatibility
- **Data Type**: App activity
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit

### Usage Information Collected

#### **App Interactions**
- **Purpose**: Service improvement, analytics
- **Data Type**: App activity
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit

#### **Class Bookings**
- **Purpose**: Service provision, booking management
- **Data Type**: App activity
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit and at rest

#### **Gym Branch Interactions**
- **Purpose**: Service provision, location services
- **Data Type**: App activity
- **Collection**: Required
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit and at rest

### Location Information

#### **Branch Location Data**
- **Purpose**: Location-based services, branch finder
- **Data Type**: Approximate location
- **Collection**: Optional (with user consent)
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit

#### **GPS Coordinates**
- **Purpose**: Location-based services
- **Data Type**: Precise location
- **Collection**: Optional (with explicit consent)
- **Sharing**: Not shared with third parties
- **Security**: Encrypted in transit

## Data Security Practices

### Encryption
- **In Transit**: All data encrypted using HTTPS/TLS
- **At Rest**: Sensitive data encrypted using flutter_secure_storage
- **Authentication**: Secure token-based authentication

### Data Minimization
- Only collect data necessary for service provision
- No unnecessary data collection
- Regular data cleanup and retention policies

### User Control
- Users can delete their accounts
- Users can request data deletion
- Users can opt-out of non-essential data collection
- Clear privacy controls in app settings

## Third-Party Services

### Payment Processing
- **Service**: Third-party payment processor
- **Data Shared**: Payment information only
- **Purpose**: Payment processing
- **Security**: PCI DSS compliant

### Analytics
- **Service**: Firebase Analytics (if used)
- **Data Shared**: Anonymized usage data
- **Purpose**: App improvement
- **Security**: Encrypted and anonymized

## Data Retention

### Account Data
- **Retention Period**: Until account deletion
- **Deletion**: Upon user request or account closure
- **Backup**: Secure encrypted backups

### Usage Data
- **Retention Period**: 2 years maximum
- **Deletion**: Automatic after retention period
- **Anonymization**: Data anonymized after 1 year

### Security Logs
- **Retention Period**: 1 year
- **Purpose**: Security monitoring
- **Access**: Restricted to security team

## Compliance

### GDPR Compliance
- Data subject rights implemented
- Lawful basis for processing
- Data protection impact assessments
- Privacy by design principles

### CCPA Compliance
- California consumer rights
- Data sale opt-out mechanisms
- Transparent data practices
- Consumer request handling

### Children's Privacy
- **Age Requirement**: 13+ years old
- **Verification**: Date of birth collection
- **Protection**: No data collection from children under 13
- **COPPA Compliance**: Full compliance with COPPA

## Data Safety Questionnaire Answers

### Does your app collect or share any of the required user data types?
**Answer**: Yes

### Personal info
- **Email address**: Yes (Required)
- **Name**: Yes (Required)
- **Phone number**: Yes (Optional)
- **Date of birth**: Yes (Required)

### Device or other IDs
- **Device ID**: Yes (Required)

### App activity
- **App interactions**: Yes (Required)
- **In-app search history**: No
- **Installed apps**: No
- **Other app activity**: Yes (Class bookings, gym interactions)

### Location
- **Approximate location**: Yes (Optional)
- **Precise location**: Yes (Optional)

### Financial info
- **Payment info**: Yes (Through third-party processor)

### Photos and videos
- **Photos**: Yes
- **Videos**: No

### Audio
- **Audio files**: No
- **Voice or sound recordings**: No

### Files and docs
- **Files and docs**: No

### Contacts
- **Contacts**: No

### App info and performance
- **Crash logs**: Yes (Required)
- **Diagnostics**: Yes (Required)
- **Other app performance data**: Yes (Required)

### Web browsing
- **Web browsing history**: No

### Installed apps
- **Installed apps**: No

### Other sensitive permissions
- **Camera**: Yes (Optional)
- **Microphone**: No
- **SMS**: No
- **Call logs**: No

## Data Sharing Practices

### Is this data shared with third parties?
**Answer**: No (except payment processing)

### Is this data collected, shared, or sold for advertising purposes?
**Answer**: No

### Is this data collected, shared, or sold for developer communications?
**Answer**: No

### Is this data collected, shared, or sold for fraud prevention, security, or compliance?
**Answer**: Yes (Device ID for security purposes)

### Is this data collected, shared, or sold for analytics?
**Answer**: No

### Is this data collected, shared, or sold for personalization?
**Answer**: No

### Is this data collected, shared, or sold for app functionality?
**Answer**: Yes (All data collected for app functionality)

### Is this data collected, shared, or sold for other purposes?
**Answer**: No

## Security Practices

### Is this data encrypted in transit?
**Answer**: Yes (HTTPS/TLS encryption)

### Can users request that their data be deleted?
**Answer**: Yes (Account deletion available)

### Is this data collection optional?
**Answer**: Yes (Except essential data for app functionality)

### Is this data collection required for the app to function?
**Answer**: Yes (Core functionality requires data collection)

---

**Last Updated**: [Current Date]
**Version**: 1.0.0
**Status**: Ready for Google Play Console Submission
