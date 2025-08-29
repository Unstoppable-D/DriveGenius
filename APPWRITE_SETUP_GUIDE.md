# Appwrite Setup Guide for DriveGenius

## Database Setup

### 1. Create Database
- **Database ID**: `drive_genius_db`
- **Database Name**: DriveGenius Database

### 2. Create Collections

#### Profiles Collection
- **Collection ID**: `profiles`
- **Collection Name**: User Profiles

**Attributes:**
- `name` (String, required)
- `email` (String, required)
- `phone` (String, required)
- `role` (String, required) - Values: "client", "driver"
- `isVerified` (Boolean, required)
- `profileImage` (String, optional)
- `createdAt` (String, required) - ISO 8601 format
- `updatedAt` (String, required) - ISO 8601 format

**Permissions (CRITICAL for fixing dashboard navigation):**
```
Read: users:{{user.$id}}
Write: users:{{user.$id}}
Create: users:{{user.$id}}
Update: users:{{user.$id}}
Delete: users:{{user.$id}}
```

**Important Notes:**
- The `documentId` must be the same as the Appwrite Auth `userId`
- Each user can only read/update their own profile
- The `role` field must exactly match "client" or "driver" (case-sensitive)

#### Verifications Collection
- **Collection ID**: `verifications`
- **Collection Name**: User Verifications

**Attributes:**
- `userId` (String, required)
- `verification_status` (String, required)
- `documents` (String[], optional)
- `createdAt` (String, required)
- `updatedAt` (String, required)

**Permissions:**
```
Read: users:{{user.$id}}
Write: users:{{user.$id}}
Create: users:{{user.$id}}
Update: users:{{user.$id}}
Delete: users:{{user.$id}}
```

### 3. Storage Buckets

#### Profile Images Bucket
- **Bucket ID**: `profile-images`
- **Bucket Name**: Profile Images

**Permissions:**
```
Read: users:{{user.$id}}
Write: users:{{user.$id}}
Create: users:{{user.$id}}
Delete: users:{{user.$id}}
```

## Common Issues and Solutions

### Dashboard Navigation Issue
**Problem**: Users are directed to the wrong dashboard after login.

**Root Causes:**
1. **Role field parsing error**: The `role` field in the database doesn't match expected values
2. **Missing profile document**: User profile wasn't created during signup
3. **Permission issues**: User can't read their own profile

**Solutions Implemented:**
1. **Enhanced role parsing**: Added fallback logic for role detection
2. **Profile creation fallback**: Automatically creates profile if missing
3. **Better error handling**: Provides detailed logging for debugging
4. **Role validation**: Ensures valid role before navigation

### Testing the Fix
1. **Check console logs** for role parsing information
2. **Verify database permissions** are set correctly
3. **Test with both client and driver accounts**
4. **Check profile document structure** in Appwrite console

### Debug Information
The app now provides extensive logging:
- 🔍 Profile loading details
- 🔐 Login process tracking
- ⚠️ Role parsing warnings
- 🔄 Fallback role detection
- ✅ Success confirmations

## Security Considerations

1. **User Isolation**: Each user can only access their own data
2. **Role Validation**: Server-side role validation is recommended
3. **Profile Protection**: Profile documents are protected by user ID
4. **Session Management**: Proper session cleanup on logout

## Next Steps

1. **Test the current implementation** with existing users
2. **Monitor console logs** for any remaining issues
3. **Verify database permissions** are correctly set
4. **Consider adding server-side validation** for additional security
