class Contribution {
  final String id;          // uuid
  final String seettuId;
  final String memberName;
  final int amountLkr;
  final bool paid;
  final int? paidAt;        // epoch ms or null

  Contribution({
    required this.id,
    required this.seettuId,
    required this.memberName,
    required this.amountLkr,
    required this.paid,
    required this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seettu_id': seettuId,
      'member_name': memberName,
      'amount_lkr': amountLkr,
      'paid': paid ? 1 : 0,
      'paid_at': paidAt,
    };
  }

  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      id: map['id'] as String,
      seettuId: map['seettu_id'] as String,
      memberName: map['member_name'] as String,
      amountLkr: map['amount_lkr'] as int,
      paid: (map['paid'] as int) == 1,
      paidAt: map['paid_at'] as int?,
    );
  }
}
