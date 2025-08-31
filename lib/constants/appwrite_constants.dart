class AppwriteConfig {
  // Appwrite Project Configuration
  static const String projectId = '68a53f930037f28d12a8';
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  
  // Database Collection IDs (you'll create these in Appwrite console)
  static const String usersCollection = 'users';
  static const String profilesCollection = 'profiles';
  static const String verificationsCollection = 'verifications';
  
  // Storage bucket ID (single bucket for free plan)
  static const String profileImagesBucket = 'profile-images';
  static const String documentsBucket = 'profile-images'; // Use same bucket for documents
  
  // Database ID (you'll create this in Appwrite console)
  static const String databaseId = 'drive_genius_db';
}

/// Centralized Appwrite resource IDs for better maintainability
class AppwriteIds {
  // Project and Database
  static const String projectId = AppwriteConfig.projectId;
  static const String databaseId = 'drive_genius_db'; // Exact ID from Console
  
  // Collections (exact IDs from Console)
  static const String profilesCollectionId = 'profiles'; // Exact collection ID
  static const String verificationsCollectionId = 'verifications'; // Exact collection ID
  static const String jobRequestsCollectionId = 'job_requests'; // Exact collection ID
  static const String notificationsCollectionId = 'notifications'; // NEW: Notifications collection
  static const String conversationsCollectionId = 'conversations'; // NEW: Conversations collection
  static const String messagesCollectionId = 'messages'; // NEW: Messages collection
  static const String messagesReadCollectionId = 'messages_read'; // NEW: Messages read tracking
  
  // Storage Buckets
  static const String profileBucketId = 'profile-images'; // Exact bucket ID from Console
  
  // Helper getters for backward compatibility
  static String get profileImagesBucket => profileBucketId;
  static String get documentsBucket => profileBucketId; // Use same bucket for now
}
