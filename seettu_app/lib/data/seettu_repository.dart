import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import 'local/app_db.dart';
import '../models/seettu.dart';
import '../models/member.dart';
import '../models/contribution.dart';

class SeettuRepository {
  final _uuid = const Uuid();

  // ---------- Query helpers ----------

  Future<Seettu> getSeettuById(String id) async {
    final Database db = await AppDb().db;
    final rows = await db.query(
      'seettu',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Seettu not found: $id');
    }
    return Seettu.fromMap(rows.first);
  }

  Future<List<Seettu>> getSeettuByStatus(String status) async {
    final Database db = await AppDb().db;
    final rows = await db.query(
      'seettu',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'updated_at DESC',
    );
    return rows.map((m) => Seettu.fromMap(m)).toList();
  }

  Future<List<SeettuMember>> getMembersForSeettu(String seettuId) async {
    final Database db = await AppDb().db;
    final rows = await db.query(
      'seettu_member',
      where: 'seettu_id = ?',
      whereArgs: [seettuId],
      orderBy: 'join_order ASC',
    );
    return rows
        .map((m) => SeettuMember(
              seettuId: m['seettu_id'] as String,
              userName: m['user_name'] as String,
              joinOrder: m['join_order'] as int,
              role: m['role'] as String,
            ))
        .toList();
  }

  Future<List<Contribution>> getContributionsForSeettu(String seettuId) async {
    final Database db = await AppDb().db;
    final rows = await db.query(
      'contribution',
      where: 'seettu_id = ?',
      whereArgs: [seettuId],
    );
    return rows.map((m) => Contribution.fromMap(m)).toList();
  }

  // ---------- Create / Activate ----------

  Future<String> createDraftSeettu({
  required String name,
  required String rotationMode,
  required int users,        // <-- planned total members
  required int amount,
  required String frequency,
}) async {
  final Database db = await AppDb().db;
  final id = _uuid.v4();
  final now = DateTime.now().millisecondsSinceEpoch;

  await db.insert('seettu', {
    'id': id,
    'name': name,
    'rotation_mode': rotationMode,
    'amount_lkr': amount,
    'frequency': frequency,
    'status': 'draft',
    'updated_at': now,
    'current_index': 0,
    'next_due_at': now,
    'planned_users': users,          // NEW
  });

  return id;
}

Future<int> getPlannedUsers(String seettuId) async {
  final db = await AppDb().db;
  final rows = await db.query('seettu',
      columns: ['planned_users'],
      where: 'id = ?',
      whereArgs: [seettuId],
      limit: 1);
  if (rows.isEmpty) throw StateError('Seettu not found: $seettuId');
  return rows.first['planned_users'] as int;
}

  /// Adds members (including organizer if not present), enforces max_members,
  /// deduplicates (case-insensitive), creates contributions, and activates.
  Future<void> addMembersAndActivate({
  required String seettuId,
  required List<String> memberNames,     // names typed in sheet (others)
  required String currentUserName,       // auto member (organizer)
}) async {
  final Database db = await AppDb().db;
  final now = DateTime.now().millisecondsSinceEpoch;

  // planned total
  final planned = await getPlannedUsers(seettuId);

  // build final unique list: current user + sheet members
  final all = <String>{currentUserName.trim()};
  for (final m in memberNames) {
    final v = m.trim();
    if (v.isNotEmpty) all.add(v);
  }
  if (all.length > planned) {
    throw StateError('Maximum $planned members allowed. You already added ${all.length}.');
  }

  // Insert members (ordered by join sequence); current user is organizer
  var order = 1;
  for (final m in all) {
    await db.insert('seettu_member', {
      'seettu_id': seettuId,
      'user_name': m,
      'join_order': order,
      'role': (m == currentUserName) ? 'Organizer' : 'Member',
    });
    order++;
  }

  // Amount/frequency & contributions
  final s = await getSeettuById(seettuId);
  for (final m in all) {
    await db.insert('contribution', {
      'id': _uuid.v4(),
      'seettu_id': seettuId,
      'member_name': m,
      'amount_lkr': s.amountLkr,
      'paid': 0,
      'paid_at': null,
    });
  }

  final dueAt = DateTime.now()
      .add(_frequencyToDuration(s.frequency))
      .millisecondsSinceEpoch;

  await db.update('seettu', {
    'status': 'active',
    'updated_at': now,
    'current_index': 0,
    'next_due_at': dueAt,
  }, where: 'id = ?', whereArgs: [seettuId]);
}

  // ---------- Mutations ----------

  Future<void> setContributionPaid({
    required String contributionId,
    required bool paid,
  }) async {
    final Database db = await AppDb().db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'contribution',
      {
        'paid': paid ? 1 : 0,
        'paid_at': paid ? now : null,
      },
      where: 'id = ?',
      whereArgs: [contributionId],
    );
  }

  /// Advance to next round if all contributions are paid.
  /// - Increments current_index (wraps around).
  /// - Moves next_due_at by the frequency duration from *now*.
  /// - Resets all contributions (paid=0, paid_at=null).
  /// Returns true if the cycle advanced, false if not all paid yet.
  Future<bool> advanceCycle(String seettuId) async {
    final Database db = await AppDb().db;

    // 1) Ensure all contributions are paid
    final rows = await db.query(
      'contribution',
      columns: ['paid'],
      where: 'seettu_id = ?',
      whereArgs: [seettuId],
    );
    if (rows.isEmpty) return false;
    final allPaid = rows.every((r) => (r['paid'] as int) == 1);
    if (!allPaid) return false;

    // 2) Load seettu & members
    final seettu = await getSeettuById(seettuId);
    final members = await getMembersForSeettu(seettuId);
    if (members.isEmpty) return false;

    // 3) Compute next index & next due
    final nextIndex = (seettu.currentIndex + 1) % members.length;
    final nextDueAt = DateTime.now()
        .add(_frequencyToDuration(seettu.frequency))
        .millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;

    // 4) Reset contributions for next round
    await db.update(
      'contribution',
      {
        'paid': 0,
        'paid_at': null,
      },
      where: 'seettu_id = ?',
      whereArgs: [seettuId],
    );

    // 5) Update seettu with new index + due date
    await db.update(
      'seettu',
      {
        'current_index': nextIndex,
        'next_due_at': nextDueAt,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [seettuId],
    );

    return true;
  }

  // ---------- Convenience ----------

  /// Returns the user name of the current taker (based on current_index).
  Future<String?> getCurrentPayerName(String seettuId) async {
    final s = await getSeettuById(seettuId);
    final members = await getMembersForSeettu(seettuId);
    if (members.isEmpty) return null;

    final idx = (s.currentIndex).clamp(0, members.length - 1);
    return members[idx].userName;
  }

  Duration _frequencyToDuration(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return const Duration(days: 7);
      case 'biweekly':
        return const Duration(days: 14);
      case 'monthly':
      default:
        return const Duration(days: 30);
    }
  }
}
