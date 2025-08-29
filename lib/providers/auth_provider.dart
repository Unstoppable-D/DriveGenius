import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/appwrite_constants.dart';
import '../services/appwrite_service.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AppwriteService _appwriteService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  AuthProvider({AppwriteService? appwriteService}) 
      : _appwriteService = appwriteService ?? AppwriteService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isNewUser = false;
  String? _userId;               // track which user the state belongs to
  bool _isVerified = false;      // user verification status
  String? _avatarUrl;            // from prefs.profileImageUrl
  String? _documentUrl;          // from prefs.documentUrl
  
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isClient => _user?.role == UserRole.client;
  bool get isDriver => _user?.role == UserRole.driver;
  bool get needsProfileSetup => _user != null && (_user!.role == UserRole.none || _user!.phone.isEmpty);
  bool get isNewUser => _isNewUser;
  String? get userId => _userId;
  bool get isVerified => _isVerified;
  String? get avatarUrl => _avatarUrl;
  String? get documentUrl => _documentUrl;

  /// Force sign out and clear all sessions
  /// This is useful for ensuring fresh start on app launch
  Future<void> forceSignOut() async {
    try {
      // Clear all Appwrite sessions
      await _appwriteService.deleteAllSessions();
      print('✅ All Appwrite sessions cleared');
    } catch (e) {
      print('⚠️ Could not clear Appwrite sessions: $e');
    }
    
    // Clear all provider state
    clearForLogout();
    
    // Clear local state
    _status = AuthStatus.unauthenticated;
    _user = null;
    _errorMessage = null;
    _isNewUser = false;
    
    // Clear secure storage
    await _secureStorage.deleteAll();
    print('✅ Local auth state cleared');
    
    notifyListeners();
  }

  /// Set user verification status
  void setVerified(bool verified) {
    _isVerified = verified;
    if (_user != null) {
      _user = _user!.copyWith(isVerified: verified);
    }
    notifyListeners();
    print('✅ User verification status updated: $verified');
  }

  /// Set profile image file ID
  void setProfileImageFileId(String? fileId) {
    if (_user != null) {
      _user = _user!.copyWith(profileImage: fileId);
      notifyListeners();
      print('✅ Profile image file ID updated: $fileId');
    }
  }

  void setAvatarUrl(String? url) {
    _avatarUrl = url;
    notifyListeners();
    print('✅ Avatar URL updated: $url');
  }

  void setDocumentUrl(String? url) {
    _documentUrl = url;
    notifyListeners();
    print('✅ Document URL updated: $url');
  }

  // Resets user-scoped, volatile UI fields to defaults
  void _resetVolatile() {
    _isVerified = false;
    _avatarUrl = null;
    _documentUrl = null;
    _address = null;
    _addressString = null;
    notifyListeners();
    print('✅ Volatile state reset to defaults');
  }

  // Call this after login/signup (when you know the new user id)
  Future<void> onAuthUserChanged({
    required String userId,
    required AppwriteService svc,
  }) async {
    if (_userId != userId) {
      print('🔄 Auth user changed from $_userId to $userId');
      _userId = userId;
      _resetVolatile();           // show defaults immediately
      
      // Ensure profile document exists for new user
      try {
        if (_user != null) {
          await svc.ensureProfileDoc(
            userId: userId,
            name: _user!.name,
            email: _user!.email,
            phone: _user!.phone,
            role: _user!.role.name,
          );
          print('✅ Profile document ensured for new user');
        }
      } catch (e) {
        print('⚠️ Could not ensure profile document: $e');
        // Don't fail auth for profile creation issues
      }
      
      await refreshPrefs(svc);    // then load fresh prefs for this user
    }
  }

  // Logout flow should clear everything
  void clearForLogout({bool silent = true}) {
    print('🚪 Clearing auth state for logout (silent: $silent)');
    _userId = null;
    _resetVolatile();
    if (!silent) notifyListeners();
  }

  // Address management
  Map<String, String>? _address; // {houseNumber, street, city, state}
  String? _addressString;

  Map<String, String>? get address => _address;
  
  String get addressDisplay =>
      _addressString ??
      (_address == null || _address!.values.every((v) => v.isEmpty)
          ? 'No address provided'
          : [
              _address!['houseNumber'] ?? '',
              _address!['street'] ?? '',
              _address!['city'] ?? '',
              _address!['state'] ?? '',
            ].where((e) => (e ?? '').isNotEmpty).join(', '));

  void setAddress({
    Map<String, String>? address,
    String? pretty,
  }) {
    _address = address;
    _addressString = pretty;
    notifyListeners();
  }

  /// Refresh user preferences from Appwrite
  Future<void> refreshPrefs(AppwriteService svc) async {
    try {
      final p = await svc.getPrefs();
      setAvatarUrl(p['profileImageUrl'] as String?);
      setDocumentUrl(p['documentUrl'] as String?);
      
      final addr = (p['address'] as Map?)?.cast<String, dynamic>();
      setAddress(
        address: addr == null
            ? null
            : addr.map((k, v) => MapEntry(k, (v as String?) ?? '')),
        pretty: p['addressString'] as String?,
      );
      
      final verified = p['isVerified'] as bool?;
      if (verified != null) setVerified(verified);
      
      print('✅ User preferences refreshed from Appwrite');
    } catch (e) {
      print('❌ Failed to refresh preferences: $e');
    }
  }

  /// Get profile image URL from preferences
  Future<String?> getProfileImageUrl() async {
    try {
      final prefs = await _appwriteService.getUserPrefs();
      final profileImageFileId = prefs['profileImageFileId'];
      if (profileImageFileId != null) {
        return _appwriteService.getFileUrl(
          bucketId: AppwriteIds.profileBucketId,
          fileId: profileImageFileId,
        );
      }
      return null;
    } catch (e) {
      print('⚠️ Could not get profile image URL: $e');
      return null;
    }
  }

  /// Get user address from preferences
  Future<Map<String, dynamic>?> getUserAddress() async {
    try {
      final prefs = await _appwriteService.getUserPrefs();
      return prefs['address'];
    } catch (e) {
      print('⚠️ Could not get user address: $e');
      return null;
    }
  }
  
  // Initialize auth state
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();
    
    try {
      // Check for existing session
      final sessionId = await _secureStorage.read(key: 'session_id');
      
      if (sessionId != null) {
        // Try to get current user
        final appwriteUser = await _appwriteService.getCurrentUser();
        await _loadUserProfile(appwriteUser.$id);
        _status = AuthStatus.authenticated;
        _isNewUser = false; // Mark as existing user when loading from session
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      // Clear invalid session
      await _secureStorage.delete(key: 'session_id');
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }
  
  // Load user profile from Appwrite
  Future<void> _loadUserProfile(String userId) async {
    try {
      print('🔍 Loading user profile for ID: $userId');
      
      // Get the user profile document from the profiles collection
      final document = await _appwriteService.getUserProfile(userId);
      print('✅ User profile loaded successfully');
      print('🔍 Profile data: ${document.data}');
      print('🔍 Role field value: ${document.data['role']}');
      print('🔍 Role field type: ${document.data['role']?.runtimeType}');
      
      // Create user object from the document
      _user = User.fromAppwriteDocument(document);
      print('👤 User role loaded: ${_user?.role.name}');
      
      // Verify that the role is properly set
      if (_user?.role == UserRole.none) {
        print('⚠️ WARNING: User role is "none" - this indicates a parsing issue!');
        print('🔍 Raw role value from database: ${document.data['role']}');
        
        // Try to manually parse the role as a fallback
        final rawRole = document.data['role'];
        if (rawRole != null && rawRole is String) {
          if (rawRole.toLowerCase() == 'driver') {
            print('🔄 Manually setting role to driver');
            _user = _user!.copyWith(role: UserRole.driver);
          } else if (rawRole.toLowerCase() == 'client') {
            print('🔄 Manually setting role to client');
            _user = _user!.copyWith(role: UserRole.client);
          }
        }
        
        print('👤 User role after manual fix: ${_user?.role.name}');
      }
      
    } catch (e) {
      print('❌ Error loading user profile: $e');
      
      // If profile doesn't exist, create one with default values
      if (e.toString().contains('not found') || e.toString().contains('document not found')) {
        print('🔄 Profile not found, creating default profile...');
        await _createDefaultProfile(userId);
      } else {
        // For other errors, try to get basic user info from auth
        try {
          print('🔄 Attempting to get basic user info from auth...');
          final appwriteUser = await _appwriteService.getCurrentUser();
          
          // Create a minimal user object with basic info
          _user = User(
            id: appwriteUser.$id,
            email: appwriteUser.email,
            name: appwriteUser.name,
            phone: '',
            role: UserRole.none, // Will be updated when profile is created
            isVerified: false,
            createdAt: DateTime.now(),
            authMethod: AuthMethod.appwrite,
          );
          
          print('⚠️ Created minimal user object. Profile needs to be set up.');
          _errorMessage = 'Profile incomplete. Please complete your profile setup.';
          
        } catch (profileError) {
          print('❌ Error getting basic user info: $profileError');
          _user = null;
          _errorMessage = 'Unable to load user information. Please try again.';
        }
      }
    }
  }

  // Create a default profile for users who don't have one
  Future<void> _createDefaultProfile(String userId) async {
    try {
      print('🔄 Creating default profile for user: $userId');
      
      // Get basic user info from auth
      final appwriteUser = await _appwriteService.getCurrentUser();
      
      // Create default profile data - only include required attributes
      final profileData = {
        'name': appwriteUser.name,
        'email': appwriteUser.email,
        'phone': '',
        'role': UserRole.client.name, // Default to client role
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      print('📝 Profile data to create: $profileData');
      
      // Create the profile in the database with proper permissions
      await _appwriteService.createUserProfile(
        userId: userId,
        profileData: profileData,
      );
      
      print('✅ Default profile created successfully');
      
      // Reload the profile
      await _loadUserProfile(userId);
      
    } catch (e) {
      print('❌ Error creating default profile: $e');
      
      // Provide specific error messages for common issues
      if (e.toString().contains('user_unauthorized') || e.toString().contains('permission denied')) {
        _errorMessage = 'Permission error: Unable to create profile. Please check your authentication status.';
      } else if (e.toString().contains('Permissions must be one of: (any, guests)')) {
        _errorMessage = 'Permission configuration error: Your Appwrite collection needs to be updated to use document-level permissions. See APPWRITE_PERMISSIONS_FIX.md for instructions.';
      } else if (e.toString().contains('collection not found')) {
        _errorMessage = 'Database configuration error: Profiles collection not found. Please contact support.';
      } else if (e.toString().contains('database not found')) {
        _errorMessage = 'Database configuration error: Database not found. Please contact support.';
      } else {
        _errorMessage = 'Error creating user profile: $e';
      }
      
      notifyListeners();
    }
  }
  
  // Save session ID securely
  Future<void> _saveSession(String sessionId) async {
    await _secureStorage.write(key: 'session_id', value: sessionId);
  }
  
  // Clear existing sessions
  Future<void> _clearExistingSessions() async {
    try {
      final sessionId = await _secureStorage.read(key: 'session_id');
      if (sessionId != null) {
        await _appwriteService.deleteSession(sessionId);
        await _secureStorage.delete(key: 'session_id');
      }
    } catch (e) {
      // Ignore errors when clearing sessions
      print('Warning: Could not clear existing session: $e');
    }
  }
  
  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Clear any existing sessions first
      await _clearExistingSessions();
      
      // Create Appwrite account
      final appwriteUser = await _appwriteService.createAccount(
        email: email,
        password: password,
        name: name,
      );
      
      // Create user profile in database
      try {
        print('🔐 Signup Debug: Creating profile with role: ${role.name}');
        
        // Only include the required attributes that match your Appwrite collection schema
        final profileData = {
          'name': name,
          'email': email,
          'phone': phone,
          'role': role.name,
          'isVerified': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        print('🔐 Signup Debug: Profile data: $profileData');
        print('🔐 Signup Debug: Schema validation - only sending required attributes');
        
        await _appwriteService.createUserProfile(
          userId: appwriteUser.$id,
          profileData: profileData,
        );
        print('✅ User profile created successfully');
      } catch (profileError) {
        print('❌ Error creating user profile: $profileError');
        
        // Check for specific error types and provide guidance
        if (profileError.toString().contains('document_invalid_structure')) {
          print('⚠️ Schema validation error detected:');
          print('   This usually means your Appwrite collection has different required attributes');
          print('   Expected schema: name, email, phone, role, isVerified, createdAt, updatedAt');
          print('   Check your Appwrite collection attributes and make sure they match exactly');
          print('   Remove any required attributes that are not in the expected schema');
        } else if (profileError.toString().contains('user_unauthorized') || 
            profileError.toString().contains('Permissions must be one of: (any, guests)')) {
          print('⚠️ Permission issue detected. This usually means:');
          print('   1. Collection is using collection-level permissions instead of document-level');
          print('   2. Collection permissions are not set to allow authenticated users to create documents');
          print('   See APPWRITE_PERMISSIONS_FIX.md for detailed instructions');
        } else {
          print('⚠️ Other error: $profileError');
        }
        
        // Continue with signup but log the error
        // The profile can be created later or the user can be guided to fix the issue
      }
      
      // Wait a moment for account to be fully processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create session after account creation
      final session = await _appwriteService.createEmailSession(
        email: email,
        password: password,
      );
      
      // Save session ID
      await _saveSession(session.$id);
      
      // Create user object
      _user = User(
        id: appwriteUser.$id,
        email: email,
        name: name,
        phone: phone,
        role: role,
        isVerified: false,
        createdAt: DateTime.now(),
        authMethod: AuthMethod.appwrite,
      );
      
      // Reset provider state for new user and load preferences
      try {
        await onAuthUserChanged(
          userId: appwriteUser.$id,
          svc: _appwriteService,
        );
        print('✅ Auth provider state reset and preferences loaded for new user');
      } catch (e) {
        print('⚠️ Could not reset provider state: $e');
        // Don't fail signup for provider state issues
      }
      
      _status = AuthStatus.authenticated;
      _isNewUser = true; // Mark as new user after signup
      notifyListeners();
      return true;
      
    } catch (e) {
      _status = AuthStatus.error;
      
      // Handle specific error cases
      if (e.toString().contains('already exists')) {
        _errorMessage = 'An account with this email already exists. Please sign in instead.';
      } else {
        _errorMessage = e.toString();
      }
      
      notifyListeners();
      return false;
    }
  }
  
  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Clear any existing sessions first
      await _clearExistingSessions();
      
      // Create Appwrite session
      final session = await _appwriteService.createEmailSession(
        email: email,
        password: password,
      );
      
      // Save session ID
      await _saveSession(session.$id);
      
      // Get current user and profile
      final appwriteUser = await _appwriteService.getCurrentUser();
      print('🔐 Login Debug: Appwrite user ID: ${appwriteUser.$id}');
      
      await _loadUserProfile(appwriteUser.$id);
      print('🔐 Login Debug: Profile loaded, user role: ${_user?.role.name}');
      
      // Validate that we have a valid user object
      if (_user == null) {
        throw Exception('Failed to load user profile after authentication');
      }
      
      // Ensure user role is properly set
      await ensureUserRole();
      print('🔐 Login Debug: After role fix, user role: ${_user?.role.name}');
      
      // Final validation - ensure we have a valid role
      if (_user!.role == UserRole.none) {
        print('⚠️ WARNING: User role is still "none" after all attempts to fix it');
        print('🔄 Setting default role to client to prevent navigation issues');
        _user = _user!.copyWith(role: UserRole.client);
      }
      
      // Reset provider state for new user and load preferences
      try {
        await onAuthUserChanged(
          userId: appwriteUser.$id,
          svc: _appwriteService,
        );
        print('✅ Auth provider state reset and preferences loaded for new user');
      } catch (e) {
        print('⚠️ Could not reset provider state: $e');
        // Don't fail login for provider state issues
      }
      
      _status = AuthStatus.authenticated;
      _isNewUser = false; // Mark as existing user after login
      notifyListeners();
      return true;
      
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      print('❌ Login error: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      final sessionId = await _secureStorage.read(key: 'session_id');
      if (sessionId != null) {
        await _appwriteService.deleteSession(sessionId);
        await _secureStorage.delete(key: 'session_id');
      }
      
      // Clear all provider state
      clearForLogout();
      
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error signing out: $e';
      notifyListeners();
    }
  }
  
  // Helper function to automatically add updatedAt timestamp to profile updates
  Map<String, dynamic> _addUpdatedAt(Map<String, dynamic> updates) {
    return {
      ...updates,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create or update user profile
  Future<bool> createOrUpdateProfile({
    String? name,
    String? phone,
    UserRole? role,
    bool? isVerified,
    String? profileImage, // Note: This is stored locally but not sent to Appwrite
  }) async {
    if (_user == null) return false;
    
    try {
      // Only include attributes that are part of the Appwrite collection schema
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role.name;
      if (isVerified != null) updates['isVerified'] = isVerified;
      // Note: profileImage is not included in updates as it's not part of the Appwrite schema
      
      // Automatically add updatedAt timestamp to all profile updates
      final updatesWithTimestamp = _addUpdatedAt(updates);
      
      // Try to update existing profile first
      try {
        await _appwriteService.updateUserProfile(
          userId: _user!.id,
          updates: updatesWithTimestamp,
        );
      } catch (e) {
        // If profile doesn't exist, create it
        if (e.toString().contains('not found')) {
          await _appwriteService.createUserProfile(
            userId: _user!.id,
            profileData: {
              'name': _user!.name,
              'email': _user!.email,
              'phone': _user!.phone,
              'role': _user!.role.name,
              'isVerified': _user!.isVerified,
              'createdAt': _user!.createdAt.toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              ...updates,
            },
          );
        } else {
          rethrow;
        }
      }
      
      // Update local user object (including profileImage for local storage)
      _user = _user!.copyWith(
        name: name ?? _user!.name,
        phone: phone ?? _user!.phone,
        role: role ?? _user!.role,
        isVerified: isVerified ?? _user!.isVerified,
        profileImage: profileImage ?? _user!.profileImage,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating profile: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Update user profile (alias for backward compatibility)
  Future<bool> updateProfile({
    String? name,
    String? phone,
    UserRole? role,
    bool? isVerified,
    String? profileImage,
  }) async {
    return await createOrUpdateProfile(
      name: name,
      phone: phone,
      role: role,
      isVerified: isVerified,
      profileImage: profileImage,
    );
  }

  // Update verification status and reload user data
  Future<bool> updateVerificationStatus({
    required bool isVerified,
    String? profileImage,
    Map<String, dynamic>? addressJson,
    String? driverDocumentUrl,
    String? driverDocumentType,
  }) async {
    if (_user == null) return false;
    
    try {
      // Update the profile with verification status and new fields
      final updates = <String, dynamic>{
        'isVerified': isVerified,
      };
      
      if (profileImage != null) {
        updates['profileImage'] = profileImage;
      }
      
      if (addressJson != null) {
        updates['addressJson'] = addressJson;
      }
      
      if (driverDocumentUrl != null) {
        updates['driverDocumentUrl'] = driverDocumentUrl;
      }
      
      if (driverDocumentType != null) {
        updates['driverDocumentType'] = driverDocumentType;
      }
      
      // Automatically add updatedAt timestamp
      final updatesWithTimestamp = _addUpdatedAt(updates);
      
      // Update the profile in Appwrite
      await _appwriteService.updateUserProfile(
        userId: _user!.id,
        updates: updatesWithTimestamp,
      );
      
      // Update local user object with new fields
      _user = _user!.copyWith(
        isVerified: isVerified,
        profileImage: profileImage ?? _user!.profileImage,
        addressJson: addressJson?.toString() ?? _user!.addressJson,
        driverDocumentUrl: driverDocumentUrl ?? _user!.driverDocumentUrl,
        driverDocumentType: driverDocumentType != null
            ? DocumentType.values.firstWhere(
                (e) => e.name == driverDocumentType,
                orElse: () => DocumentType.license,
              )
            : _user!.driverDocumentType,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating verification status: $e';
      notifyListeners();
      return false;
    }
  }

  // Refresh user data from Appwrite
  Future<void> refreshUserData() async {
    if (_user == null) return;
    
    try {
      await _loadUserProfile(_user!.id);
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }
  
  // Complete profile setup for new users
  Future<bool> completeProfileSetup({
    required String phone,
    required UserRole role,
  }) async {
    if (_user == null) return false;
    
    try {
      // Update the profile with the correct schema
      final updates = <String, dynamic>{
        'phone': phone,
        'role': role.name,
      };
      
      // Automatically add updatedAt timestamp
      final updatesWithTimestamp = _addUpdatedAt(updates);
      
      try {
        await _appwriteService.updateUserProfile(
          userId: _user!.id,
          updates: updatesWithTimestamp,
        );
      } catch (e) {
        // If profile doesn't exist, create it with the complete schema
        if (e.toString().contains('not found')) {
          await _appwriteService.createUserProfile(
            userId: _user!.id,
            profileData: {
              'name': _user!.name,
              'email': _user!.email,
              'phone': phone,
              'role': role.name,
              'isVerified': _user!.isVerified,
              'createdAt': _user!.createdAt.toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
        } else {
          rethrow;
        }
      }
      
      // Update local user object
      _user = _user!.copyWith(
        phone: phone,
        role: role,
      );
      
      // Reload user profile to ensure all data is up to date
      await _loadUserProfile(_user!.id);
      
      return true;
    } catch (e) {
      _errorMessage = 'Error completing profile setup: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Set new user status
  void setNewUser(bool isNew) {
    _isNewUser = isNew;
    notifyListeners();
  }
  
  // Mark user as existing (after login)
  void markAsExistingUser() {
    _isNewUser = false;
    notifyListeners();
  }
  
  // Ensure user role is properly set (fallback for login issues)
  Future<void> ensureUserRole() async {
    if (_user != null && _user!.role == UserRole.none) {
      print('⚠️ User role is "none", attempting to fix...');
      
      try {
        // Try to reload the profile to get the correct role
        final document = await _appwriteService.getUserProfile(_user!.id);
        final updatedUser = User.fromAppwriteDocument(document);
        
        if (updatedUser.role != UserRole.none) {
          print('✅ User role fixed: ${updatedUser.role.name}');
          _user = updatedUser;
          notifyListeners();
        } else {
          print('❌ Could not fix user role, still "none"');
          
          // Try manual role detection from the raw document data
          final rawRole = document.data['role'];
          if (rawRole != null && rawRole is String) {
            final normalizedRole = rawRole.trim().toLowerCase();
            UserRole? detectedRole;
            
            if (normalizedRole == 'driver') {
              detectedRole = UserRole.driver;
            } else if (normalizedRole == 'client') {
              detectedRole = UserRole.client;
            }
            
            if (detectedRole != null) {
              print('🔄 Manually detected role: ${detectedRole.name}');
              _user = _user!.copyWith(role: detectedRole);
              notifyListeners();
            }
          }
        }
      } catch (e) {
        print('❌ Error fixing user role: $e');
        
        // If we can't fix the role, set a default to prevent navigation issues
        print('🔄 Setting default role to client to prevent navigation issues');
        _user = _user!.copyWith(role: UserRole.client);
        notifyListeners();
      }
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      // Note: Appwrite password recovery requires a web URL for the reset page
      // For now, we'll show a message that this feature needs to be configured
      _errorMessage = 'Password reset feature needs to be configured with a web reset URL.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error sending password reset email: $e';
      notifyListeners();
      return false;
    }
  }

  // Test Appwrite collection permissions to diagnose issues
  Future<Map<String, dynamic>> testPermissions() async {
    try {
      print('🔍 Testing Appwrite collection permissions...');
      
      final result = await _appwriteService.testCollectionPermissions();
      
      print('📊 Permission test result:');
      print('   Status: ${result['status']}');
      print('   Message: ${result['message']}');
      print('   Permission Type: ${result['permission_type']}');
      
      if (result['recommendation'] != null) {
        print('   Recommendation: ${result['recommendation']}');
      }
      
      return result;
      
    } catch (e) {
      print('❌ Error testing permissions: $e');
      return {
        'status': 'error',
        'message': 'Failed to test permissions: $e',
        'permission_type': 'unknown',
      };
    }
  }
}
