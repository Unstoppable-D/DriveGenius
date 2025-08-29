# Test Active Jobs Fix - Quick Verification

## What Was Fixed
✅ **Code Fix Applied**: Added safe fallback ordering in `listDriverActiveJobs()` method
- Tries `acceptedAt` first (preferred)
- Falls back to `updatedAt` if 400 error  
- Falls back to `createdAt` as final fallback

## Quick Test Steps

### 1. Test Active Jobs Screen (Immediate)
1. **Open Driver Dashboard**
2. **Tap "Active Jobs"** quick action card
3. **Expected Result**: Screen loads without 400 error
4. **Current Result**: May show "No active jobs" (which is fine)

### 2. Test Accept Flow (After Schema Update)
1. **Go to Job Requests**
2. **Tap a pending request**
3. **Tap "Accept with ETA"**
4. **Pick date/time** (defaults to scheduledAt)
5. **Expected Result**: 
   - Request disappears from Job Requests
   - Appears in Active Jobs
   - No errors in console

### 3. Verify Schema Update Worked
1. **Check Appwrite Console** → Databases → `drive_genius_db` → `job_requests`
2. **Verify Attributes exist**:
   - `acceptedAt` (String, optional)
   - `rejectedAt` (String, optional) 
   - `estimatedPickupAt` (String, optional)

## Expected Behavior

### Before Schema Update:
- ❌ Active Jobs: 400 error
- ❌ Accept/Reject: May fail when setting timestamps
- ❌ Client notifications: May not include ETA

### After Schema Update:
- ✅ Active Jobs: Loads successfully
- ✅ Accept/Reject: Works with ETA
- ✅ Client notifications: Include ETA information
- ✅ Real-time updates: Work properly

## If Still Getting Errors

### Check Console Logs:
```dart
// The fallback code should show these attempts:
1. Trying acceptedAt ordering...
2. Falling back to updatedAt ordering...
3. Falling back to createdAt ordering...
```

### Verify Collection Has Required Fields:
- `updatedAt` (should exist)
- `createdAt` (should exist)
- `status` (should exist)
- `driverId` (should exist)

### Check Appwrite Console:
- Go to **job_requests** collection
- Check **Settings** → **Attributes**
- Ensure all required fields are present

## Quick Schema Check

Run this in Appwrite Console to verify attributes:

```javascript
// In Appwrite Console → Databases → job_requests → Documents
// Create a test document with these fields:
{
  "clientId": "test",
  "driverId": "test", 
  "pickup": "Test",
  "destination": "Test",
  "scheduledAt": "2024-01-01T00:00:00.000Z",
  "status": "ACCEPTED",
  "acceptedAt": "2024-01-01T00:00:00.000Z",
  "estimatedPickupAt": "2024-01-01T01:00:00.000Z"
}
```

If this creates successfully, your schema is correct.

## Success Indicators

✅ **Active Jobs loads without errors**
✅ **Accept flow works end-to-end**
✅ **ETA picker shows scheduledAt as default**
✅ **Accepted requests appear in Active Jobs**
✅ **Client receives notification with ETA**
✅ **Real-time updates work**

## Next Steps After Fix

1. **Test complete workflow** with real data
2. **Add recommended indexes** for performance
3. **Monitor function logs** for notifications
4. **Verify client side** receives updates
5. **Test edge cases** (reject, cancel, etc.)

The fix should resolve the 400 error immediately, allowing Active Jobs to work with fallback ordering until you add the schema attributes.
