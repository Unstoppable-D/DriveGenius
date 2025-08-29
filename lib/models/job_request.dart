class JobRequest {
  final String id;
  final String clientId;
  final String driverId;
  final String pickup;
  final String destination;
  final DateTime scheduledAt;
  final String? note;
  final String status;                // PENDING | ACCEPTED | REJECTED | CANCELLED
  final DateTime createdAt;

  // NEW: ETA and status timestamps
  final DateTime? estimatedPickupAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;

  JobRequest({
    required this.id,
    required this.clientId,
    required this.driverId,
    required this.pickup,
    required this.destination,
    required this.scheduledAt,
    this.note,
    required this.status,
    required this.createdAt,
    this.estimatedPickupAt,
    this.acceptedAt,
    this.rejectedAt,
  });

  factory JobRequest.fromMap(Map<String, dynamic> m) {
    DateTime? _tryParse(String? v) =>
        (v == null || v.isEmpty) ? null : DateTime.tryParse(v);

    return JobRequest(
      id: m[r'$id'] as String,
      clientId: m['clientId'] as String,
      driverId: m['driverId'] as String,
      pickup: m['pickup'] as String,
      destination: m['destination'] as String,
      scheduledAt: DateTime.parse(m['scheduledAt'] as String),
      note: (m['note'] as String?) ?? '',
      status: m['status'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
      estimatedPickupAt: _tryParse(m['estimatedPickupAt'] as String?),
      acceptedAt: _tryParse(m['acceptedAt'] as String?),
      rejectedAt: _tryParse(m['rejectedAt'] as String?),
    );
  }
}
