# Appwrite Schema Update Guide - Fix Active Jobs 400 Error

## Problem
The Active Jobs screen is getting a 400 error because the `job_requests` collection is missing required attributes for the ETA flow.

## Immediate Fix Applied
✅ **Code Fix**: Added safe fallback ordering in `listDriverActiveJobs()` method
- Tries `acceptedAt` first (preferred)
- Falls back to `updatedAt` if 400 error
- Falls back to `createdAt` as final fallback

## Required Schema Updates

### 1. Add Missing Attributes to job_requests Collection

**Location**: Appwrite Console → Databases → `drive_genius_db` → Collections → `job_requests` → Settings → Attributes

#### Add These Attributes:

| Attribute Name | Type | Required | Size | Default | Description |
|----------------|------|----------|------|---------|-------------|
| `acceptedAt` | String | No | 255 | None | ISO datetime when driver accepted |
| `rejectedAt` | String | No | 255 | None | ISO datetime when driver rejected |
| `estimatedPickupAt` | String | No | 255 | None | ISO datetime for pickup ETA |

#### Step-by-Step:
1. Go to **Appwrite Console**
2. Navigate to **Databases** → **drive_genius_db** → **job_requests**
3. Click **Settings** tab
4. Under **Attributes**, click **Add Attribute** for each field:

**For `acceptedAt`:**
- **Type**: String
- **Required**: No
- **Array**: No
- **Size**: 255
- **Default**: None

**For `rejectedAt`:**
- **Type**: String
- **Required**: No
- **Array**: No
- **Size**: 255
- **Default**: None

**For `estimatedPickupAt`:**
- **Type**: String
- **Required**: No
- **Array**: No
- **Size**: 255
- **Default**: None

5. **Save** each attribute

### 2. Recommended Indexes (Optional but Recommended)

**Location**: Appwrite Console → Databases → `drive_genius_db` → Collections → `job_requests` → Settings → Indexes

#### Add These Indexes:

| Index Name | Attributes | Type | Orders |
|-------------|------------|------|---------|
| `driver_status` | `driverId`, `status` | Key | `driverId` (ASC), `status` (ASC) |
| `client_status` | `clientId`, `status` | Key | `clientId` (ASC), `status` (ASC) |
| `created_at` | `createdAt` | Key | `createdAt` (DESC) |
| `updated_at` | `updatedAt` | Key | `updatedAt` (DESC) |
| `accepted_at` | `acceptedAt` | Key | `acceptedAt` (DESC) |
| `eta_pickup` | `estimatedPickupAt` | Key | `estimatedPickupAt` (ASC) |

#### Step-by-Step:
1. Click **Add Index**
2. **Name**: Enter index name (e.g., `driver_status`)
3. **Attributes**: Select the attributes
4. **Type**: Key
5. **Orders**: Set the sort order
6. **Create**

## 3. Backfill Existing Data (Optional)

If you already have accepted job requests without the new attributes, you can backfill them:

### Option A: Appwrite Console (Manual)
1. Go to **job_requests** collection
2. Find documents with `status: "ACCEPTED"`
3. Edit each document and add:
   - `acceptedAt`: Set to `updatedAt` or `createdAt` value
   - `estimatedPickupAt`: Set to a reasonable default or leave empty

### Option B: Appwrite Function (Automated)
Create a one-time function to backfill:

```javascript
// backfill-accepted-jobs.js
export default async ({ req, res, log, error }) => {
  try {
    const client = new Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
      .setKey(process.env.APPWRITE_API_KEY);

    const databases = new Databases(client);
    
    // Get all accepted jobs without acceptedAt
    const docs = await databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_JOB_REQUESTS_ID,
      [
        Query.equal('status', ['ACCEPTED']),
        Query.isNull('acceptedAt')
      ]
    );

    // Update each document
    for (const doc of docs.documents) {
      await databases.updateDocument(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_JOB_REQUESTS_ID,
        doc.$id,
        {
          acceptedAt: doc.updatedAt || doc.createdAt
        }
      );
    }

    return res.json({ updated: docs.documents.length });
  } catch (e) {
    error(`Backfill failed: ${e.message}`);
    return res.json({ error: e.message }, 500);
  }
};
```

## 4. Test the Fix

### Before Schema Update:
- Active Jobs screen shows 400 error
- Accept/Reject flow may fail when setting timestamps

### After Schema Update:
- Active Jobs screen loads successfully
- Accept/Reject flow works with ETA
- Client notifications include ETA information
- Real-time updates work properly

## 5. Verification Steps

1. **Check Active Jobs**: Navigate to driver dashboard → Active Jobs
   - Should load without errors
   - Should show accepted requests

2. **Test Accept Flow**: 
   - Go to Job Requests
   - Accept a pending request with ETA
   - Verify it appears in Active Jobs
   - Check that `acceptedAt` and `estimatedPickupAt` are set

3. **Test Client Side**:
   - Client should receive notification with ETA
   - My Trips should show updated status and ETA

## 6. Performance Considerations

### With Indexes:
- Queries are fast and efficient
- Real-time updates are responsive
- Large datasets perform well

### Without Indexes:
- Queries still work but may be slower
- Real-time updates may have slight delays
- Large datasets may experience performance issues

## 7. Troubleshooting

### Common Issues:

**"Attribute not found" errors:**
- Verify all three attributes were added correctly
- Check attribute names match exactly (case-sensitive)
- Ensure attributes are saved in the collection

**Still getting 400 errors:**
- Check if the fallback code is working
- Verify the collection has `updatedAt` and `createdAt` attributes
- Check Appwrite Console logs for specific error details

**Accept/Reject not working:**
- Verify the `updateJobRequestStatus` method has proper error handling
- Check if the function has proper permissions
- Ensure the job_requests collection allows updates

## 8. Next Steps

1. **Immediate**: Add the three missing attributes to job_requests collection
2. **Optional**: Add recommended indexes for better performance
3. **Optional**: Backfill existing accepted jobs if needed
4. **Test**: Verify Active Jobs loads and Accept/Reject flow works
5. **Monitor**: Check function logs and database performance

## 9. Schema Summary

### Current Required Attributes:
- `id` (auto-generated)
- `clientId` (String, required)
- `driverId` (String, required)
- `pickup` (String, required)
- `destination` (String, required)
- `scheduledAt` (String, required)
- `note` (String, optional)
- `status` (String, required)
- `createdAt` (String, required)
- `updatedAt` (String, required)

### New Attributes Added:
- `acceptedAt` (String, optional)
- `rejectedAt` (String, optional)
- `estimatedPickupAt` (String, optional)

### Status Values Supported:
- `PENDING` (initial state)
- `ACCEPTED` (driver accepted with ETA)
- `REJECTED` (driver rejected)
- `CANCELLED` (client cancelled)

After completing these schema updates, the Active Jobs screen will work properly and the complete Accept/Reject flow with ETA will be fully functional.
