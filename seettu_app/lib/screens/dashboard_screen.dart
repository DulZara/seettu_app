import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bind these to real data
    const String userName = 'John Doe';
    const int activeCount = 2;
    const int completedCount = 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const SizedBox(height: 8),

          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, size: 48, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Center(
            child: Text(
              userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),

          // Stats card (two columns)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Active Seettu',
                    value: activeCount.toString(),
                    rightDivider: true,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: 'Completed Seettu',
                    value: completedCount.toString(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Two "My Groups" buttons (both go to /groups)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/groups'),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('My Seettu'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/groups'),
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('My Groups'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Verification button
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: () {
                // TODO: navigate to your Verification screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Go to Verification screen')),
                );
              },
              child: const Text(
                'Verification',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool rightDivider;
  const _StatTile({
    required this.label,
    required this.value,
    this.rightDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      fontWeight: FontWeight.w600,
    );
    final valueStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: rightDivider
            ? Border(
                right: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.6),
                  width: 0.75,
                ),
              )
            : null,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
