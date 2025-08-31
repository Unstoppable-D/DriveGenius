# DriveGenius Appwrite Functions

This directory contains Node.js functions for the DriveGenius application, configured for Git-based deployments to Appwrite.

## Function Structure

Each function is self-contained in its own directory with:
- `package.json` - Dependencies and metadata
- `index.mjs` - Main function code (ESM format)

### Functions

1. **job-requests-acl** - Sets permissions on job request documents
2. **job-requests-notify** - Creates notifications when job status changes
3. **chat-acl** - Sets permissions on conversation and message documents

## Appwrite Console Configuration

### For Each Function:

#### Basic Settings
- **Runtime**: Node.js 22
- **Entrypoint**: `index.mjs`
- **Root directory**: `functions/[function-name]` (e.g., `functions/job-requests-acl`)

#### Build Settings
- **Command**: `npm ci`

#### Environment Variables
All functions require these base variables:
```
APPWRITE_ENDPOINT = https://fra.cloud.appwrite.io/v1
APPWRITE_API_KEY = [YOUR_SERVER_API_KEY]
APPWRITE_DATABASE_ID = drive_genius_db
```

**job-requests-acl**:
```
APPWRITE_JOB_REQUESTS_ID = job_requests
```

**job-requests-notify**:
```
APPWRITE_JOB_REQUESTS_ID = job_requests
APPWRITE_NOTIFICATIONS_ID = notifications
```

**chat-acl**:
```
APPWRITE_CONVERSATIONS_ID = conversations
APPWRITE_MESSAGES_ID = messages
```

#### Triggers (Events)
- **job-requests-acl**: `databases.*.collections.job_requests.documents.create`
- **job-requests-notify**: `databases.*.collections.job_requests.documents.update`
- **chat-acl**: 
  - `databases.*.collections.conversations.documents.create`
  - `databases.*.collections.messages.documents.create`

## Deployment

1. **Connect to Git**: Link your repository in Appwrite Console
2. **Configure Functions**: Set up each function with the settings above
3. **Push to Main**: Deployments trigger automatically on push to main branch

## Troubleshooting

### Common Issues

**"bash: dart: command not found"**
- Wrong runtime selected. Use Node.js 22, not Dart/Flutter
- Root directory should point to function folder, not repo root

**"index.mjs not found"**
- Entrypoint mismatch or wrong root directory
- Ensure entrypoint is relative to configured root directory

**"Cannot find module node-appwrite"**
- Missing npm install. Add build command `npm ci`
- Verify package.json includes "node-appwrite" dependency

**"Missing env"**
- Set all required environment variables per function
- Redeploy after adding variables

**"Git root includes Flutter only"**
- Point root directory to `functions/[function-name]`
- Don't use repo root as it includes Flutter files

### Build Failures
- Check root directory points to function folder
- Ensure runtime is Node.js 22
- Verify package.json exists in root directory
- Confirm index.mjs matches entrypoint

## Function Details

### job-requests-acl
Sets read/update/delete permissions for both client and driver on job request documents.

### job-requests-notify
Creates notification documents when job status changes to ACCEPTED or REJECTED.

### chat-acl
Sets permissions on conversation and message documents for the two participants.

## Development

To test locally:
1. Install dependencies: `npm ci`
2. Use Appwrite CLI for local testing
3. Deploy to staging environment first

## Git Integration

- Functions are deployed automatically on push to main branch
- Each function has its own deployment pipeline
- Build logs available in Appwrite Console
- Rollback to previous versions if needed
