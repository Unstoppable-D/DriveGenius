class DriverProfile {
  final String id;        // documentId == accountId
  final String name;
  final bool isVerified;
  final String role;      // 'driver' | 'client'
  final String? phone;
  final String? avatarUrl; // may be null (fallback to initial)

  DriverProfile({
    required this.id,
    required this.name,
    required this.isVerified,
    required this.role,
    this.phone,
    this.avatarUrl,
  });
}
