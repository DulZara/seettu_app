import 'package:flutter/material.dart';

class SeettuDetailArgs {
  final String id;
  final String name;
  final int amountLkr;
  final String frequency; // Daily/Weekly/Biweekly/Monthly
  final DateTime nextDue;
  final List<MemberStatus> members;
  final bool isOrganizer;
  final int pendingSync; // offline queued ops

  SeettuDetailArgs({
    required this.id,
    required this.name,
    required this.amountLkr,
    required this.frequency,
    required this.nextDue,
    required this.members,
    required this.isOrganizer,
    this.pendingSync = 0,
  });
}

class MemberStatus {
  final String name;
  final bool paid;
  MemberStatus(this.name, this.paid);

  MemberStatus copyWith({String? name, bool? paid}) =>
      MemberStatus(name ?? this.name, paid ?? this.paid);
}

class SeettuDetailScreen extends StatefulWidget {
  final SeettuDetailArgs args;
  const SeettuDetailScreen({super.key, required this.args});

  @override
  State<SeettuDetailScreen> createState() => _SeettuDetailScreenState();
}

class _SeettuDetailScreenState extends State<SeettuDetailScreen> {
  late List<MemberStatus> _members;
  late bool _isOrganizer;
  late int _pending;

  @override
  void initState() {
    super.initState();
    _members = widget.args.members.map((e) => e).toList();
    _isOrganizer = widget.args.isOrganizer;
    _pending = widget.args.pendingSync;
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(',');
    }
    return b.toString();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final dueText = "${_month(a.nextDue.month)} ${a.nextDue.day}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seettu'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailBlock(
                  title: 'Next Contribution Due',
                  value: dueText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailBlock(
                  title: 'Frequency',
                  value: a.frequency,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DetailBlock(
                  title: 'Amount',
                  value: '${_fmt(a.amountLkr)} LKR',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),

          // Progress ring + initials
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progressPaid(),
                    strokeWidth: 8,
                  ),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    child: Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _members
                            .take(4)
                            .map(
                              (m) => CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade200,
                                child: Text(
                                  _initials(m.name),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Members
          ..._members.map((m) {
            if (_isOrganizer) {
              return _MemberToggleTile(
                name: m.name,
                value: m.paid,
                onChanged: (v) {
                  setState(() {
                    final idx = _members.indexWhere((x) => x.name == m.name);
                    _members[idx] = _members[idx].copyWith(paid: v);
                    _pending += 1; // queued offline mutation (placeholder)
                  });
                },
              );
            } else {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.name),
                trailing: Chip(
                  label: Text(m.paid ? 'Paid' : 'Due'),
                  backgroundColor: m.paid
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: m.paid
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
          }),

          const SizedBox(height: 16),

          if (_isOrganizer)
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _canMarkPayout()
                    ? () {
                        setState(() => _pending += 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payout marked for this cycle'),
                          ),
                        );
                      }
                    : null,
                child: const Text('Mark Payout'),
              ),
            ),

          if (_pending > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Offline syncing\n$_pending change(s) to be synced…',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canMarkPayout() => _members.isNotEmpty && _members.every((m) => m.paid);
  double _progressPaid() => _members.isEmpty
      ? 0
      : _members.where((m) => m.paid).length / _members.length;

  String _month(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(m - 1).clamp(0, 11)];
  }
}

class _DetailBlock extends StatelessWidget {
  final String title;
  final String value;
  final bool alignEnd;
  const _DetailBlock({
    required this.title,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      fontWeight: FontWeight.w600,
    );
    final valueStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        const SizedBox(height: 6),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _MemberToggleTile extends StatelessWidget {
  final String name;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MemberToggleTile({
    required this.name,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      value: value,
      onChanged: onChanged,
      secondary: const Text('Mark Paid'),
    );
  }
}
