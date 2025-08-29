# Appwrite Functions Setup Guide

This directory contains the Appwrite Functions needed for the DriveGenius job request system to work end-to-end.

## Functions Overview

### 1. `job-requests-acl` - Access Control List
**Purpose**: Sets proper permissions when job requests are created
**Trigger**: `databases.*.collections.job_requests.documents.create`
**What it does**: Grants read/update permissions to both client and driver

### 2. `job-requests-notify` - Client Notifications
**Purpose**: Creates notifications when drivers accept/reject requests
**Trigger**: `databases.*.collections.job_requests.documents.update`
**What it does**: Sends real-time updates to clients with ETA for accepted trips

## Deployment Steps

### Prerequisites
- Appwrite Console access
- Server API key with database read/write permissions
- Node.js 20 runtime available

### Step 1: Deploy ACL Function
1. In Appwrite Console → Functions → Create Function
2. **Name**: `job-requests-acl`
3. **Runtime**: Node.js 20
4. **Events**: `databases.*.collections.job_requests.documents.create`
5. **Code**: Copy from `functions/job-requests-acl/index.mjs`
6. **Environment Variables**:
   ```
   APPWRITE_ENDPOINT=https://<your-region>.cloud.appwrite.io/v1
   APPWRITE_API_KEY=<server-key-with-db-permissions>
   APPWRITE_DATABASE_ID=drive_genius_db
   APPWRITE_JOB_REQUESTS_ID=job_requests
   ```
7. **Deploy** and **Activate**

### Step 2: Deploy Notifications Function
1. In Appwrite Console → Functions → Create Function
2. **Name**: `job-requests-notify`
3. **Runtime**: Node.js 20
4. **Events**: `databases.*.collections.job_requests.documents.update`
5. **Code**: Copy from `functions/job-requests-notify/index.mjs`
6. **Environment Variables**:
   ```
   APPWRITE_ENDPOINT=https://<your-region>.cloud.appwrite.io/v1
   APPWRITE_API_KEY=<server-key-with-db-permissions>
   APPWRITE_DATABASE_ID=drive_genius_db
   APPWRITE_JOB_REQUESTS_ID=job_requests
   APPWRITE_NOTIFICATIONS_ID=<EXACT-notifications-collection-id>
   ```
7. **Deploy** and **Activate**

## Database Schema Requirements

### `job_requests` Collection
Required attributes (all String type):
- `clientId` (required)
- `driverId` (required)
- `pickup` (required)
- `destination` (required)
- `scheduledAt` (required)
- `note` (optional)
- `status` (required) - "PENDING" | "ACCEPTED" | "REJECTED" | "CANCELLED"
- `createdAt` (required)
- `updatedAt` (required)
- `estimatedPickupAt` (optional) - added when driver accepts
- `acceptedAt` (optional) - added when driver accepts
- `rejectedAt` (optional) - added when driver rejects

### `notifications` Collection
Required attributes:
- `userId` (String, required) - client who receives the notification
- `jobRequestId` (String, required) - reference to the job request
- `type` (String, required) - "JOB_ACCEPTED" | "JOB_REJECTED"
- `title` (String, required) - "Trip accepted" | "Trip rejected"
- `body` (String, optional) - ETA details for accepted trips
- `status` (String, required) - "UNREAD" | "READ"
- `createdAt` (String, required) - ISO timestamp
- `readAt` (String, optional) - ISO timestamp when marked read

## Testing the System

### 1. Create Job Request
- Client creates booking → Function triggers → Sets permissions
- Check Console: job_requests document should have read/update for both client and driver

### 2. Driver Accept/Reject
- Driver accepts with ETA → Status changes to ACCEPTED
- Function triggers → Creates notification for client
- Check Console: notifications collection should have new document

### 3. Client Notifications
- Client dashboard badge should increment
- Notifications screen should show new item
- Tap to mark as read → Badge decrements

## Troubleshooting

### Common Issues

**404 Collection Not Found**
- Verify collection IDs in environment variables
- Check that collections exist in the correct database

**401 Permission Denied**
- Ensure server API key has database read/write permissions
- Check that ACL Function is deployed and active

**Function Not Triggering**
- Verify event triggers are set correctly
- Check Function logs for errors
- Ensure Function is activated

**Notifications Not Appearing**
- Check Function logs for "OK" response
- Verify notifications collection schema
- Check client dashboard realtime subscription

### Debug Steps
1. Check Function logs in Console
2. Verify environment variables
3. Test Function manually with sample data
4. Check database permissions on documents
5. Verify realtime subscriptions are working

## Security Notes

- The temporary client-side permissions (`Permission.update(Role.users())`) allow any authenticated user to update job requests
- This is a temporary measure until the ACL Function is deployed
- Once deployed, the ACL Function will restrict permissions to only client + driver
- Consider removing the temporary permissions after ACL Function is working

## Performance Considerations

- Functions are lightweight and should respond quickly
- Realtime subscriptions update UI within ~1 second
- Badge counts are cached and only recalculated on changes
- Optimistic UI updates provide immediate feedback
