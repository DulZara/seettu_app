class Seettu {
  final String id;
  final String name;
  final String rotationMode;
  final int amountLkr;
  final String frequency;
  final String status;
  final int updatedAt;
  final int currentIndex;
  final int nextDueAt;
  final int maxMembers; // ⬅ NEW

  Seettu({
    required this.id,
    required this.name,
    required this.rotationMode,
    required this.amountLkr,
    required this.frequency,
    required this.status,
    required this.updatedAt,
    required this.currentIndex,
    required this.nextDueAt,
    required this.maxMembers,
  });

  factory Seettu.fromMap(Map<String, dynamic> m) => Seettu(
    id: m['id'] as String,
    name: m['name'] as String,
    rotationMode: m['rotation_mode'] as String,
    amountLkr: m['amount_lkr'] as int,
    frequency: m['frequency'] as String,
    status: m['status'] as String,
    updatedAt: m['updated_at'] as int,
    currentIndex: m['current_index'] as int,
    nextDueAt: m['next_due_at'] as int,
    maxMembers: (m['max_members'] as int?) ?? 1, // backward-safe
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'rotation_mode': rotationMode,
    'amount_lkr': amountLkr,
    'frequency': frequency,
    'status': status,
    'updated_at': updatedAt,
    'current_index': currentIndex,
    'next_due_at': nextDueAt,
    'max_members': maxMembers,
  };
}
