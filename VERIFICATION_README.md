# DriveGenius Verification System

This document describes the implementation of the verification system for the DriveGenius app, which allows users to verify their identity and build trust within the platform.

## Overview

The verification system is designed to handle two different user types:
- **Drivers**: Require ID document upload, selfie, and address confirmation
- **Clients**: Require selfie and address confirmation

## Features

### For Drivers
1. **ID Document Upload**
   - Support for PDF, JPG, JPEG, PNG files
   - File validation and preview
   - Upload to Supabase storage

2. **Selfie Capture**
   - Camera integration for taking photos
   - Gallery selection option
   - Image optimization (800x800 max, 80% quality)

3. **Address Confirmation**
   - House number
   - Street name
   - Town/City
   - State
   - Form validation

4. **Verification Submission**
   - All data stored in Supabase
   - Files uploaded to appropriate storage buckets
   - User profile updated with verification status

### For Clients
1. **Selfie Capture**
   - Same functionality as drivers
   - Camera and gallery options

2. **Address Confirmation**
   - Same address fields as drivers
   - Form validation

3. **Verification Submission**
   - Simplified process compared to drivers
   - Same storage and database updates

## Technical Implementation

### Dependencies Added
```yaml
# File handling and image processing
file_picker: ^6.1.1
image_picker: ^1.0.7
path: ^1.8.3

# UI enhancements
cached_network_image: ^3.3.1
```

### Key Components

#### 1. VerificationScreen (`lib/screens/verification_screen.dart`)
- Multi-step verification flow
- Dynamic steps based on user role
- File upload and image capture
- Form validation
- Supabase integration

#### 2. VerificationBadge (`lib/widgets/verification_badge.dart`)
- Displays verification status
- Two variants: badge and status widget
- Customizable size and text display

#### 3. SupabaseStorageService (`lib/services/supabase_storage_service.dart`)
- File upload to Supabase storage
- Verification data storage
- User profile updates

### Storage Structure

#### Supabase Tables
- `profiles`: User profile information including verification status
- `verifications`: Detailed verification data and file URLs

#### Storage Buckets
- `profile-images`: User profile photos and selfies
- `documents`: ID documents and verification files

### Data Flow

1. **User initiates verification**
   - Navigate to verification screen
   - Steps determined by user role

2. **File/Image Collection**
   - ID document upload (drivers only)
   - Selfie capture/selection
   - Address information input

3. **Data Processing**
   - Files uploaded to Supabase storage
   - URLs stored in verification table
   - User profile updated

4. **Completion**
   - User redirected to appropriate dashboard
   - Verification badge displayed on profile
   - Status updated in database

## Usage Examples

### Adding Verification Badge to Profile
```dart
import '../widgets/verification_badge.dart';

// Simple badge
VerificationBadge(
  isVerified: user.isVerified,
  size: 20,
)

// Status widget with tap action
VerificationStatusWidget(
  isVerified: user.isVerified,
  verificationStatus: 'pending',
  onVerifyTap: () => Navigator.pushNamed(context, '/verification'),
)
```

### Checking Verification Status
```dart
if (user.isVerified) {
  // User is verified, show verified features
  showVerifiedFeatures();
} else {
  // User needs verification
  showVerificationPrompt();
}
```

### Navigating to Verification
```dart
// From profile screen
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/verification');
  },
  child: Text('Complete Verification'),
)
```

## Configuration

### Supabase Setup
Ensure your Supabase project has:
1. Storage buckets configured for `profile-images` and `documents`
2. Tables for `profiles` and `verifications`
3. Proper RLS policies for security

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take verification photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select verification images</string>
```

## Security Considerations

1. **File Validation**: Only allow specific file types and sizes
2. **Storage Security**: Use Supabase RLS policies to control access
3. **Data Privacy**: Sensitive information stored securely
4. **User Consent**: Clear communication about data usage

## Future Enhancements

1. **OCR Integration**: Automatic text extraction from ID documents
2. **Face Recognition**: Verify selfie matches ID document
3. **Address Verification**: Integration with address validation services
4. **Real-time Updates**: WebSocket notifications for verification status
5. **Admin Panel**: Manual verification review system

## Troubleshooting

### Common Issues

1. **File Upload Fails**
   - Check Supabase storage bucket permissions
   - Verify file size and type restrictions
   - Check network connectivity

2. **Image Capture Issues**
   - Ensure camera permissions are granted
   - Check device camera functionality
   - Verify image picker configuration

3. **Verification Not Saving**
   - Check Supabase connection
   - Verify table structure and permissions
   - Check for validation errors

### Debug Mode
Enable debug logging in `SupabaseStorageService`:
```dart
print('🔄 Uploading file: $bucket/$path');
print('✅ File uploaded successfully: $publicUrl');
print('❌ Error uploading file: $e');
```

## Support

For technical support or questions about the verification system:
1. Check the Supabase documentation
2. Review Flutter package documentation
3. Check app logs for error messages
4. Verify configuration settings

---

**Note**: This verification system is designed to be secure, user-friendly, and scalable. Always test thoroughly in development before deploying to production.
