class SeettuMember {
  final String seettuId;
  final String userName;
  final int joinOrder;
  final String role; // "Organizer" | "Member"

  SeettuMember({
    required this.seettuId,
    required this.userName,
    required this.joinOrder,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'seettu_id': seettuId,
      'user_name': userName,
      'join_order': joinOrder,
      'role': role,
    };
  }

  factory SeettuMember.fromMap(Map<String, dynamic> map) {
    return SeettuMember(
      seettuId: map['seettu_id'] as String,
      userName: map['user_name'] as String,
      joinOrder: map['join_order'] as int,
      role: map['role'] as String,
    );
  }
}
