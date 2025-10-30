

import 'package:flutter/material.dart';

class AddMemberResult {
  final List<String> members; // only the extra members typed in the sheet
  final bool startNow;
  AddMemberResult({required this.members, required this.startNow});
}

class AddMembersSheet extends StatefulWidget {
  final String seettuName;
  final int maxExtraMembers; // planned_users - 1 (since current user is auto-added)

  const AddMembersSheet({
    super.key,
    required this.seettuName,
    required this.maxExtraMembers,
  });

  @override
  State<AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<AddMembersSheet> {
  final _controller = TextEditingController();
  final _members = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;

    if (_members.length >= widget.maxExtraMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum members reached (${widget.maxExtraMembers}). '
            'Organizer is already counted.',
          ),
        ),
      );
      return;
    }

    if (_members.contains(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already added')),
      );
      return;
    }

    setState(() {
      _members.add(v);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = const Radius.circular(28);
    final remaining = widget.maxExtraMembers - _members.length;

    return ClipRRect(
      borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    Text('Add Members – ${widget.seettuName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'You can add up to ${widget.maxExtraMembers} more member(s). '
                  'Organizer is already counted.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                // Input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: remaining > 0
                              ? 'Phone or name (remaining $remaining)'
                              : 'Member limit reached',
                          border: const OutlineInputBorder(),
                        ),
                        enabled: remaining > 0,
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: remaining > 0 ? _add : null, child: const Text('Add')),
                  ],
                ),
                const SizedBox(height: 12),

                // Pills list
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _members
                        .map(
                          (m) => Chip(
                            label: Text(m),
                            onDeleted: () => setState(() => _members.remove(m)),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Start Seettu
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        AddMemberResult(members: _members, startNow: true),
                      );
                    },
                    child: const Text(
                      'Start Seettu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
