class PublicUser {
  final String id;
  final String name;
  final String role;         // 'driver' | 'client'
  final bool isVerified;
  final String? avatarUrl;   // from verifications.profileImageUrl
  final String? documentUrl; // from verifications.documentUrl (driver only)
  final String? email;       // optional
  final String? phone;       // optional

  // NEW: Address fields from verifications
  final Map<String, String>? address; // {houseNumber, street, city, state}
  final String? addressString;        // "12 Main St, City, State"

  PublicUser({
    required this.id,
    required this.name,
    required this.role,
    required this.isVerified,
    this.avatarUrl,
    this.documentUrl,
    this.email,
    this.phone,
    this.address,
    this.addressString,
  });
}
