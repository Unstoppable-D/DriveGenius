# Appwrite Permissions Fix Guide

## Problem
You're getting the error: `"AppwriteException: user_unauthorized, Permissions must be one of: (any, guests)"`

This happens because your `profiles` collection is currently using **collection-level permissions**, which means Appwrite ignores the document-level permissions you're trying to set in your Flutter code.

## Solution: Enable Document-Level Permissions

### Step 1: Update Collection Permissions in Appwrite Console

1. Go to your Appwrite Console
2. Navigate to **Databases** → **drive_genius_db** → **profiles** collection
3. Click on **Settings** tab
4. Under **Permissions**, change from **Collection-level** to **Document-level**
5. Save the changes

### Step 2: Set Collection-Level Permissions

With document-level permissions enabled, you need to set the collection permissions to allow authenticated users to create documents:

**Collection Permissions:**
- **Create**: `users` (allows authenticated users to create documents)
- **Read**: `users` (allows authenticated users to read documents)
- **Update**: `users` (allows authenticated users to update documents)
- **Delete**: `users` (allows authenticated users to delete documents)

### Step 3: Document-Level Permissions (Handled by Flutter Code)

Your Flutter code will now properly set document-level permissions:
- **Read**: `Role.user(userId)` - only the owner can read
- **Update**: `Role.user(userId)` - only the owner can update  
- **Delete**: `Role.user(userId)` - only the owner can delete

## Alternative: Collection-Level Permissions (Less Secure)

If you cannot enable document-level permissions, you can use collection-level permissions but this is less secure:

**Collection Permissions:**
- **Create**: `users` (allows any authenticated user to create profiles)
- **Read**: `users` (allows any authenticated user to read any profile)
- **Update**: `users` (allows any authenticated user to update any profile)
- **Delete**: `users` (allows any authenticated user to delete any profile)

**Security Trade-offs:**
- ✅ Simpler to manage
- ❌ Any authenticated user can read/update/delete any profile
- ❌ No data isolation between users
- ❌ Potential security vulnerabilities

## Recommended Approach
Use **document-level permissions** for better security and data isolation. This ensures each user can only access their own profile data.

## Testing
After making these changes:
1. Try creating a new user account
2. Verify the profile document is created successfully
3. Verify the user can only access their own profile
4. Verify other users cannot access the profile
