# Active Jobs & Notifications Setup Guide

## Overview
This guide covers the complete setup for the enhanced driver Accept/Reject functionality with Active Jobs screen and client notifications system.

## Database Schema Updates

### 1. Job Requests Collection (Already Updated)
Ensure your `job_requests` collection has these attributes:
- `estimatedPickupAt` (String, optional)
- `acceptedAt` (String, optional)
- `rejectedAt` (String, optional)

### 2. New Notifications Collection
Create a new collection called `notifications` in your `drive_genius_db` database:

#### Attributes:
- **`userId`** (String, required) - recipient (client)
- **`jobRequestId`** (String, required) - reference to job request
- **`type`** (String, required) - "JOB_ACCEPTED" | "JOB_REJECTED"
- **`title`** (String, required) - short title
- **`body`** (String, optional) - message content
- **`status`** (String, required) - "UNREAD" | "READ"
- **`createdAt`** (String, required) - ISO datetime
- **`readAt`** (String, optional) - ISO datetime when read

#### Indexes:
- **`user_status`**: userId (ASC), status (ASC)
- **`user_created`**: userId (ASC), createdAt (DESC)

#### Permissions:
- **Create**: `users` (allows authenticated users to create notifications)
- **Read**: `users` (allows authenticated users to read notifications)
- **Update**: `users` (allows authenticated users to update notifications)
- **Delete**: `users` (allows authenticated users to delete notifications)

## Appwrite Function Setup

### 1. Create Function
1. Go to your Appwrite Console
2. Navigate to **Functions**
3. Click **Create Function**
4. **Name**: `job-requests-notify`
5. **Runtime**: Node.js 20
6. **Entrypoint**: `index.mjs`

### 2. Upload Function Code
Upload the files from `functions/job-requests-notify/`:
- `package.json`
- `index.mjs`

### 3. Configure Environment Variables
Set these environment variables in your function:
- **`APPWRITE_API_KEY`**: Server key with Databases read/write permissions
- **`APPWRITE_ENDPOINT`**: `https://<region>.cloud.appwrite.io/v1`
- **`APPWRITE_DATABASE_ID`**: `drive_genius_db`
- **`APPWRITE_JOB_REQUESTS_ID`**: `job_requests`
- **`APPWRITE_NOTIFICATIONS_ID`**: `notifications`

### 4. Set Function Trigger
- **Event**: `databases.*.collections.job_requests.documents.update`
- **Schedule**: Not applicable (event-driven)

### 5. Deploy Function
Click **Deploy** to activate the function.

## Flutter Implementation Status

### ✅ Completed Features

#### **Driver Side**
1. **Job Requests Screen**:
   - View pending requests
   - Accept with ETA picker (defaults to scheduledAt)
   - Reject with confirmation
   - Real-time list updates

2. **Active Jobs Screen**:
   - View accepted requests
   - Show ETA pickup time
   - Real-time updates when status changes

3. **Dashboard Integration**:
   - "Active Jobs" quick action card
   - Badge count for pending requests

#### **Client Side**
1. **Notifications Screen**:
   - View all notifications with status badges
   - Tap to mark as read
   - Real-time updates for new notifications
   - Visual distinction for unread items

2. **My Trips Screen**:
   - View all trip requests with status
   - Show ETA when accepted
   - Real-time status updates

3. **Dashboard Integration**:
   - "Notifications" quick action card
   - "My Trips" quick action card

### 🔧 Key Features

#### **Real-time Updates**
- Both driver and client sides subscribe to relevant changes
- Immediate UI updates without manual refresh
- Proper subscription cleanup on screen dispose

#### **Enhanced UX**
- ETA picker defaults to scheduled date/time
- Visual status badges with color coding
- Unread notification highlighting
- Loading states and error handling

#### **Security**
- Document-level permissions for notifications
- Client-only access to their notifications
- Driver-only access to their job requests

## Testing Checklist

