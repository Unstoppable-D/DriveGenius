# Verifications Collection Permissions Setup

## Problem
The `verifications` collection needs to allow authenticated users to read each other's verification data so that:
- Clients can see driver addresses and documents when booking
- Drivers can see client verification status when viewing job requests

## Solution: Enable Read Access for Authenticated Users

### Step 1: Update Verifications Collection Permissions in Appwrite Console

1. Go to your Appwrite Console
2. Navigate to **Databases** → **drive_genius_db** → **verifications** collection
3. Click on **Settings** tab
4. Under **Permissions**, ensure you have:

**Collection Permissions:**
- **Create**: `users` (allows authenticated users to create verification documents)
- **Read**: `users` (allows authenticated users to read verification documents)
- **Update**: `users` (allows authenticated users to update their own verification documents)
- **Delete**: `users` (allows authenticated users to delete their own verification documents)

### Step 2: Document-Level Permissions (Recommended)

With document-level permissions enabled, your Flutter code should set:

**For each verification document:**
- **Read**: `Role.users()` - allows any authenticated user to read
- **Update**: `Role.user(userId)` - only the owner can update
- **Delete**: `Role.user(userId)` - only the owner can delete

### Step 3: Update Your upsertVerification Method

Ensure your `upsertVerification` method includes the read permission for all users:

```dart
// In your AppwriteService.upsertVerification method
final permissions = [
  Permission.read(Role.users()),        // Allow all authenticated users to read
  Permission.update(Role.user(userId)), // Only owner can update
  Permission.delete(Role.user(userId)), // Only owner can delete
];

await _databases.createDocument(
  databaseId: AppwriteIds.databaseId,
  collectionId: AppwriteIds.verificationsCollectionId,
  documentId: userId,
  data: verificationData,
  permissions: permissions,
);
```

### Step 4: Security Considerations

**What this enables:**
- ✅ Clients can see driver addresses and documents for booking decisions
- ✅ Drivers can see client verification status for job acceptance
- ✅ Profile previews work seamlessly

**What this means:**
- ⚠️ Any authenticated user can read verification data
- ⚠️ Address information is visible to other users
- ⚠️ Document URLs are accessible (but files themselves may be protected by storage permissions)

### Step 5: Alternative: Storage-Level Protection

If you want to restrict document access, you can:
1. Keep verification documents readable by all users
2. Set storage bucket permissions to `Role.users()` for profile images
3. Set storage bucket permissions to `Role.users()` for documents
4. Or use `Role.any` for public access to media files

### Testing
After making these changes:
1. Create a driver account with verification data
2. Create a client account
3. As a client, try to book a trip and view driver profile
4. Verify you can see the driver's address and document
5. Verify the "View document" button works for both images and PDFs

## Current Implementation Status
✅ PublicUser model updated with address fields
✅ AppwriteService.fetchPublicUserById updated to fetch address data
✅ PublicProfileSheet updated to display address and support tap-to-view avatar
✅ ImageViewer widget created for full-screen image viewing
✅ Booking and job request screens already properly integrated

## Next Steps
1. Update verifications collection permissions in Appwrite Console
2. Ensure your upsertVerification method includes `Permission.read(Role.users())`
3. Test the profile preview functionality
4. Verify address display and document viewing work correctly
