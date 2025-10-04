import 'package:flutter/material.dart';

enum RotationMode { joinOrder, autoOrder, manual }

class NewSeettuResult {
  final String name;
  final RotationMode mode;
  final int users;
  final int amount;
  NewSeettuResult({
    required this.name,
    required this.mode,
    required this.users,
    required this.amount,
  });
}

class NewSeettuSheet extends StatefulWidget {
  const NewSeettuSheet({super.key});
  @override
  State<NewSeettuSheet> createState() => _NewSeettuSheetState();
}

class _NewSeettuSheetState extends State<NewSeettuSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _users = TextEditingController();
  final _amount = TextEditingController();
  RotationMode _mode = RotationMode.joinOrder;

  @override
  void dispose() {
    _name.dispose();
    _users.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = const Radius.circular(28);
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
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 60),
                      const Text(
                        'New Seettu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rotation Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _Segmented(
                    mode: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Number of Users',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _users,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 2 || n > 20) return 'Enter 2–20';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Contribution Amount',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'Rs ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 100) return 'Minimum Rs 100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pop(
                            NewSeettuResult(
                              name: _name.text.trim(),
                              mode: _mode,
                              users: int.parse(_users.text),
                              amount: int.parse(_amount.text),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final RotationMode mode;
  final ValueChanged<RotationMode> onChanged;
  const _Segmented({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected = [
      mode == RotationMode.joinOrder,
      mode == RotationMode.autoOrder,
      mode == RotationMode.manual,
    ];
    return ToggleButtons(
      isSelected: isSelected,
      onPressed: (i) => onChanged(
        [
          RotationMode.joinOrder,
          RotationMode.autoOrder,
          RotationMode.manual,
        ][i],
      ),
      borderRadius: BorderRadius.circular(12),
      constraints: const BoxConstraints(minHeight: 44, minWidth: 110),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Join Order'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Auto Order'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Manual'),
        ),
      ],
    );
  }
}
