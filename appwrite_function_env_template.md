# Appwrite Function Environment Variables

## Required Environment Variables

Set these in your Appwrite Function's environment variables:

```bash
# Appwrite Configuration
APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1
APPWRITE_FUNCTION_PROJECT_ID=68a53f930037f28d12a8

# Database and Collection IDs
APPWRITE_DATABASE_ID=drive_genius_db
APPWRITE_JOB_REQUESTS_ID=job_requests

# API Key (Server Key with full access)
APPWRITE_API_KEY=your_server_api_key_here
```

## How to Get These Values

### 1. APPWRITE_ENDPOINT
- Use your project's endpoint: `https://fra.cloud.appwrite.io/v1`

### 2. APPWRITE_FUNCTION_PROJECT_ID
- Your project ID: `68a53f930037f28d12a8`

### 3. APPWRITE_DATABASE_ID
- Database ID: `drive_genius_db`

### 4. APPWRITE_JOB_REQUESTS_ID
- Collection ID: `job_requests`

### 5. APPWRITE_API_KEY
- Go to **Settings** → **API Keys**
- Create a new API Key with **Full Access** permissions
- Copy the generated key

## Security Note
- The API Key has full access to your project
- Keep it secure and don't expose it in client-side code
- This key is only used server-side in the Appwrite Function
