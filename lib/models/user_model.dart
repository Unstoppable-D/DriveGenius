enum UserRole { client, driver, none }
enum AuthMethod { appwrite, none }
enum DocumentType { license, nin }

class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final bool isVerified;
  final String? profileImage;

  final String? addressJson;
  final String? driverDocumentUrl;
  final DocumentType? driverDocumentType;
  final DateTime createdAt;
  final AuthMethod authMethod;
  
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.isVerified,
    this.profileImage,
    this.addressJson,
    this.driverDocumentUrl,
    this.driverDocumentType,
    required this.createdAt,
    required this.authMethod,
  });
  
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    bool? isVerified,
    String? profileImage,
    String? addressJson,
    String? driverDocumentUrl,
    DocumentType? driverDocumentType,
    DateTime? createdAt,
    AuthMethod? authMethod,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      profileImage: profileImage ?? this.profileImage,
      addressJson: addressJson ?? this.addressJson,
      driverDocumentUrl: driverDocumentUrl ?? this.driverDocumentUrl,
      driverDocumentType: driverDocumentType ?? this.driverDocumentType,
      createdAt: createdAt ?? this.createdAt,
      authMethod: authMethod ?? this.authMethod,
    );
  }
  
  // Convert User to Map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.name,
      'isVerified': isVerified,
      'profileImage': profileImage,

      'addressJson': addressJson,
      'driverDocumentUrl': driverDocumentUrl,
      'driverDocumentType': driverDocumentType?.name,
      'createdAt': createdAt.toIso8601String(),
      'authMethod': authMethod.name,
    };
  }
  
  // Create User from Appwrite Document
  factory User.fromAppwriteDocument(dynamic document) {
    final data = document.data;
    
    // Debug role parsing
    print('🔍 User.fromAppwriteDocument Debug:');
    print('  Document ID: ${document.$id}');
    print('  Raw role data: ${data['role']}');
    print('  Role type: ${data['role']?.runtimeType}');
    
    // Parse role with better error handling
    UserRole userRole;
    try {
      if (data['role'] == null) {
        print('  ⚠️ Role field is null');
        userRole = UserRole.none;
      } else if (data['role'] is String) {
        final roleString = data['role'] as String;
        print('  🔍 Looking for role: "$roleString"');
        
        // Normalize the role string (trim whitespace, convert to lowercase)
        final normalizedRole = roleString.trim().toLowerCase();
        print('  🔍 Normalized role: "$normalizedRole"');
        
        // Try to find the role in the enum
        userRole = UserRole.values.firstWhere(
          (e) => e.name.toLowerCase() == normalizedRole,
          orElse: () {
            print('  ❌ Role "$normalizedRole" not found in UserRole.values');
            print('  🔍 Available roles: ${UserRole.values.map((e) => e.name).toList()}');
            
            // Fallback: try to match partial strings
            if (normalizedRole.contains('driver') || normalizedRole.contains('drive')) {
              print('  🔄 Partial match found for driver');
              return UserRole.driver;
            } else if (normalizedRole.contains('client') || normalizedRole.contains('cust')) {
              print('  🔄 Partial match found for client');
              return UserRole.client;
            }
            
            return UserRole.none;
          },
        );
        print('  ✅ Role parsed successfully: ${userRole.name}');
      } else {
        print('  ❌ Role field is not a string: ${data['role']}');
        userRole = UserRole.none;
      }
    } catch (e) {
      print('  ❌ Error parsing role: $e');
      userRole = UserRole.none;
    }
    
    // Additional validation: ensure we have a valid role
    if (userRole == UserRole.none) {
      print('  ⚠️ Final role is still "none" - this may cause navigation issues');
    }
    
    return User(
      id: document.$id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: userRole,
      isVerified: data['isVerified'] ?? false,
      profileImage: data['profileImage'],
      
      addressJson: data['addressJson'],
      driverDocumentUrl: data['driverDocumentUrl'],
      driverDocumentType: _parseDocumentType(data['driverDocumentType']),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      authMethod: AuthMethod.appwrite,
    );
  }
  

  
  // Helper method to parse document type
  static DocumentType? _parseDocumentType(dynamic type) {
    if (type == null) return null;
    try {
      return DocumentType.values.firstWhere(
        (e) => e.name == type.toString().toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  // Create User from Map (for backward compatibility)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.none,
      ),
      isVerified: map['isVerified'] ?? false,
      profileImage: map['profileImage'],

      addressJson: map['addressJson'],
      driverDocumentUrl: map['driverDocumentUrl'],
      driverDocumentType: _parseDocumentType(map['driverDocumentType']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      authMethod: AuthMethod.values.firstWhere(
        (e) => e.name == map['authMethod'],
        orElse: () => AuthMethod.none,
      ),
    );
  }
}
