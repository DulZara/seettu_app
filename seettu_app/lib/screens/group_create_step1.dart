import 'package:flutter/material.dart';

class GroupCreateStep1 extends StatefulWidget {
  const GroupCreateStep1({super.key});

  @override
  State<GroupCreateStep1> createState() => _GroupCreateStep1State();
}

class _GroupCreateStep1State extends State<GroupCreateStep1> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  String _frequency = 'MONTHLY';
  DateTime _start = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group – Basics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(
                  labelText: 'Contribution amount (LKR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 100) return 'Min Rs. 100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                items: const [
                  DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                  DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                  DropdownMenuItem(value: 'BIWEEKLY', child: Text('Bi-weekly')),
                  DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                ],
                onChanged: (v) => setState(() => _frequency = v!),
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start date'),
                subtitle: Text('${_start.toLocal()}'.split(' ').first),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _start = d);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: save to state and navigate to Step 2 (rotation mode)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Step 1 OK – next: Rotation Mode'),
                        ),
                      );
                    }
                  },
                  child: const Text('Continue → Rotation Mode'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
