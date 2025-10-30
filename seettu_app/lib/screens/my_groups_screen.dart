import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/new_seettu_sheet.dart';
import '../widgets/add_members_sheet.dart';

import '../data/seettu_repository.dart';
import '../models/seettu.dart';
import 'seettu_detail_screen.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final _repo = SeettuRepository();
  static const String currentUserName = 'You'; // TODO: bind to FirebaseAuth later

  // UI models
  List<_SeettuItem> _drafts = [];
  List<_SeettuItem> _active = [];
  List<_SeettuItem> _completed = [];

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Color _colorForSeettu(String id) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.green,
      Colors.pink,
    ];
    final idx = id.hashCode.abs() % colors.length;
    return colors[idx];
  }

  SeettuStatus _statusFromString(String s) {
    switch (s) {
      case 'draft':
        return SeettuStatus.draft;
      case 'active':
        return SeettuStatus.active;
      case 'completed':
        return SeettuStatus.completed;
      default:
        return SeettuStatus.draft;
    }
  }

  String _formatDue(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  _SeettuItem _mapSeettuToItem(Seettu s) {
    final color = _colorForSeettu(s.id);

    String subtitle;
    if (s.status == 'draft') {
      subtitle = 'Draft';
    } else if (s.status == 'active') {
      subtitle = 'Next due: ${_formatDue(s.nextDueAt)}';
    } else {
      subtitle = 'Completed';
    }

    final role = s.status == 'completed' ? 'Member' : 'Organizer';

    return _SeettuItem(
      id: s.id,
      name: s.name,
      role: role,
      subtitle: subtitle,
      amountPerCycle: s.amountLkr,
      frequency: s.frequency,
      color: color,
      status: _statusFromString(s.status),
      maxMembers: s.maxMembers, // carry forward
    );
  }

  Future<void> _refreshAll() async {
    final drafts = await _repo.getSeettuByStatus('draft');
    final actives = await _repo.getSeettuByStatus('active');
    final dones = await _repo.getSeettuByStatus('completed');

    setState(() {
      _drafts = drafts.map(_mapSeettuToItem).toList();
      _active = actives.map(_mapSeettuToItem).toList();
      _completed = dones.map(_mapSeettuToItem).toList();
    });
  }

  // Step 1: create draft seettu
  // lib/screens/my_groups_screen.dart (inside _openNewSeettuSheet)
Future<void> _openNewSeettuSheet() async {
  final result = await showModalBottomSheet<NewSeettuResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NewSeettuSheet(),
  );

  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancelled creating Seettu')),
    );
    return;
  }

  if (result.name.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a name')),
    );
    return;
  }

  final rotationMode = switch (result.mode) {
    RotationMode.joinOrder => 'join',
    RotationMode.autoOrder => 'auto',
    RotationMode.manual => 'manual',
  };

  try {
    await _repo.createDraftSeettu(
      name: result.name.trim(),
      rotationMode: rotationMode,
      users: result.users,
      amount: result.amount,
      frequency: 'Monthly',
    );

    await _refreshAll();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "${result.name}"')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create: $e')),
      );
    }
  }
}


 Future<void> _openAddMembers(_SeettuItem item) async {
  // planned total (N) → you can add at most N-1 in the sheet
  final planned = await _repo.getPlannedUsers(item.id);
  final maxExtra = (planned - 1).clamp(0, 999);

  final res = await showModalBottomSheet<AddMemberResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddMembersSheet(
      seettuName: item.name,
      maxExtraMembers: maxExtra,
    ),
  );

  if (res == null || res.startNow == false) return;

  // Current signed-in user name (placeholder).
  // Replace 'You' with your auth displayName when you wire Firebase.
  const currentUserName = 'You';

  try {
    await _repo.addMembersAndActivate(
      seettuId: item.id,
      memberNames: res.members,
      currentUserName: currentUserName,
    );

    await _refreshAll();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Started "${item.name}" with ${planned} members planned '
            '(${res.members.length + 1} added incl. you).',
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start: $e')),
      );
    }
  }
}

  // View details of seettu
  void _openDetail(_SeettuItem s, {required bool isOrganizer}) {
    final nowPlusTen = DateTime.now().add(const Duration(days: 10)); // fallback only
    context.push(
      '/seettu/${s.id}',
      extra: SeettuDetailArgs(
        id: s.id,
        name: s.name,
        amountLkr: s.amountPerCycle,
        frequency: s.frequency.isEmpty ? 'Monthly' : s.frequency,
        nextDue: nowPlusTen,
        members: const [],
        isOrganizer: isOrganizer,
        pendingSync: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _active.length;
    final completedCount = _completed.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C3B3A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('My Seettu', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(child: _StatChip(title: '$activeCount', subtitle: 'Active count')),
              const SizedBox(width: 12),
              Expanded(child: _StatChip(title: '$completedCount', subtitle: 'Completed')),
              const SizedBox(width: 12),
              const Expanded(child: _PillChip(title: 'Reliability', value: 'Clean')),
            ],
          ),
          const SizedBox(height: 20),

          if (_drafts.isNotEmpty) ...[
            const Text('New Seettu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ..._drafts.map((s) => _SeettuCard(item: s, onTap: () => _openAddMembers(s))),
            const SizedBox(height: 22),
          ],

          const Text('Active Seettu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._active.map((s) => _SeettuCard(
                item: s,
                onTap: () => _openDetail(s, isOrganizer: s.role == 'Organizer'),
              )),
          const SizedBox(height: 22),

          const Text('Completed Seettu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._completed.map((s) => _SeettuCard(
                item: s,
                onTap: () => _openDetail(s, isOrganizer: false),
              )),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1C3B3A),
        onPressed: _openNewSeettuSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1C3B3A)),
              onPressed: _openNewSeettuSheet,
              child: const Text('Create Seettu'),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- UI helper classes --------------------

enum SeettuStatus { draft, active, completed }

class _SeettuItem {
  final String id;
  final String name;
  final String role; // Organizer/Member
  final String subtitle;
  final int amountPerCycle;
  final String frequency;
  final Color color;
  final SeettuStatus status;
  final int maxMembers; // NEW

  _SeettuItem({
    required this.id,
    required this.name,
    required this.role,
    required this.subtitle,
    required this.amountPerCycle,
    required this.frequency,
    required this.color,
    required this.status,
    required this.maxMembers,
  });

  _SeettuItem copyWith({
    String? name,
    String? role,
    String? subtitle,
    int? amountPerCycle,
    String? frequency,
    Color? color,
    SeettuStatus? status,
    int? maxMembers,
  }) {
    return _SeettuItem(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      subtitle: subtitle ?? this.subtitle,
      amountPerCycle: amountPerCycle ?? this.amountPerCycle,
      frequency: frequency ?? this.frequency,
      color: color ?? this.color,
      status: status ?? this.status,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }
}

class _SeettuCard extends StatelessWidget {
  final _SeettuItem item;
  final VoidCallback? onTap;
  const _SeettuCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outline, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: item.color.withOpacity(0.25), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Container(width: 14, height: 14, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  Text(
                    item.amountPerCycle <= 0 ? '' : 'Rs ${_fmt(item.amountPerCycle)} / cycle',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.role, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                const SizedBox(height: 8),
                Text(item.frequency, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class _StatChip extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StatChip({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6), width: 0.8),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String title;
  final String value;
  const _PillChip({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.primary.withOpacity(0.12);
    final fg = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6), width: 0.8),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );
  }
}
