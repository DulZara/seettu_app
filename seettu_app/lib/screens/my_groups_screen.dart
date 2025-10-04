import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/new_seettu_sheet.dart';
import '../widgets/add_members_sheet.dart';
import 'seettu_detail_screen.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});
  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final _active = <_SeettuItem>[
    _SeettuItem(
      id: 'a1',
      name: 'Seettu 1',
      role: 'Organizer',
      subtitle: 'Next due: May 5',
      amountPerCycle: 1000,
      frequency: 'Monthly',
      color: Colors.blue,
      status: SeettuStatus.active,
    ),
    _SeettuItem(
      id: 'a2',
      name: 'Friends Seettu',
      role: 'Member',
      subtitle: 'Next due: Apr · 30',
      amountPerCycle: 500,
      frequency: 'Biweekly',
      color: Colors.orange,
      status: SeettuStatus.active,
    ),
  ];

  final _completed = <_SeettuItem>[
    _SeettuItem(
      id: 'c1',
      name: 'Savings Club',
      role: 'Member',
      subtitle: 'Completed',
      amountPerCycle: 0,
      frequency: '',
      color: Colors.purple,
      status: SeettuStatus.completed,
    ),
  ];

  final _drafts = <_SeettuItem>[]; // New Seettu list

  Future<void> _openNewSeettuSheet() async {
    final result = await showModalBottomSheet<NewSeettuResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewSeettuSheet(),
    );

    if (result != null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _drafts.add(
          _SeettuItem(
            id: id,
            name: result.name,
            role: 'Organizer',
            subtitle: 'Draft • ${result.users} users • Rs ${result.amount}',
            amountPerCycle: result.amount,
            frequency: _modeToLabel(result.mode),
            color: Colors.teal,
            status: SeettuStatus.draft,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "${result.name}" in New Seettu')),
      );
    }
  }

  Future<void> _openAddMembers(_SeettuItem item) async {
    final res = await showModalBottomSheet<AddMemberResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMembersSheet(seettuName: item.name),
    );

    if (res != null && res.startNow) {
      // move draft -> active
      setState(() {
        _drafts.removeWhere((e) => e.id == item.id);
        _active.add(
          item.copyWith(
            status: SeettuStatus.active,
            subtitle: 'Members: ${res.members.length} • Next due: TBD',
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Started "${item.name}" with ${res.members.length} members',
          ),
        ),
      );
    }
  }

  static String _modeToLabel(RotationMode m) {
    switch (m) {
      case RotationMode.joinOrder:
        return 'Join Order';
      case RotationMode.autoOrder:
        return 'Auto Order';
      case RotationMode.manual:
        return 'Manual';
    }
  }

  void _openDetail(_SeettuItem s, {required bool isOrganizer}) {
    context.push(
      '/seettu/${s.id}',
      extra: SeettuDetailArgs(
        id: s.id,
        name: s.name,
        amountLkr: s.amountPerCycle,
        frequency: s.frequency.isEmpty ? 'Monthly' : s.frequency,
        nextDue: DateTime.now().add(const Duration(days: 10)),
        members: [
          MemberStatus('Amara Silva', true),
          MemberStatus('Nuwan Kumarasinghe', false),
          MemberStatus('Rajani Madushani', true),
          MemberStatus('Dinuka Jayasekara', false),
        ],
        isOrganizer: isOrganizer,
        pendingSync: isOrganizer ? 3 : 0,
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
        title: const Text(
          'My Seettu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Stats row
          Row(
            children: const [
              Expanded(
                child: _StatChip(title: '2', subtitle: 'Active count'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatChip(title: '1', subtitle: 'Completed'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _PillChip(title: 'Reliability', value: 'Clean'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // New Seettu (Drafts)
          if (_drafts.isNotEmpty) ...[
            const Text(
              'New Seettu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ..._drafts.map(
              (s) => _SeettuCard(item: s, onTap: () => _openAddMembers(s)),
            ),
            const SizedBox(height: 22),
          ],

          // Active Seettu
          const Text(
            'Active Seettu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ..._active.map(
            (s) => _SeettuCard(
              item: s,
              onTap: () => _openDetail(s, isOrganizer: s.role == 'Organizer'),
            ),
          ),
          const SizedBox(height: 22),

          // Completed Seettu
          const Text(
            'Completed Seettu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ..._completed.map(
            (s) => _SeettuCard(
              item: s,
              onTap: () => _openDetail(s, isOrganizer: false),
            ),
          ),

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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1C3B3A),
              ),
              onPressed: _openNewSeettuSheet,
              child: const Text('Create Seettu'),
            ),
          ),
        ),
      ),
    );
  }
}

enum SeettuStatus { draft, active, completed }

class _SeettuItem {
  final String id;
  final String name;
  final String role; // Organizer/Member
  final String subtitle; // Next due / Draft info
  final int amountPerCycle; // LKR
  final String frequency; // Weekly / Biweekly / Monthly
  final Color color;
  final SeettuStatus status;

  _SeettuItem({
    required this.id,
    required this.name,
    required this.role,
    required this.subtitle,
    required this.amountPerCycle,
    required this.frequency,
    required this.color,
    required this.status,
  });

  _SeettuItem copyWith({
    String? name,
    String? role,
    String? subtitle,
    int? amountPerCycle,
    String? frequency,
    Color? color,
    SeettuStatus? status,
  }) => _SeettuItem(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    subtitle: subtitle ?? this.subtitle,
    amountPerCycle: amountPerCycle ?? this.amountPerCycle,
    frequency: frequency ?? this.frequency,
    color: color ?? this.color,
    status: status ?? this.status,
  );
}

class _SeettuCard extends StatelessWidget {
  final _SeettuItem item;
  final VoidCallback? onTap;
  const _SeettuCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(
      context,
    ).colorScheme.outlineVariant.withOpacity(0.6);

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
            // leading colored dot
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // name + subtitle + amount/frequency
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.amountPerCycle <= 0
                        ? ''
                        : 'Rs ${_fmt(item.amountPerCycle)} / cycle',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // role + frequency
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.role,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.frequency,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
