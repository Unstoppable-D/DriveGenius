import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../constants/appwrite_constants.dart';
import '../models/driver_profile.dart';
import '../models/job_request.dart';
import '../models/public_user.dart';
import '../utils/chat_utils.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  late final Storage _storage;
  late final Realtime _realtime;

  void initialize() {
    _client = Client()
      ..setEndpoint(AppwriteConfig.endpoint)
      ..setProject(AppwriteConfig.projectId);
    
    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
    _realtime = Realtime(_client);
  }

  // Session management
  Future<bool> hasSession() async {
    try {
      await _account.get();
      return true;
    } on AppwriteException catch (e) {
      if (e.code == 401) return false;
      rethrow;
    }
  }

  // Authentication Methods
  Future<User> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return user;
    } catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  Future<Session> createEmailSession({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _account.deleteSession(sessionId: sessionId);
    } catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  /// Deletes all active sessions for the current user
  /// This is useful for forcing a fresh login on app launch
  Future<void> deleteAllSessions() async {
    try {
      // Get current user to check if there's an active session
      try {
        final user = await _account.get();
        print('🔍 Found active user: ${user.$id}');
        
        // Get all sessions for the user
        final sessions = await _account.listSessions();
        print('🔍 Found ${sessions.sessions.length} active sessions');
        
        // Delete each session
        for (final session in sessions.sessions) {
          try {
            await _account.deleteSession(sessionId: session.$id);
            print('✅ Deleted session: ${session.$id}');
          } catch (e) {
            print('⚠️ Could not delete session ${session.$id}: $e');
          }
        }
        
        print('✅ All sessions deleted successfully');
      } catch (e) {
        // No active user, which is fine
        print('ℹ️ No active user found, no sessions to delete');
      }
    } catch (e) {
      print('⚠️ Error deleting sessions: $e');
      // Don't throw here as this is a cleanup operation
    }
  }

  /// Simple logout method that deletes all sessions
  /// Used for normal logout flow
  Future<void> logout() async {
    try {
      await deleteAllSessions();
      debugPrint('✅ Logged out (Appwrite sessions deleted)');
    } on AppwriteException catch (e) {
      debugPrint('❌ Appwrite logout error [${e.code}] ${e.type}: ${e.message}');
      // Don't rethrow; we still want to clear local state and navigate out
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  // Database Methods
  /// Creates or updates a user profile document.
  /// 
  /// This method implements a "create-or-update" pattern:
  /// 1. First attempts to create a new profile document
  /// 2. If document already exists (409 error), automatically falls back to update
  /// 3. Uses userId as documentId to ensure one profile per user
  /// 4. Automatically adds updatedAt timestamp for updates
  /// 
  /// Returns the created/updated document with operation logging.
  Future<Document> createUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      print('📝 Creating user profile for ID: $userId');
      print('   Database ID: ${AppwriteConfig.databaseId}');
      print('   Collection ID: ${AppwriteConfig.profilesCollection}');
      print('   Profile data: $profileData');
      
      // Validate schema before attempting to create
      final schemaValidation = await validateProfileSchema(profileData);
      if (!schemaValidation['valid']) {
        print('❌ Schema validation failed: ${schemaValidation['error']}');
        print('   Missing attributes: ${schemaValidation['missing']}');
        print('   Unexpected attributes: ${schemaValidation['unexpected']}');
        throw Exception('Profile schema validation failed: ${schemaValidation['error']}. Please check your Appwrite collection attributes.');
      }
      
      print('✅ Schema validation passed');
      
      // First, try with document-level permissions (recommended approach)
      try {
        final permissions = [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ];
        
        print('🔐 Attempting to create with document-level permissions: $permissions');
        
        final document = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.profilesCollection,
          documentId: userId,
          data: profileData,
          permissions: permissions,
        );
        
                 print('✅ User profile created successfully with document-level permissions: ${document.$id}');
         print('   Operation: CREATE (new profile)');
         return document;
        
      } catch (permissionError) {
        // If document-level permissions fail, try without permissions (collection-level)
        if (permissionError.toString().contains('user_unauthorized') || 
            permissionError.toString().contains('permission denied') ||
            permissionError.toString().contains('Permissions must be one of: (any, guests)')) {
          
          print('⚠️ Document-level permissions failed, trying with collection-level permissions...');
          print('   This is less secure but will work with current collection setup');
          
          final document = await _databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.profilesCollection,
            documentId: userId,
            data: profileData,
            // No permissions parameter - uses collection-level permissions
          );
          
                     print('✅ User profile created successfully with collection-level permissions: ${document.$id}');
           print('   Operation: CREATE (new profile)');
           print('⚠️ WARNING: Profile is accessible to all authenticated users due to collection-level permissions');
           print('   Consider updating Appwrite collection to use document-level permissions for better security');
           
           return document;
        } else {
          // Re-throw if it's not a permission issue
          rethrow;
        }
      }
      
    } catch (e) {
      print('❌ Error creating user profile: $e');
      
      // If document already exists, try to update it
      if (e.toString().contains('already exists') || e.toString().contains('document already exists') || 
          e.toString().contains('document_already_exists') || e.toString().contains('409')) {
        print('🔄 Document already exists (409), automatically falling back to update...');
        print('   This is normal behavior when userId already has a profile');
        
        try {
          // Automatically add updatedAt timestamp for the update
          final profileDataWithTimestamp = _addUpdatedAtToProfile(profileData);
          print('   Updating with data: $profileDataWithTimestamp');
          
          final document = await _databases.updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.profilesCollection,
            documentId: userId,
            data: profileDataWithTimestamp,
          );
          print('✅ User profile updated successfully: ${document.$id}');
          print('   Operation: UPDATE (existing profile)');
          return document;
        } catch (updateError) {
          print('❌ Error updating user profile: $updateError');
          throw _handleAppwriteError(updateError);
        }
      }
      
             // Check for specific database errors
       if (e.toString().contains('database not found')) {
         throw Exception('Database "${AppwriteConfig.databaseId}" not found. Please create it in Appwrite console.');
       }
       if (e.toString().contains('collection not found')) {
         throw Exception('Collection "${AppwriteConfig.profilesCollection}" not found. Please create it in Appwrite console.');
       }
       if (e.toString().contains('document_invalid_structure')) {
         throw Exception('Document structure invalid. Please check your Appwrite collection schema. Expected attributes: name, email, phone, role, isVerified, createdAt, updatedAt');
       }
       if (e.toString().contains('permission denied') || e.toString().contains('user_unauthorized')) {
         throw Exception('Permission denied. Please check your Appwrite collection permissions and ensure the user can create documents.');
       }
       
       // If we get here, it's an unexpected error
       print('❌ Unexpected error during profile creation/update: $e');
       throw _handleAppwriteError(e);
    }
  }

  Future<Document> getUserProfile(String userId) async {
    try {
      print('📖 Getting user profile for ID: $userId');
      print('   Database ID: ${AppwriteConfig.databaseId}');
      print('   Collection ID: ${AppwriteConfig.profilesCollection}');
      
      final document = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.profilesCollection,
        documentId: userId,
      );
      
      print('✅ User profile retrieved successfully');
      print('   Document ID: ${document.$id}');
      print('   Document data: ${document.data}');
      print('   Role field: ${document.data['role']}');
      print('   Role field type: ${document.data['role']?.runtimeType}');
      
      return document;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      
      // Check for specific permission errors
      if (e.toString().contains('permission denied') || e.toString().contains('user_unauthorized')) {
        throw Exception('Permission denied. You can only read your own profile. Please check your authentication status.');
      }
      if (e.toString().contains('document not found')) {
        throw Exception('Profile not found. Please create your profile first.');
      }
      
      throw _handleAppwriteError(e);
    }
  }

  // Helper function to automatically add updatedAt timestamp to profile updates
  Map<String, dynamic> _addUpdatedAtToProfile(Map<String, dynamic> updates) {
    return {
      ...updates,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<Document> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      print('📝 Updating user profile for ID: $userId');
      print('   Updates: $updates');
      
      // Automatically add updatedAt timestamp to all profile updates
      final updatesWithTimestamp = _addUpdatedAtToProfile(updates);
      print('   Updates with timestamp: $updatesWithTimestamp');
      
      final document = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.profilesCollection,
        documentId: userId,
        data: updatesWithTimestamp,
      );
      
      print('✅ User profile updated successfully');
      return document;
    } catch (e) {
      print('❌ Error updating user profile: $e');
      
      // Check for specific permission errors
      if (e.toString().contains('permission denied') || e.toString().contains('user_unauthorized')) {
        throw Exception('Permission denied. You can only update your own profile. Please check your authentication status.');
      }
      if (e.toString().contains('document not found')) {
        throw Exception('Profile not found. Please create your profile first.');
      }
      
      throw _handleAppwriteError(e);
    }
  }

  Future<Document> createVerificationData({
    required String userId,
    required Map<String, dynamic> verificationData,
  }) async {
    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.verificationsCollection,
        documentId: 'verification_$userId',
        data: verificationData,
      );
      return document;
    } catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  Future<Document?> getVerificationData(String userId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.verificationsCollection,
        documentId: 'verification_$userId',
      );
      return document;
    } catch (e) {
      // Return null if verification data doesn't exist
      return null;
    }
  }

  Future<bool> hasVerificationData(String userId) async {
    try {
      await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.verificationsCollection,
        documentId: 'verification_$userId',
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Check if user profile exists and get basic info
  Future<Map<String, dynamic>?> getUserProfileInfo(String userId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.profilesCollection,
        documentId: userId,
      );
      
      print('🔍 Profile info for user $userId:');
      print('   Exists: true');
      print('   Data: ${document.data}');
      print('   Role: ${document.data['role']}');
      
      return document.data;
    } catch (e) {
      print('🔍 Profile info for user $userId:');
      print('   Exists: false');
      print('   Error: $e');
      return null;
    }
  }

  // Check if a user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.profilesCollection,
        documentId: userId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Validate profile schema before creating documents
  Future<Map<String, dynamic>> validateProfileSchema(Map<String, dynamic> profileData) async {
    try {
      print('🔍 Validating profile schema...');
      
      // Expected required attributes based on your Appwrite collection
      final requiredAttributes = [
        'name',
        'email', 
        'phone',
        'role',
        'isVerified',
        'createdAt',
        'updatedAt',
      ];
      
      // Check for missing required attributes
      final missingAttributes = <String>[];
      for (final attribute in requiredAttributes) {
        if (!profileData.containsKey(attribute)) {
          missingAttributes.add(attribute);
        }
      }
      
      // Check for unexpected attributes
      final unexpectedAttributes = <String>[];
      for (final key in profileData.keys) {
        if (!requiredAttributes.contains(key)) {
          unexpectedAttributes.add(key);
        }
      }
      
      if (missingAttributes.isNotEmpty) {
        return {
          'valid': false,
          'error': 'Missing required attributes: ${missingAttributes.join(', ')}',
          'missing': missingAttributes,
          'unexpected': unexpectedAttributes,
        };
      }
      
      if (unexpectedAttributes.isNotEmpty) {
        print('⚠️ Warning: Unexpected attributes found: ${unexpectedAttributes.join(', ')}');
        print('   These will be ignored by Appwrite if not in the collection schema');
      }
      
      return {
        'valid': true,
        'message': 'Profile schema is valid',
        'missing': <String>[],
        'unexpected': unexpectedAttributes,
      };
      
    } catch (e) {
      return {
        'valid': false,
        'error': 'Schema validation failed: $e',
        'missing': <String>[],
        'unexpected': <String>[],
      };
    }
  }

  // Test collection permissions to diagnose issues
  Future<Map<String, dynamic>> testCollectionPermissions() async {
    try {
      print('🔍 Testing collection permissions...');
      
      // Try to create a test document with document-level permissions
      try {
        final testData = {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        final testPermissions = [
          Permission.read(Role.user('test_user')),
          Permission.update(Role.user('test_user')),
          Permission.delete(Role.user('test_user')),
        ];
        
        print('🔐 Testing document-level permissions...');
        
        final document = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.profilesCollection,
          documentId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          data: testData,
          permissions: testPermissions,
        );
        
        print('✅ Document-level permissions working!');
        
        // Clean up test document
        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.profilesCollection,
          documentId: document.$id,
        );
        
        return {
          'status': 'success',
          'message': 'Document-level permissions are working correctly',
          'permission_type': 'document_level',
        };
        
      } catch (e) {
        if (e.toString().contains('user_unauthorized') || 
            e.toString().contains('Permissions must be one of: (any, guests)')) {
          
          print('⚠️ Document-level permissions failed, testing collection-level...');
          
          // Try without permissions (collection-level)
          try {
            final testData = {
              'test': true,
              'timestamp': DateTime.now().toIso8601String(),
            };
            
            final document = await _databases.createDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.profilesCollection,
              documentId: 'test_${DateTime.now().millisecondsSinceEpoch}',
              data: testData,
              // No permissions parameter
            );
            
            print('✅ Collection-level permissions working!');
            
            // Clean up test document
            await _databases.deleteDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.profilesCollection,
              documentId: document.$id,
            );
            
            return {
              'status': 'warning',
              'message': 'Collection is using collection-level permissions (less secure)',
              'permission_type': 'collection_level',
              'recommendation': 'Consider updating to document-level permissions for better security',
            };
            
          } catch (collectionError) {
            return {
              'status': 'error',
              'message': 'Both permission types failed',
              'permission_type': 'unknown',
              'document_level_error': e.toString(),
              'collection_level_error': collectionError.toString(),
              'recommendation': 'Check collection permissions in Appwrite console',
            };
          }
        } else {
          return {
            'status': 'error',
            'message': 'Unexpected error during permission test',
            'permission_type': 'unknown',
            'error': e.toString(),
          };
        }
      }
      
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to test permissions',
        'permission_type': 'unknown',
        'error': e.toString(),
      };
    }
  }

  Future<String?> getVerificationStatus(String userId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.verificationsCollection,
        documentId: 'verification_$userId',
      );
      return document.data['verification_status'];
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteVerificationData(String userId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.verificationsCollection,
        documentId: 'verification_$userId',
      );
    } catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  // Storage Methods
  Future<File> uploadFile({
    required String bucketId,
    String? fileId, // Made optional - if null, Appwrite will generate ID
    Uint8List? fileBytes, // Made optional - can use filePath instead
    String? filePath, // Optional: path to file on device
    String? fileName,
    String? userId, // Optional: for setting permissions
  }) async {
    try {
      print('📁 Starting file upload...');
      print('   Bucket ID: $bucketId');
      print('   File ID: $fileId');
      print('   File path: $filePath');
      print('   Has bytes: ${fileBytes != null}');
      print('   User ID: $userId');
      
      // Validate that either fileBytes or filePath is provided
      if (fileBytes == null && filePath == null) {
        throw Exception('Either fileBytes or filePath must be provided for file upload');
      }
      
      // Generate fileId if not provided, or validate existing one
      String finalFileId;
      if (fileId == null) {
        // Let Appwrite generate a unique ID
        finalFileId = ID.unique();
        print('   Generated File ID: $finalFileId');
      } else {
        // Validate provided fileId format
        if (fileId.length > 36) {
          throw Exception('File ID must be 36 characters or less');
        }
        
        // Remove any invalid characters from fileId
        finalFileId = fileId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
        print('   Clean File ID: $finalFileId');
      }
      
      // Set proper permissions for the file
      List<String> permissions = [];
      if (userId != null) {
        // User can read, update, and delete their own files
        permissions.add(Permission.read(Role.user(userId)));
        permissions.add(Permission.update(Role.user(userId)));
        permissions.add(Permission.delete(Role.user(userId)));
        
        // Optional: Admins can read files for review
        // permissions.add(Permission.read(Role.team("admins")));
        
        print('🔐 Setting file permissions: $permissions');
      }
      
      // Create InputFile based on available data
      InputFile inputFile;
      if (filePath != null) {
        // Use file path if available
        inputFile = InputFile.fromPath(
          path: filePath,
          filename: fileName ?? 'file',
        );
        print('   Using file path: $filePath');
      } else {
        // Use bytes if available
        inputFile = InputFile.fromBytes(
          bytes: fileBytes!,
          filename: fileName ?? 'file',
        );
        print('   Using file bytes: ${fileBytes!.length} bytes');
      }
      
      final file = await _storage.createFile(
        bucketId: bucketId,
        fileId: finalFileId,
        file: inputFile,
        permissions: permissions.isNotEmpty ? permissions : null,
      );
      
      print('✅ File uploaded successfully: ${file.$id}');
      return file;
    } catch (e) {
      print('❌ File upload failed: $e');
      throw _handleAppwriteError(e);
    }
  }

  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      print('🗑️ Deleting file: $fileId from bucket: $bucketId');
      await _storage.deleteFile(
        bucketId: bucketId,
        fileId: fileId,
      );
      print('✅ File deleted successfully: $fileId');
    } catch (e) {
      print('❌ Error deleting file: $e');
      throw _handleAppwriteError(e);
    }
  }

  // Clean up uploaded files if verification fails
  Future<void> cleanupUploadedFiles({
    required String bucketId,
    required List<String> fileIds,
  }) async {
    try {
      print('🧹 Cleaning up uploaded files: $fileIds');
      
      for (final fileId in fileIds) {
        try {
          await deleteFile(bucketId: bucketId, fileId: fileId);
        } catch (e) {
          print('⚠️ Failed to delete file $fileId: $e');
          // Continue with other files even if one fails
        }
      }
      
      print('✅ File cleanup completed');
    } catch (e) {
      print('❌ File cleanup failed: $e');
      // Don't throw - cleanup failure shouldn't break the main flow
    }
  }

  String getFileUrl({
    required String bucketId,
    required String fileId,
  }) {
    return '${AppwriteConfig.endpoint}/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }

  // Upload file to bucket and return file ID
  Future<String> uploadToBucket({
    required String bucketId,
    required String filePath,
    String? fileName,
    String? userId, // Optional: for setting permissions
  }) async {
    try {
      print('📁 Uploading file to bucket: $bucketId');
      print('   File path: $filePath');
      print('   File name: $fileName');
      print('   User ID: $userId');
      
      final file = InputFile.fromPath(
        path: filePath,
        filename: fileName ?? 'file',
      );
      
      // Set permissions if userId is provided
      List<String>? permissions;
      if (userId != null) {
        permissions = [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ];
        print('🔐 Setting file permissions: $permissions');
      }
      
      final result = await _storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: file,
        permissions: permissions,
      );
      
      print('✅ File uploaded successfully: ${result.$id}');
      return result.$id;
    } catch (e) {
      print('❌ File upload failed: $e');
      throw _handleAppwriteError(e);
    }
  }

  /// Upload profile image with improved error handling
  Future<String> uploadProfileImage({
    required String userId,
    required String filePath,
  }) async {
    try {
      debugPrint('📁 Uploading profile image to bucket: ${AppwriteIds.profileBucketId}');
      debugPrint('   User ID: $userId');
      debugPrint('   File path: $filePath');
      
      final res = await _storage.createFile(
        bucketId: AppwriteIds.profileBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath),
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
      
      debugPrint('✅ Profile image uploaded to bucket ${AppwriteIds.profileBucketId}, fileId: ${res.$id}');
      return res.$id;
    } on AppwriteException catch (e) {
      debugPrint('❌ Profile image upload failed [${e.code}]: ${e.type} - ${e.message}');
      
      // Add a more helpful message for 404
      if (e.code == 404) {
        throw Exception(
          'Storage bucket not found. Ensure a bucket with ID "${AppwriteIds.profileBucketId}" exists in the SAME project and region.',
        );
      }
      
      // Handle other common Appwrite errors
      if (e.code == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (e.code == 403) {
        throw Exception('Permission denied. You cannot upload files to this bucket.');
      } else if (e.code == 413) {
        throw Exception('File too large. Please select a smaller image.');
      }
      
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error during profile image upload: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Build a public "view" URL for the uploaded file (requires proper read perms)
  String fileViewUrl(String bucketId, String fileId) {
    // Append project ID so the SDK can authorize the request
    final endpoint = _client.endPoint; // e.g., https://cloud.appwrite.io/v1
    final projectId = _client.config['project'];
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=$projectId';
  }

  /// Upload avatar/photo with PUBLIC READ permission so NetworkImage works
  Future<(String fileId, String url)> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      final result = await _storage.createFile(
        bucketId: AppwriteIds.profileBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath),
        permissions: [
          Permission.read(Role.any()),           // <-- important: public read
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
      final url = fileViewUrl(AppwriteIds.profileBucketId, result.$id);
      debugPrint('✅ Avatar uploaded with public read: ${result.$id}');
      return (result.$id, url);
    } on AppwriteException catch (e) {
      debugPrint('❌ Avatar upload failed [${e.code}] ${e.type}: ${e.message}');
      if (e.code == 404) {
        throw Exception('Bucket "${AppwriteIds.profileBucketId}" not found in this project.');
      }
      rethrow;
    }
  }

  /// Upload driver document with PUBLIC READ permission for preview/download
  Future<(String fileId, String url)> uploadDriverDocument({
    required String userId,
    required String filePath,
  }) async {
    try {
      final result = await _storage.createFile(
        bucketId: AppwriteIds.profileBucketId, // reuse "profile-images" unless you have a docs bucket
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath),
        permissions: [
          Permission.read(Role.any()),           // <-- important: public read
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
      final url = fileViewUrl(AppwriteIds.profileBucketId, result.$id);
      debugPrint('✅ Driver document uploaded with public read: ${result.$id}');
      return (result.$id, url);
    } on AppwriteException catch (e) {
      debugPrint('❌ Driver document upload failed [${e.code}] ${e.type}: ${e.message}');
      if (e.code == 404) {
        throw Exception('Bucket "${AppwriteIds.profileBucketId}" not found in this project.');
      }
      rethrow;
    }
  }

  /// Upload to profile bucket and return both fileId and viewable URL (legacy method)
  Future<(String fileId, String url)> uploadToProfileBucket({
    required String userId,
    required String filePath,
  }) async {
    try {
      final result = await _storage.createFile(
        bucketId: AppwriteIds.profileBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath),
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
      final url = fileViewUrl(AppwriteIds.profileBucketId, result.$id);
      debugPrint('✅ Uploaded file to ${AppwriteIds.profileBucketId}, fileId=${result.$id}');
      return (result.$id, url);
    } on AppwriteException catch (e) {
      debugPrint('❌ Upload failed [${e.code}] ${e.type}: ${e.message}');
      if (e.code == 404) {
        throw Exception('Bucket "${AppwriteIds.profileBucketId}" not found in this project.');
      }
      rethrow;
    }
  }

  /// Ensure a profiles document exists (ID mirrors account.$id)
  Future<void> ensureProfileDoc({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    try {
      await _databases.getDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.profilesCollectionId,
        documentId: userId,
      );
      // exists
      debugPrint('✅ Profile document already exists for $userId');
    } on AppwriteException catch (e) {
      if (e.code == 404 && e.type == 'document_not_found') {
        debugPrint('ℹ️ Creating new profiles document for $userId');
        await _databases.createDocument(
          databaseId: AppwriteIds.databaseId,
          collectionId: AppwriteIds.profilesCollectionId,
          documentId: userId,
          data: {
            'name': name,
            'email': email,
            'phone': phone,
            'role': role,
            'isVerified': false,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          permissions: [
            Permission.read(Role.user(userId)),
            Permission.write(Role.user(userId)),
          ],
        );
        debugPrint('✅ Created new profile document for $userId');
      } else if (e.code == 404 && e.type == 'collection_not_found') {
        throw Exception('profiles collection not found. Check AppwriteIds.profilesCollectionId and databaseId.');
      } else {
        rethrow;
      }
    }
  }

  /// Create or update a verification record (verifications collection)
  Future<String> upsertVerification({
    required String userId,
    required String role, // 'driver' | 'client'
    required String profileImageUrl,
    String? documentUrl, // required only for driver
    required String houseNumber,
    required String street,
    required String city,
    required String state,
    required String status, // 'VERIFIED' after success
  }) async {
    try {
      // One-per-user approach: use userId as documentId; adjust if you prefer multiple submissions
      final now = DateTime.now().toIso8601String();

      // Try get; if not exists, create
      try {
        await _databases.getDocument(
          databaseId: AppwriteIds.databaseId,
          collectionId: AppwriteIds.verificationsCollectionId,
          documentId: userId,
        );
        // Document exists, update it
        await _databases.updateDocument(
          databaseId: AppwriteIds.databaseId,
          collectionId: AppwriteIds.verificationsCollectionId,
          documentId: userId,
          data: {
            'userId': userId,
            'role': role,
            'profileImageUrl': profileImageUrl,
            'documentUrl': documentUrl ?? '',
            'houseNumber': houseNumber,
            'street': street,
            'city': city,
            'state': state,
            'status': status,
            'updatedAt': now,
          },
        );
        debugPrint('✅ Updated existing verification document for $userId');
        return userId;
      } on AppwriteException catch (e) {
        if (e.code == 404 && e.type == 'document_not_found') {
          // Document doesn't exist, create it
          final res = await _databases.createDocument(
            databaseId: AppwriteIds.databaseId,
            collectionId: AppwriteIds.verificationsCollectionId,
            documentId: userId,
            data: {
              'userId': userId,
              'role': role,
              'profileImageUrl': profileImageUrl,
              'documentUrl': documentUrl ?? '',
              'houseNumber': houseNumber,
              'street': street,
              'city': city,
              'state': state,
              'status': status,
              'createdAt': now,
              'updatedAt': now,
            },
            permissions: [
              Permission.read(Role.users()),             // allow all authenticated users to read verification info
              Permission.write(Role.user(userId)),       // only owner can write
              Permission.update(Role.user(userId)),
            ],
          );
          debugPrint('✅ Created new verification document for $userId');
          return res.$id;
        } else if (e.code == 404 && e.type == 'collection_not_found') {
          throw Exception('verifications collection not found. Check AppwriteIds.verificationsCollectionId and databaseId.');
        } else {
          rethrow;
        }
      }
    } on AppwriteException catch (e) {
      debugPrint('❌ Upsert verification failed [${e.code}] ${e.type}: ${e.message}');
      rethrow;
    }
  }

  /// Mark user verified in profiles and store avatar in prefs for UI
  Future<void> finalizeVerification({
    required String role,
    required String profileImageUrl,
  }) async {
    final acc = await _account.get();
    final userId = acc.$id;

    debugPrint('✅ Finalizing verification for user $userId');

    // Ensure profiles doc exists
    await ensureProfileDoc(
      userId: userId,
      name: acc.name ?? '',
      email: acc.email ?? '',
      phone: '', // supply actual phone if available
      role: role,
    );

    // Mark as verified
    await _databases.updateDocument(
      databaseId: AppwriteIds.databaseId,
      collectionId: AppwriteIds.profilesCollectionId,
      documentId: userId,
      data: {
        'isVerified': true,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );

    // Save profileImageUrl in prefs for avatar rendering
    await _account.updatePrefs(prefs: {
      'profileImageUrl': profileImageUrl,
      'isVerified': true,
    });

    debugPrint('✅ finalizeVerification complete for $userId');
  }

  /// Save avatar, address, and document URL in Account preferences for fast access
  Future<void> savePrefsAfterVerification({
    required String profileImageUrl,
    String? documentUrl,
    required String houseNumber,
    required String street,
    required String city,
    required String state,
  }) async {
    final pretty = [
      if (houseNumber.isNotEmpty) houseNumber,
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].join(', ');
    
    final prefs = {
      'profileImageUrl': profileImageUrl,
      'address': {
        'houseNumber': houseNumber,
        'street': street,
        'city': city,
        'state': state,
      },
      'addressString': pretty,
    };
    
    if (documentUrl != null && documentUrl.isNotEmpty) {
      prefs['documentUrl'] = documentUrl;
    }
    
    await _account.updatePrefs(prefs: prefs);
    debugPrint('✅ Saved prefs: avatar + address ${documentUrl != null ? "+ document" : ""}');
  }

  /// Save avatar and address in Account preferences for fast access (legacy method)
  Future<void> savePrefsAvatarAndAddress({
    required String profileImageUrl,
    required String houseNumber,
    required String street,
    required String city,
    required String state,
  }) async {
    final pretty = _formatAddress(houseNumber, street, city, state);
    await _account.updatePrefs(prefs: {
      'profileImageUrl': profileImageUrl,
      'address': {
        'houseNumber': houseNumber,
        'street': street,
        'city': city,
        'state': state,
      },
      'addressString': pretty,
    });
    debugPrint('✅ Saved prefs: avatar + address');
  }

  /// Format address into a readable string
  String _formatAddress(String houseNumber, String street, String city, String state) {
    final parts = [
      if (houseNumber.isNotEmpty) houseNumber,
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ];
    return parts.join(', ');
  }

  /// Get user preferences (for retrieving stored data)
  Future<Map<String, dynamic>> getPrefs() async {
    try {
      final prefs = await _account.getPrefs();
      // Appwrite returns a Preferences model with .data
      return Map<String, dynamic>.from(prefs.data);
    } catch (e) {
      debugPrint('⚠️ Could not get user preferences: $e');
      return {};
    }
  }

  /// Mark user verified in profiles collection (separate method for clarity)
  Future<void> markUserVerifiedInProfiles() async {
    final acc = await _account.get();
    await _databases.updateDocument(
      databaseId: AppwriteIds.databaseId,
      collectionId: AppwriteIds.profilesCollectionId,
      documentId: acc.$id,
      data: {
        'isVerified': true,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('✅ User marked as verified in profiles collection');
  }

  /// Make existing file publicly viewable (for retroactive permission fixes)
  Future<void> makeFilePublic(String fileId) async {
    try {
      final acc = await _account.get();
      await _storage.updateFile(
        bucketId: AppwriteIds.profileBucketId,
        fileId: fileId,
        permissions: [
          Permission.read(Role.any()),
          Permission.read(Role.user(acc.$id)),
          Permission.write(Role.user(acc.$id)),
        ],
      );
      debugPrint('✅ File $fileId now has public read permission');
    } catch (e) {
      debugPrint('❌ Failed to update file permissions: $e');
      rethrow;
    }
  }

  /// Get current account user ID
  Future<String> currentUserId() async {
    final acc = await _account.get();
    return acc.$id;
  }

  /// Upload KYC document with improved error handling
  Future<String> uploadKycDocument({
    required String userId,
    required String filePath,
  }) async {
    try {
      debugPrint('📁 Uploading KYC document to bucket: ${AppwriteIds.profileBucketId}');
      debugPrint('   User ID: $userId');
      debugPrint('   File path: $filePath');
      
      final res = await _storage.createFile(
        bucketId: AppwriteIds.profileBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath),
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
      
      debugPrint('✅ KYC document uploaded to bucket ${AppwriteIds.profileBucketId}, fileId: ${res.$id}');
      return res.$id;
    } on AppwriteException catch (e) {
      debugPrint('❌ KYC upload failed [${e.code}]: ${e.type} - ${e.message}');
      
      if (e.code == 404) {
        throw Exception(
          'KYC bucket not found. Update AppwriteIds.profileBucketId to the correct ID.',
        );
      }
      
      // Handle other common Appwrite errors
      if (e.code == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (e.code == 403) {
        throw Exception('Permission denied. You cannot upload documents to this bucket.');
      } else if (e.code == 413) {
        throw Exception('Document too large. Please select a smaller file.');
      }
      
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error during KYC document upload: $e');
      throw Exception('Failed to upload KYC document: $e');
    }
  }

  // Update user account preferences (schema-less, good for flexible data)
  Future<void> updateUserPrefs({
    String? profileImageFileId,
    String? documentFileId,
    String? documentType, // "LICENSE" | "NIN"
    Map<String, dynamic>? address,
  }) async {
    try {
      print('📝 Updating user preferences...');
      print('   Profile image: $profileImageFileId');
      print('   Document: $documentFileId');
      print('   Document type: $documentType');
      print('   Address: $address');
      
      final prefs = <String, dynamic>{};
      if (profileImageFileId != null) prefs['profileImageFileId'] = profileImageFileId;
      if (documentFileId != null) prefs['documentFileId'] = documentFileId;
      if (documentType != null) prefs['documentType'] = documentType;
      if (address != null) prefs['address'] = address;
      
      await _account.updatePrefs(prefs: prefs);
      print('✅ User preferences updated successfully');
    } catch (e) {
      print('❌ Failed to update user preferences: $e');
      throw _handleAppwriteError(e);
    }
  }

  // Mark user as verified in the users collection
  Future<void> markUserVerified({
    required String databaseId,
    required String usersCollectionId,
    required String userDocId,
  }) async {
    try {
      print('✅ Marking user as verified...');
      print('   Database: $databaseId');
      print('   Collection: $usersCollectionId');
      print('   User ID: $userDocId');
      
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userDocId,
        data: {
          'isVerified': true,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      
      print('✅ User marked as verified successfully');
    } catch (e) {
      print('❌ Failed to mark user as verified: $e');
      throw _handleAppwriteError(e);
    }
  }

  // Get user preferences (for retrieving stored data)
  Future<Map<String, dynamic>> getUserPrefs() async {
    try {
      final user = await _account.get();
      return user.prefs.data;
    } catch (e) {
      print('⚠️ Could not get user preferences: $e');
      return {};
    }
  }

  // Get file URL with optional query parameters
  String getFileUrlWithParams({
    required String bucketId,
    required String fileId,
    Map<String, String>? queryParams,
  }) {
    final baseUrl = getFileUrl(bucketId: bucketId, fileId: fileId);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      return '$baseUrl&$queryString';
    }
    
    return baseUrl;
  }

  // Error Handling
  String _handleAppwriteError(dynamic error) {
    if (error is AppwriteException) {
      switch (error.type) {
        case 'user_already_exists':
          return 'An account already exists with this email.';
        case 'user_invalid_credentials':
          return 'Invalid email or password.';
        case 'user_invalid_email':
          return 'Please provide a valid email address.';
        case 'user_invalid_password':
          return 'Password must be at least 8 characters long.';
        case 'user_unauthorized':
          return 'Unauthorized access. Please sign in again.';
        case 'user_session_already_exists':
          return 'A session is already active. Please sign out first.';
        case 'user_session_invalid':
          return 'Invalid session. Please sign in again.';
        case 'document_already_exists':
          return 'Document already exists.';
        case 'document_not_found':
          return 'Document not found.';
        case 'document_invalid_id':
          return 'Invalid document ID.';
        case 'document_unauthorized':
          return 'Unauthorized access to document. Please check your permissions.';
        case 'storage_file_not_found':
          return 'File not found.';
        case 'storage_bucket_not_found':
          return 'Storage bucket not found.';
        case 'storage_file_invalid':
          return 'Invalid file format or corrupted file.';
        case 'storage_file_too_large':
          return 'File size exceeds the maximum allowed limit.';
        case 'storage_file_already_exists':
          return 'A file with this name already exists.';
        case 'storage_quota_exceeded':
          return 'Storage quota exceeded. Please contact support.';
        case 'permission_denied':
          return 'Permission denied. You do not have access to this resource.';
        case 'permission_unsupported':
          return 'Permission not supported for this operation.';
        default:
          return error.message ?? 'An error occurred.';
      }
    }
    return error.toString();
  }

  // Booking and Job Request Methods
  Future<List<DriverProfile>> fetchDrivers({bool verifiedOnly = true, int limit = 50}) async {
    try {
      final filters = <String>[
        Query.equal('role', ['driver']),
        if (verifiedOnly) Query.equal('isVerified', [true]),
        Query.limit(limit),
        Query.orderDesc('createdAt'),
      ];
      
      final DocumentList docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.profilesCollectionId,
        queries: filters,
      );
      
      // We don't have a public avatar in profiles; fallback to null (initials in UI)
      return docs.documents.map((d) {
        final data = d.data;
        return DriverProfile(
          id: d.$id,
          name: (data['name'] as String?) ?? 'Driver',
          isVerified: (data['isVerified'] as bool?) ?? false,
          role: (data['role'] as String?) ?? 'driver',
          phone: (data['phone'] as String?),
          avatarUrl: null,
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching drivers: $e');
      throw _handleAppwriteError(e);
    }
  }

  Future<JobRequest> createJobRequest({
    required String clientId,
    required String driverId,
    required String pickup,
    required String destination,
    required DateTime scheduledAt,
    String? note,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final payload = {
        'clientId': clientId,
        'driverId': driverId,
        'pickup': pickup,
        'destination': destination,
        'scheduledAt': scheduledAt.toIso8601String(),
        'note': note ?? '',
        'status': 'PENDING',
        'createdAt': now,
        'updatedAt': now,
      };

      final doc = await _databases.createDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.jobRequestsCollectionId,
        documentId: ID.unique(),
        data: payload,
        permissions: [
          Permission.read(Role.users()),               // readable by authenticated users (we filter in queries)
          Permission.write(Role.user(clientId)),       // client can write
          Permission.update(Role.users()),             // TEMP: allow any authed user to update so driver can accept
          Permission.delete(Role.user(clientId)),      // client can delete
        ],
      );

      return JobRequest.fromMap(doc.data..[r'$id'] = doc.$id);
    } catch (e) {
      if (e is AppwriteException) {
        print('❌ Appwrite error creating job request:');
        print('  Code: ${e.code}');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response}');
      } else {
        print('❌ Error creating job request: $e');
      }
      throw _handleAppwriteError(e);
    }
  }

  Future<List<JobRequest>> listDriverJobRequests(String driverId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.jobRequestsCollectionId,
        queries: [
          Query.equal('driverId', [driverId]),
          Query.equal('status', ['PENDING']),
          Query.orderDesc('createdAt'),
          Query.limit(50),
        ],
      );
      return docs.documents.map((d) => JobRequest.fromMap(d.data..[r'$id'] = d.$id)).toList();
    } catch (e) {
      print('❌ Error listing driver job requests: $e');
      throw _handleAppwriteError(e);
    }
  }

  RealtimeSubscription subscribeDriverRequests({
    required String driverId,
    required void Function(JobRequest) onNew,
  }) {
    final channel = 'databases.${AppwriteIds.databaseId}.collections.${AppwriteIds.jobRequestsCollectionId}.documents';
    final sub = _realtime.subscribe([channel]);
    sub.stream.listen((event) {
      if (!event.events.any((e) => e.endsWith('.create'))) return;
      final p = event.payload; // Map<String, dynamic>
      if (p['driverId'] == driverId && p['status'] == 'PENDING') {
        try {
          onNew(JobRequest.fromMap(p));
        } catch (_) {}
      }
    });
    return sub;
  }

  // Count pending job requests for a driver
  Future<int> countDriverPendingRequests(String driverId) async {
    try {
      final DocumentList docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.jobRequestsCollectionId,
        queries: [
          Query.equal('driverId', [driverId]),
          Query.equal('status', ['PENDING']),
          Query.limit(100),           // adjust if you expect >100
        ],
      );
      return docs.total ?? docs.documents.length; // total is available on SDK >= 13; fallback to length
    } catch (e) {
      print('❌ Error counting driver pending requests: $e');
      return 0; // Return 0 on error to prevent UI crashes
    }
  }

  // Listen to any change and let caller refresh count on demand
  RealtimeSubscription subscribeJobRequestsChanges({
    required String driverId,
    required VoidCallback onChange,
  }) {
    final channel =
        'databases.${AppwriteIds.databaseId}.collections.${AppwriteIds.jobRequestsCollectionId}.documents';

    final sub = _realtime.subscribe([channel]);
    sub.stream.listen((event) {
      // Only react to documents relevant to this driver
      final p = event.payload;
      if (p is Map && p['driverId'] == driverId) {
        onChange();
      }
    });
    return sub;
  }

  // Update job request status (Accept/Reject)
  Future<void> updateJobRequestStatus({
    required String requestId,
    required String status, // ACCEPTED | REJECTED | CANCELLED
    DateTime? estimatedPickupAt,
    String? driverNote, // optional – if you later add a driverNote attribute
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': now,
    };
    if (status == 'ACCEPTED') {
      data['acceptedAt'] = now;
      if (estimatedPickupAt != null) {
        data['estimatedPickupAt'] = estimatedPickupAt.toIso8601String();
      }
    } else if (status == 'REJECTED') {
      data['rejectedAt'] = now;
    }
    if (driverNote != null) data['note'] = driverNote;

    await _databases.updateDocument(
      databaseId: AppwriteIds.databaseId,
      collectionId: AppwriteIds.jobRequestsCollectionId,
      documentId: requestId,
      data: data,
    );
  }

  // List all job requests for a client (all statuses)
  Future<List<JobRequest>> listClientJobRequests(String clientId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.jobRequestsCollectionId,
        queries: [
          Query.equal('clientId', [clientId]),
          Query.orderDesc('createdAt'),
          Query.limit(100),
        ],
      );
      return docs.documents.map((d) => JobRequest.fromMap(d.data..[r'$id'] = d.$id)).toList();
    } catch (e) {
      print('❌ Error listing client job requests: $e');
      throw _handleAppwriteError(e);
    }
  }

  // Realtime for client-side changes
  RealtimeSubscription subscribeClientRequestsChanges({
    required String clientId,
    required VoidCallback onChange,
  }) {
    final channel =
        'databases.${AppwriteIds.databaseId}.collections.${AppwriteIds.jobRequestsCollectionId}.documents';
    final sub = _realtime.subscribe([channel]);
    sub.stream.listen((event) {
      final p = event.payload;
      if (p is Map && p['clientId'] == clientId) {
        onChange();
      }
    });
    return sub;
  }

  // Accepted jobs for driver
  Future<List<JobRequest>> listDriverActiveJobs(String driverId) async {
    // Try preferred sort by acceptedAt; if missing in schema, fallback to updatedAt then createdAt
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.jobRequestsCollectionId,
        queries: [
          Query.equal('driverId', [driverId]),
          Query.equal('status', ['ACCEPTED']),
          Query.orderDesc('acceptedAt'), // may fail if attribute not defined
          Query.limit(100),
        ],
      );
      return docs.documents
          .map((d) => JobRequest.fromMap(d.data..[r'$id'] = d.$id))
          .toList();
    } on AppwriteException catch (e) {
      // Fallback 1: updatedAt
      if (e.code == 400) {
        try {
          final docs = await _databases.listDocuments(
            databaseId: AppwriteIds.databaseId,
            collectionId: AppwriteIds.jobRequestsCollectionId,
            queries: [
              Query.equal('driverId', [driverId]),
              Query.equal('status', ['ACCEPTED']),
              Query.orderDesc('updatedAt'),
              Query.limit(100),
            ],
          );
          return docs.documents
              .map((d) => JobRequest.fromMap(d.data..[r'$id'] = d.$id))
              .toList();
        } catch (_) {
          // Fallback 2: createdAt
          final docs = await _databases.listDocuments(
            databaseId: AppwriteIds.databaseId,
            collectionId: AppwriteIds.jobRequestsCollectionId,
            queries: [
              Query.equal('driverId', [driverId]),
              Query.equal('status', ['ACCEPTED']),
              Query.orderDesc('createdAt'),
              Query.limit(100),
            ],
          );
          return docs.documents
              .map((d) => JobRequest.fromMap(d.data..[r'$id'] = d.$id))
              .toList();
        }
      }
      rethrow;
    } catch (e) {
      print('❌ Error listing driver active jobs: $e');
      throw _handleAppwriteError(e);
    }
  }

  // Notifications for client
  Future<List<Document>> listClientNotifications(String userId) async {
    if (!await hasSession()) return [];
    try {
      // Prefer system $createdAt so we don't depend on a custom attribute
      final docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.notificationsCollectionId,
        queries: [
          Query.equal('userId', [userId]),
          Query.orderDesc(r'$createdAt'),
          Query.limit(100),
        ],
      );
      return docs.documents;
    } on AppwriteException catch (e) {
      // Fallback: if some projects still use a custom createdAt, try that
      if (e.code == 400) {
        try {
          final docs = await _databases.listDocuments(
            databaseId: AppwriteIds.databaseId,
            collectionId: AppwriteIds.notificationsCollectionId,
            queries: [
              Query.equal('userId', [userId]),
              Query.orderDesc('createdAt'),
              Query.limit(100),
            ],
          );
          return docs.documents;
        } catch (e2) {
          print('❌ Notifications list fallback failed: $e2');
          return [];
        }
      }
      print('❌ Error listing client notifications: $e');
      // Return empty list on 404 to prevent UI crashes
      if (e.toString().contains('404') || e.toString().contains('collection_not_found')) {
        print('⚠️ Notifications collection not found, returning empty list');
        return [];
      }
      throw _handleAppwriteError(e);
    }
  }

  // Count unread notifications for client
  Future<int> countClientUnreadNotifications(String userId) async {
    if (!await hasSession()) return 0;
    try {
      final DocumentList docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.notificationsCollectionId,
        queries: [
          Query.equal('userId', [userId]),
          Query.equal('status', ['UNREAD']),
          Query.limit(100), // adjust if you expect >100
        ],
      );
      return docs.total ?? docs.documents.length;
    } catch (e) {
      print('❌ Error counting client unread notifications: $e');
      return 0; // Return 0 on error to prevent UI crashes
    }
  }

  // Realtime for client notifications
  RealtimeSubscription subscribeClientNotifications({
    required String userId,
    required VoidCallback onChange,
  }) {
    final channel =
        'databases.${AppwriteIds.databaseId}.collections.${AppwriteIds.notificationsCollectionId}.documents';
    final sub = _realtime.subscribe([channel]);
    sub.stream.listen((event) {
      final p = event.payload;
      if (p is Map && p['userId'] == userId) {
        onChange();
      }
    });
    return sub;
  }

  // Mark notification as read
  Future<void> markNotificationRead(String notifId) async {
    if (!await hasSession()) return;
    try {
      await _databases.updateDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.notificationsCollectionId,
        documentId: notifId,
        data: {
          'status': 'READ',
          'readAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      throw _handleAppwriteError(e);
    }
  }

  // Chat and Messaging Methods
  // Find or create conversation using "members" as pairKey string
  Future<Document> getOrCreateConversation(String a, String b) async {
    final key = makePairKey(a, b);

    // Try find by exact pairKey
    final found = await _databases.listDocuments(
      databaseId: AppwriteIds.databaseId,
      collectionId: AppwriteIds.conversationsCollectionId,
      queries: [
        Query.equal('members', [key]),
        Query.limit(1),
      ],
    );
    if (found.documents.isNotEmpty) return found.documents.first;

    // Create new conversation
    final now = DateTime.now().toIso8601String();
    final conv = await _databases.createDocument(
      databaseId: AppwriteIds.databaseId,
      collectionId: AppwriteIds.conversationsCollectionId,
      documentId: ID.unique(),
      data: {
        'members': key,              // REQUIRED String
        'lastMessage': '',           // REQUIRED String (empty is fine)
        'lastMessageAt': now,        // optional in schema but good to fill
      },
      // TEMP: Users perms so client can create; your chat-acl function should tighten to the two users
      permissions: [
        Permission.read(Role.users()),
        Permission.write(Role.users()),
        Permission.update(Role.users()),
      ],
    );
    return conv;
  }

  // Inbox: try to narrow with search; fallback to list+filter client-side
  Future<List<Document>> listUserConversations(String userId) async {
    // Try Query.search (works if Console allows; if not, we fallback)
    try {
      final searched = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.conversationsCollectionId,
        queries: [
          Query.search('members', userId),
          Query.limit(100),
        ],
      );
      final list = searched.documents;
      list.sort((x, y) {
        final ax = (x.data['lastMessageAt'] as String?) ?? x.$createdAt ?? '';
        final ay = (y.data['lastMessageAt'] as String?) ?? y.$createdAt ?? '';
        return ay.compareTo(ax);
      });
      return list;
    } on AppwriteException catch (e) {
      // Fallback: list visible docs (server already restricts by perms) and filter locally
      final docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.conversationsCollectionId,
        queries: [
          Query.limit(100),
          // Avoid fragile ordering by custom fields; UI can sort in-memory by lastMessageAt/$createdAt
        ],
      );
      final filtered = docs.documents.where((d) {
        final key = (d.data['members'] as String?) ?? '';
        return key.contains(userId); // okay because perms already limit visibility
      }).toList();

      filtered.sort((x, y) {
        final ax = (x.data['lastMessageAt'] as String?) ?? x.$createdAt ?? '';
        final ay = (y.data['lastMessageAt'] as String?) ?? y.$createdAt ?? '';
        return ay.compareTo(ax);
      });
      return filtered;
    }
  }

  // Conversation messages
  Future<List<Document>> listMessages(String conversationId, {int limit = 50}) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.messagesCollectionId,
        queries: [
          Query.equal('conversationId', [conversationId]),
          Query.orderAsc(r'$createdAt'),
          Query.limit(limit),
        ],
      );
      return docs.documents;
    } catch (e) {
      print('❌ Error listing messages: $e');
      throw _handleAppwriteError(e);
    }
  }

  // Send message
  Future<Document> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final now = DateTime.now().toIso8601String();

    // base data without custom createdAt
    final base = <String, dynamic>{
      'conversationId': conversationId,
      'senderId': senderId,
      'body': text,
      'type': 'text',
    };

    // Try with createdAt first (if your schema truly has it), then fallback
    Map<String, dynamic> dataWithCreated = {...base, 'createdAt': now};

    Future<Document> _create(Map<String, dynamic> payload) {
      return _databases.createDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.messagesCollectionId,
        documentId: ID.unique(),
        data: payload,
        permissions: [
          // TEMP Users perms; your chat-acl function should restrict to two users on CREATE
          Permission.read(Role.users()),
          Permission.write(Role.users()),
          Permission.update(Role.users()),
        ],
      );
    }

    Document msg;
    try {
      msg = await _create(dataWithCreated);
    } on AppwriteException catch (e) {
      // If schema rejects 'createdAt', retry without it
      final msgStr = (e.message ?? '').toLowerCase();
      if (e.code == 400 && (msgStr.contains('createdat') || msgStr.contains('unknown attribute'))) {
        print('⚠️ createdAt not in schema; retrying without it');
        msg = await _create(base);
      } else {
        print('❌ Error sending message: ${e.type} ${e.code} ${e.message}');
        throw _handleAppwriteError(e);
      }
    }

    // Update conversation summary (safe)
    try {
      await _databases.updateDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.conversationsCollectionId,
        documentId: conversationId,
        data: {
          'lastMessage': text,
          'lastMessageAt': now,
        },
      );
    } catch (e) {
      print('⚠️ Failed to update conversation summary: $e');
    }

    return msg;
  }

  // Subscribe to messages for a conversation
  RealtimeSubscription subscribeMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> payload) onCreate,
  }) {
    final channel =
        'databases.${AppwriteIds.databaseId}.collections.${AppwriteIds.messagesCollectionId}.documents';
    final sub = _realtime.subscribe([channel]);
    sub.stream.listen((event) {
      // Debug logs (remove later if noisy)
      // debugPrint('RT Event: ${event.events} -> ${event.payload}');

      if (!event.events.any((e) => e.endsWith('.create'))) return;
      final p = event.payload;
      if (p is Map && p['conversationId'] == conversationId) {
        onCreate(Map<String, dynamic>.from(p));
      }
    }, onError: (e) {
      // debugPrint('RT Error: $e');
    });
    return sub;
  }

  // Subscribe to any conversation change that involves this user (inbox auto-refresh)
  RealtimeSubscription subscribeConversations({
    required String userId,
    required VoidCallback onChange,
  }) {
    final channel =
        'databases.${AppwriteIds.databaseId}.collections.${AppwriteIds.conversationsCollectionId}.documents';
    final sub = _realtime.subscribe([channel]);
    sub.stream.listen((event) {
      final p = event.payload;
      if (p is Map) {
        final key = (p['members'] as String?) ?? '';
        if (key.contains(userId)) onChange();
      }
    }, onError: (e) {
      // debugPrint('RT conv error: $e');
    });
    return sub;
  }

  // ---------- Conversation and Peer Management ----------

  Future<Document> getConversation(String id) {
    return _databases.getDocument(
      databaseId: AppwriteIds.databaseId,
      collectionId: AppwriteIds.conversationsCollectionId,
      documentId: id,
    );
  }

  String? resolvePeerIdFromConversation(Document conv, String myId) {
    final key = (conv.data['members'] as String?) ?? '';
    return peerIdFromPairKey(key, myId);
  }

  // Fetch peer profile (name + avatar) for display
  Future<Map<String, dynamic>?> fetchPeerPublic(String peerId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.profilesCollectionId,
        documentId: peerId,
      );
      return {
        'name': (doc.data['name'] as String?) ?? 'User',
        'avatarUrl': null, // if you store avatar in verifications or prefs, plug it in
        'role': (doc.data['role'] as String?) ?? 'client',
        'verified': (doc.data['isVerified'] as bool?) ?? false,
      };
    } catch (e) {
      print('⚠️ fetchPeerPublic failed: $e');
      return null;
    }
  }

  // ---------- Unread / messages_read ----------

  String _readDocId(String conversationId, String userId) {
    final raw = '$conversationId|$userId';
    final hash = crypto.sha1.convert(utf8.encode(raw)).toString().substring(0, 30);
    return 'rd_$hash'; // <=36 chars, valid
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final docId = _readDocId(conversationId, userId);

    try {
      await _databases.updateDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.messagesReadCollectionId,
        documentId: docId,
        data: {'lastReadAt': now, 'updatedAt': now},
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        // Create if missing
        await _databases.createDocument(
          databaseId: AppwriteIds.databaseId,
          collectionId: AppwriteIds.messagesReadCollectionId,
          documentId: docId,
          data: {
            'conversationId': conversationId,
            'userId': userId,
            'lastReadAt': now,
            'updatedAt': now,
          },
          permissions: [
            Permission.read(Role.user(userId)),
            Permission.update(Role.user(userId)),
            Permission.delete(Role.user(userId)),
          ],
        );
              } else {
          debugPrint('⚠️ markConversationRead failed: ${e.message}');
        }
    }
  }

  // Count unread messages for a conversation for userId
  Future<int> countUnreadForConversation({
    required String conversationId,
    required String userId,
  }) async {
    // get lastReadAt
    String? lastReadAt;
    try {
      final rd = await _databases.getDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.messagesReadCollectionId,
        documentId: _readDocId(conversationId, userId),
      );
      lastReadAt = (rd.data['lastReadAt'] as String?) ?? '';
    } catch (_) {
      lastReadAt = null;
    }

    // Query messages newer than lastReadAt and not sent by user
    final queries = <String>[
      Query.equal('conversationId', [conversationId]),
      Query.notEqual('senderId', [userId]),
      Query.limit(100),
    ];
    if (lastReadAt != null && lastReadAt.isNotEmpty) {
      queries.add(Query.greaterThan(r'$createdAt', lastReadAt)); // system field
    }

    try {
      final docs = await _databases.listDocuments(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.messagesCollectionId,
        queries: queries,
      );
      return docs.total ?? docs.documents.length;
    } on AppwriteException catch (e) {
      print('⚠️ countUnreadForConversation error: ${e.message}');
      return 0;
    }
  }

  // Fetch public user information by ID (profiles + verifications)
  Future<PublicUser?> fetchPublicUserById(String userId) async {
    // 1) profiles (required; use defaults if missing)
    Document? profileDoc;
    try {
      profileDoc = await _databases.getDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.profilesCollectionId,
        documentId: userId,
      );
    } catch (_) {
      // Unknown user
      return null;
    }

    final p = profileDoc.data;
    final name = (p['name'] as String?) ?? 'User';
    final role = (p['role'] as String?) ?? 'client';
    final isVerified = (p['isVerified'] as bool?) ?? false;
    final email = p['email'] as String?;
    final phone = p['phone'] as String?;

    // 2) verifications (optional; may 404 if not created yet)
    String? avatarUrl;
    String? documentUrl;
    Map<String, String>? address;
    String? addressString;
    
    try {
      final vDoc = await _databases.getDocument(
        databaseId: AppwriteIds.databaseId,
        collectionId: AppwriteIds.verificationsCollectionId,
        documentId: userId, // we use userId as docId in prior steps
      );
      final v = vDoc.data;
      avatarUrl = (v['profileImageUrl'] as String?)?.trim();
      documentUrl = (v['documentUrl'] as String?)?.trim();

      // Extract address information
      final house = (v['houseNumber'] as String?)?.trim() ?? '';
      final street = (v['street'] as String?)?.trim() ?? '';
      final city = (v['city'] as String?)?.trim() ?? '';
      final state = (v['state'] as String?)?.trim() ?? '';
      
      if ([house, street, city, state].any((e) => e.isNotEmpty)) {
        address = {
          'houseNumber': house,
          'street': street,
          'city': city,
          'state': state,
        };
        addressString = [
          if (house.isNotEmpty || street.isNotEmpty) '$house $street'.trim(),
          if (city.isNotEmpty) city,
          if (state.isNotEmpty) state,
        ].where((e) => e.isNotEmpty).join(', ');
      }
    } catch (_) {
      // not verified yet or no verification doc
    }

    return PublicUser(
      id: userId,
      name: name,
      role: role,
      isVerified: isVerified,
      avatarUrl: (avatarUrl?.isNotEmpty ?? false) ? avatarUrl : null,
      documentUrl: (documentUrl?.isNotEmpty ?? false) ? documentUrl : null,
      email: email,
      phone: phone,
      address: address,
      addressString: addressString,
    );
  }
}