### Driver Workflow
- [ ] **Job Requests**: View pending requests
- [ ] **Accept**: Pick ETA (defaults to scheduledAt) → request moves to Active Jobs
- [ ] **Reject**: Confirm rejection → request disappears from pending
- [ ] **Active Jobs**: View accepted requests with ETA
- [ ] **Real-time**: Status changes update immediately

### Client Workflow
- [ ] **Notifications**: View "Trip accepted" with ETA or "Trip rejected"
- [ ] **Mark Read**: Tap notification to mark as read
- [ ] **My Trips**: View updated status and ETA
- [ ] **Real-time**: New notifications appear immediately

### Function Testing
- [ ] **Accept**: Function creates "JOB_ACCEPTED" notification
- [ ] **Reject**: Function creates "JOB_REJECTED" notification
- [ ] **Permissions**: Notifications are private to client
- [ ] **Idempotent**: Multiple updates don't create duplicates

## Usage Examples

### Driver Accepting a Request
```dart
// ETA picker defaults to scheduledAt
final eta = await _pickEta(context); // Uses scheduledAt as initial

await appwriteService.updateJobRequestStatus(
  requestId: request.id,
  status: 'ACCEPTED',
  estimatedPickupAt: eta,
);
// Function automatically creates notification for client
```

### Client Viewing Notifications
```dart
final notifications = await appwriteService.listClientNotifications(userId);
// Returns notifications with type, title, body, status

// Mark as read
await appwriteService.markNotificationRead(notificationId);
```

### Real-time Subscriptions
```dart
// Driver: Subscribe to job request changes
_sub = svc.subscribeJobRequestsChanges(
  driverId: driverId,
  onChange: _loadPending,
);

// Client: Subscribe to notifications
_sub = svc.subscribeClientNotifications(
  userId: userId,
  onChange: _loadNotifications,
);
```

## Error Handling

### Common Issues
1. **Missing Function**: Notifications won't be created
2. **Permission Errors**: Check function API key permissions
3. **Collection Missing**: Ensure notifications collection exists
4. **Real-time Issues**: Verify subscription cleanup

### Graceful Fallbacks
- Missing notifications show "No notifications" message
- Failed status updates show error SnackBar
- Network errors don't crash the app
- Invalid dates fallback to "Unknown" display

## Performance Considerations

### Database Indexes
- `userId + status` for notification queries
- `userId + createdAt` for chronological ordering
- `driverId + status` for job request queries

### Real-time Optimization
- Subscribe only to relevant document changes
- Unsubscribe on screen dispose
- Limit query results to 100 items

## Security Notes

### Data Access
- Drivers can only see their assigned requests
- Clients can only see their own notifications
- Function uses server API key for secure operations
- Document-level permissions prevent cross-user access

### Validation
- ETA must be in the future
- Status transitions are controlled
- Timestamps are server-generated
- Function validates all input data

## Next Steps

1. **Deploy Function**: Upload and configure the notification function
2. **Create Collections**: Set up notifications collection with proper schema
3. **Test Workflow**: Verify Accept/Reject → Active Jobs → Notifications flow
4. **Monitor Logs**: Check function execution logs for any issues
5. **User Testing**: Test with real driver and client accounts

## Support

If you encounter issues:
1. Check Appwrite Console function logs
2. Verify collection schema matches exactly
3. Test function with simple data first
4. Ensure all environment variables are set
5. Check database permissions are correct

## File Structure

```
lib/
├── constants/
│   ├── app_constants.dart (updated routes)
│   └── appwrite_constants.dart (updated collection IDs)
├── services/
│   └── appwrite_service.dart (new methods)
├── screens/
│   ├── active_jobs_screen.dart (new)
│   ├── notifications_screen.dart (new)
│   ├── job_requests_screen.dart (updated ETA picker)
│   ├── client/
│   │   └── client_dashboard_screen.dart (updated)
│   └── driver/
│       └── driver_dashboard_screen.dart (updated)
└── main.dart (updated routes)

functions/
└── job-requests-notify/
    ├── package.json
    └── index.mjs
```

The implementation is complete and ready for testing. All components work together to provide a seamless driver-client communication system with real-time updates and proper security.
