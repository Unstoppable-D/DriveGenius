# Job Request Status Update Guide

## Overview
This guide covers the database schema updates needed to support driver Accept/Reject functionality with ETA tracking and real-time status updates.

## Database Schema Updates

### Collection: `job_requests` (in database `drive_genius_db`)

#### New Attributes to Add
Add these optional string attributes to your existing job_requests collection:

1. **`estimatedPickupAt`** (String, optional)
   - ISO 8601 datetime string
   - Set when driver accepts a request
   - Example: `"2024-01-15T14:30:00.000Z"`

2. **`acceptedAt`** (String, optional)
   - ISO 8601 datetime string
   - Set when driver accepts a request
   - Example: `"2024-01-15T10:15:00.000Z"`

3. **`rejectedAt`** (String, optional)
   - ISO 8601 datetime string
   - Set when driver rejects a request
   - Example: `"2024-01-15T10:15:00.000Z"`

#### Existing Attributes (Keep As-Is)
- `status`: "PENDING" | "ACCEPTED" | "REJECTED" | "CANCELLED"
- `pickup`: String
- `destination`: String
- `scheduledAt`: String (ISO datetime)
- `note`: String (optional)
- `clientId`: String
- `driverId`: String
- `createdAt`: String (ISO datetime)
- `updatedAt`: String (ISO datetime)

## Appwrite Console Setup

### Step 1: Update Collection Schema
1. Go to your Appwrite Console
2. Navigate to **Databases** → **drive_genius_db** → **job_requests** collection
3. Click on **Settings** tab
4. Under **Attributes**, click **Add Attribute** for each new field:

#### estimatedPickupAt
- **Type**: String
- **Required**: No
- **Array**: No
- **Size**: 255
- **Default**: None

#### acceptedAt
- **Type**: String
- **Required**: No
- **Array**: No
- **Size**: 255
- **Default**: None

#### rejectedAt
- **Type**: String
- **Required**: No
- **Array**: No
- **Size**: 255
- **Default**: None

### Step 2: Update Indexes (Recommended)
Add these indexes for better query performance:

#### Index 1: Driver Status Query
- **Name**: `driver_status`
- **Attributes**: `driverId`, `status`
- **Type**: Key
- **Orders**: `driverId` (ASC), `status` (ASC)

#### Index 2: Client Status Query
- **Name**: `client_status`
- **Attributes**: `clientId`, `status`
- **Type**: Key
- **Orders**: `clientId` (ASC), `status` (ASC)

#### Index 3: Creation Time (if not exists)
- **Name**: `created_at`
- **Attributes**: `createdAt`
- **Type**: Key
- **Orders**: `createdAt` (DESC)

### Step 3: Verify Permissions
Ensure your collection has the correct permissions:

**Collection Permissions:**
- **Create**: `users` (allows authenticated users to create job requests)
- **Read**: `users` (allows authenticated users to read job requests)
- **Update**: `users` (allows authenticated users to update job requests)
- **Delete**: `users` (allows authenticated users to delete job requests)

**Document-Level Permissions** (if using ACL Function):
- Both client and driver must have Update permission on the document
- This ensures drivers can accept/reject requests
- This ensures clients can cancel requests

## Testing the Schema

### Test Data Creation
Create a test job request with the new fields:

```json
{
  "clientId": "test_client_id",
  "driverId": "test_driver_id",
  "pickup": "123 Main St, City",
  "destination": "456 Oak Ave, City",
  "scheduledAt": "2024-01-20T15:00:00.000Z",
  "note": "Test request",
  "status": "PENDING",
  "createdAt": "2024-01-15T10:00:00.000Z",
  "updatedAt": "2024-01-15T10:00:00.000Z"
}
```

### Test Status Updates
1. **Accept Request**: Update status to "ACCEPTED" with `estimatedPickupAt` and `acceptedAt`
2. **Reject Request**: Update status to "REJECTED" with `rejectedAt`
3. **Verify**: Check that all timestamps are properly set

## Flutter Implementation Status

### ✅ Completed
- **JobRequest Model**: Updated with new fields and parsing
- **AppwriteService**: Added status update methods and client listing
- **StatusBadge Widget**: Consistent status display component
- **JobRequestsScreen**: Driver Accept/Reject with ETA input
- **ClientTripRequestsScreen**: Client trip status viewing
- **Route Integration**: Added client trips route to navigation

### 🔧 Key Features
1. **Driver Side**:
   - View pending job requests
   - Accept with ETA picker (date + time)
   - Reject with confirmation
   - Real-time list updates

2. **Client Side**:
   - View all trip requests with status badges
   - See ETA pickup time when accepted
   - Real-time status updates

3. **Real-time Updates**:
   - Both sides subscribe to relevant changes
   - Immediate UI updates on status changes
   - No manual refresh needed

## Usage Examples

### Driver Accepting a Request
```dart
await appwriteService.updateJobRequestStatus(
  requestId: 'request_id',
  status: 'ACCEPTED',
  estimatedPickupAt: DateTime.now().add(Duration(hours: 1)),
);
```

### Driver Rejecting a Request
```dart
await appwriteService.updateJobRequestStatus(
  requestId: 'request_id',
  status: 'REJECTED',
);
```

### Client Viewing Trips
```dart
final trips = await appwriteService.listClientJobRequests(clientId);
// Returns all trips with status, ETA, and timestamps
```

## Error Handling

### Common Issues
1. **Missing Fields**: Ensure all new attributes are added to the collection
2. **Permission Errors**: Verify both client and driver have update permissions
3. **Date Parsing**: All datetime fields use ISO 8601 format
4. **Real-time**: Ensure realtime subscriptions are properly closed on dispose

### Graceful Fallbacks
- Missing ETA shows "ETA not set" message
- Failed status updates show error SnackBar
- Network errors don't crash the app
- Invalid dates fallback to "Unknown" display

## Performance Considerations

### Indexing Strategy
- Primary queries use `driverId + status` and `clientId + status`
- Creation time sorting for chronological display
- Limit queries to reasonable sizes (100 items max)

### Real-time Optimization
- Subscribe only to relevant document changes
- Unsubscribe on screen dispose
- Debounce rapid updates if needed

## Security Notes

### Data Access
- Drivers can only see requests assigned to them
- Clients can only see their own requests
- Status updates require proper authentication
- No cross-user data access possible

### Validation
- ETA must be in the future
- Status transitions are controlled (PENDING → ACCEPTED/REJECTED)
- Timestamps are server-generated for consistency

## Next Steps
1. **Update Appwrite Console** with new schema
2. **Test Status Updates** with sample data
3. **Verify Permissions** work correctly
4. **Test Real-time Updates** on both sides
5. **Deploy to Production** when ready

## Support
If you encounter issues:
1. Check Appwrite Console logs for permission errors
2. Verify collection schema matches exactly
3. Test with simple data first
4. Ensure all indexes are properly created
