# Appwrite Collection Schema Fix Guide

## Problem
You're getting the error: `"AppwriteException: document_invalid_structure, Invalid document structure: Missing required attribute 'profileImage'"`

This happens because your `profiles` collection in Appwrite still has `profileImage` as a **required attribute**, even though you think you've removed it.

## Solution: Update Collection Schema in Appwrite Console

### Step 1: Check Current Collection Schema

1. Go to your **Appwrite Console**
2. Navigate to **Databases** → **drive_genius_db** → **profiles** collection
3. Click on **Attributes** tab
4. Look for any attributes marked as **Required** (red asterisk)

### Step 2: Remove Unwanted Required Attributes

**Remove these attributes if they exist and are marked as required:**
- ❌ `profileImage` (String, required) - **REMOVE THIS**
- ❌ Any other attributes not in your target schema

**Keep only these required attributes:**
- ✅ `name` (String, required)
- ✅ `email` (String, required) 
- ✅ `phone` (String, required)
- ✅ `role` (String, required)
- ✅ `isVerified` (Boolean, required)
- ✅ `createdAt` (String, required)
- ✅ `updatedAt` (String, required)

### Step 3: Update Attribute Settings

For each attribute:

1. **Click on the attribute** to edit it
2. **Uncheck "Required"** if it's not in your target schema
3. **Set the correct type** (String, Boolean, etc.)
4. **Set the correct size** (for String attributes)
5. **Click "Update"** to save changes

### Step 4: Verify Collection Permissions

While you're in the collection settings:

1. Go to **Settings** tab
2. **Change Permissions** from "Collection-level" to "Document-level"
3. **Set Collection Permissions:**
   - Create: `users`
   - Read: `users`
   - Update: `users`
   - Delete: `users`

## Expected Schema After Fix

Your `profiles` collection should have **exactly** these attributes:

| Attribute | Type | Required | Size | Description |
|-----------|------|----------|------|-------------|
| `name` | String | ✅ Yes | 255 | User's full name |
| `email` | String | ✅ Yes | 255 | User's email address |
| `phone` | String | ✅ Yes | 20 | User's phone number |
| `role` | String | ✅ Yes | 20 | User role (client/driver) |
| `isVerified` | Boolean | ✅ Yes | - | Email verification status |
| `createdAt` | String | ✅ Yes | 255 | ISO 8601 timestamp |
| `updatedAt` | String | ✅ Yes | 255 | ISO 8601 timestamp |

## Common Issues and Solutions

### Issue 1: Can't Remove Required Attribute
- **Solution**: First, make sure no documents in the collection use that attribute
- **Alternative**: Mark it as optional (uncheck "Required") instead of deleting

### Issue 2: Attribute Type Mismatch
- **Solution**: Ensure the type matches exactly (String vs Text, Boolean vs Bool)
- **Note**: Appwrite is strict about data types

### Issue 3: Collection Still Shows Old Schema
- **Solution**: Refresh the console, clear browser cache, or wait a few minutes
- **Note**: Schema changes can take a moment to propagate

## Testing the Fix

After updating the schema:

1. **Try creating a new user account** in your Flutter app
2. **Check console logs** for successful profile creation
3. **Verify the profile document** appears in Appwrite console
4. **Check that only the expected attributes** are present

## Expected Console Output

**✅ Success:**
```
🔐 Signup Debug: Schema validation - only sending required attributes
✅ User profile created successfully with document-level permissions: [userId]
```

**❌ Still failing:**
```
⚠️ Schema validation error detected:
   This usually means your Appwrite collection has different required attributes
   Expected schema: name, email, phone, role, isVerified, createdAt, updatedAt
   Check your Appwrite collection attributes and make sure they match exactly
```

## Important Notes

- **Don't delete the collection** - just update the attributes
- **Backup your data** before making schema changes
- **Test with a new user account** first
- **The Flutter code is already fixed** to match this schema
- **profileImage is stored locally** but not sent to Appwrite

## Next Steps

1. **Update your Appwrite collection schema** (remove profileImage requirement)
2. **Test signup with a new user account**
3. **Verify the profile is created successfully**
4. **Check that permissions are working correctly**

If you still have issues after fixing the schema, the problem might be with permissions. See `APPWRITE_PERMISSIONS_FIX.md` for permission-related solutions.
