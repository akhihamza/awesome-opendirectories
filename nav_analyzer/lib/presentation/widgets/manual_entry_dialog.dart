import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/transaction_entry.dart';
import '../../core/utils/date_utils.dart';

/// Dialog for manually entering a transaction when PDF parsing fails.
class ManualEntryDialog extends StatefulWidget {
  final String? fundName;
  final List<String> fundNames;

  const ManualEntryDialog({
    super.key,
    this.fundName,
    this.fundNames = const [],
  });

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _fundName;
  TransactionType _type = TransactionType.additionalPurchase;
  final _netAmountController = TextEditingController();
  final _navController = TextEditingController();
  final _unitsController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fundName = widget.fundName ?? '';
  }

  @override
  void dispose() {
    _netAmountController.dispose();
    _navController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fund name
              if (widget.fundNames.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: widget.fundNames.contains(_fundName)
                      ? _fundName
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Fund Name',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.fundNames
                      .map((f) =>
                          DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _fundName = v ?? ''),
                )
              else
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Fund Name',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _fundName,
                  onChanged: (v) => _fundName = v,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),

              const SizedBox(height: 16),

              // Transaction type
              DropdownButtonFormField<TransactionType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  TransactionType.initialPurchase,
                  TransactionType.additionalPurchase,
                  TransactionType.conversionFrom,
                ]
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name
                              .replaceAllMapped(
                                RegExp(r'[A-Z]'),
                                (m) => ' ${m.group(0)}',
                              )
                              .trim()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),

              const SizedBox(height: 16),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Date: ${AppDateUtils.format(_date)}',
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
              ),

              const SizedBox(height: 8),

              // Net amount
              TextFormField(
                controller: _netAmountController,
                decoration: const InputDecoration(
                  labelText: 'Net Amount',
                  border: OutlineInputBorder(),
                  prefixText: 'PKR ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // NAV
              TextFormField(
                controller: _navController,
                decoration: const InputDecoration(
                  labelText: 'NAV',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Units
              TextFormField(
                controller: _unitsController,
                decoration: const InputDecoration(
                  labelText: 'Units',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_fundName.isEmpty) return;

    final netAmount = double.parse(_netAmountController.text);
    final nav = double.parse(_navController.text);
    final units = double.parse(_unitsController.text);

    final entry = TransactionEntry(
      fundName: _fundName,
      type: _type,
      grossAmount: netAmount,
      netAmount: netAmount,
      nav: nav,
      priceDate: _date,
      units: units,
      balance: units,
    );

    Navigator.of(context).pop(entry);
  }
}
