import 'package:beltei_app/core/constants/lost_found_constants.dart';
import 'package:flutter/material.dart';

class BrowseFilters {
  const BrowseFilters({
    this.category,
    this.building,
    this.status,
    this.dateFrom,
    this.dateTo,
  });

  final String? category;
  final String? building;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get hasActive =>
      category != null ||
      building != null ||
      status != null ||
      dateFrom != null ||
      dateTo != null;
}

Future<BrowseFilters?> showBrowseFiltersSheet(
  BuildContext context, {
  required BrowseFilters initial,
}) {
  return showModalBottomSheet<BrowseFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _BrowseFiltersBody(initial: initial),
  );
}

class _BrowseFiltersBody extends StatefulWidget {
  const _BrowseFiltersBody({required this.initial});

  final BrowseFilters initial;

  @override
  State<_BrowseFiltersBody> createState() => _BrowseFiltersBodyState();
}

class _BrowseFiltersBodyState extends State<_BrowseFiltersBody> {
  String? _category;
  String? _building;
  String? _status;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _category = widget.initial.category;
    _building = widget.initial.building;
    _status = widget.initial.status;
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              ...LostFoundConstants.categories.map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(LostFoundConstants.categoryLabel[c] ?? c),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _building,
            decoration: const InputDecoration(labelText: 'Building'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              ...LostFoundConstants.campusBuildings.map(
                (b) => DropdownMenuItem(value: b, child: Text(b, maxLines: 2)),
              ),
            ],
            onChanged: (v) => setState(() => _building = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              ...LostFoundConstants.statusLabel.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('From date'),
            subtitle: Text(
              _dateFrom?.toLocal().toString().split(' ').first ?? 'Any',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateFrom ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateFrom = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('To date'),
            subtitle: Text(
              _dateTo?.toLocal().toString().split(' ').first ?? 'Any',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateTo ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateTo = picked);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  const BrowseFilters(),
                ),
                child: const Text('Clear'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  BrowseFilters(
                    category: _category,
                    building: _building,
                    status: _status,
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
