import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/core/constants/lost_found_constants.dart';
import 'package:beltei_app/core/network/api_client.dart';
import 'package:beltei_app/data/repositories/items_repository.dart';
import 'package:beltei_app/screens/login_screen.dart';
import 'package:beltei_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key, this.initialType = 'LOST'});

  final String initialType;

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _repo = Get.find<ItemsRepository>();
  final _api = Get.find<ApiClient>();

  late String _type;
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _roomHint = TextEditingController();
  final _timeApprox = TextEditingController();
  final _reward = TextEditingController();
  final _color = TextEditingController();
  final _brand = TextEditingController();
  String _category = LostFoundConstants.categories.first;
  String _building = LostFoundConstants.campusBuildings.first;
  String? _foundDisposition;
  DateTime _eventDate = DateTime.now();
  final _imageUrls = <String>[];
  bool _notifyOnMatch = true;
  bool _allowContact = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _roomHint.dispose();
    _timeApprox.dispose();
    _reward.dispose();
    _color.dispose();
    _brand.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final url = await _api.uploadImageFile(file);
      setState(() => _imageUrls.add(url));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) {
      Get.to(() => const LoginScreen());
      return;
    }

    if (_title.text.trim().length < 3 ||
        _description.text.trim().length < 10 ||
        _roomHint.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }
    if (_type == 'LOST' && _timeApprox.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add approximate time for lost items')),
      );
      return;
    }
    if (_type == 'FOUND' && _foundDisposition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select where the item is now')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _repo.createItem({
        'type': _type,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'category': _category,
        'color': _color.text.trim(),
        'brand': _brand.text.trim(),
        'building': _building,
        'roomHint': _roomHint.text.trim(),
        'eventDate': _eventDate.toIso8601String(),
        'timeApprox': _type == 'LOST' ? _timeApprox.text.trim() : '',
        if (_type == 'FOUND') 'foundDisposition': _foundDisposition,
        'imageUrls': _imageUrls,
        'reward': _type == 'LOST' ? _reward.text.trim() : '',
        'notifyOnMatch': _notifyOnMatch,
        'allowContact': _allowContact,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing published')),
      );
      Get.back(result: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'LOST', label: Text('Lost')),
                ButtonSegment(value: 'FOUND', label: Text('Found')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _color,
              decoration: const InputDecoration(labelText: 'Color (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: LostFoundConstants.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(LostFoundConstants.categoryLabel[c] ?? c),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _building,
              decoration: const InputDecoration(labelText: 'Building'),
              items: LostFoundConstants.campusBuildings
                  .map((b) => DropdownMenuItem(value: b, child: Text(b, maxLines: 2)))
                  .toList(),
              onChanged: (v) => setState(() => _building = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomHint,
              decoration: const InputDecoration(labelText: 'Specific location *'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date lost / found'),
              subtitle: Text(_eventDate.toLocal().toString().split(' ').first),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _eventDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _eventDate = picked);
              },
            ),
            if (_type == 'LOST') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _timeApprox,
                decoration: const InputDecoration(labelText: 'Approximate time *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reward,
                decoration: const InputDecoration(labelText: 'Reward (optional)'),
              ),
            ],
            if (_type == 'FOUND') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _foundDisposition,
                decoration: const InputDecoration(labelText: 'Item disposition *'),
                items: LostFoundConstants.foundDispositions
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(LostFoundConstants.foundDispositionLabel[d] ?? d),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _foundDisposition = v),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading || _imageUrls.length >= 5 ? null : _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: Text('Photos (${_imageUrls.length}/5)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notify on match'),
              value: _notifyOnMatch,
              onChanged: (v) => setState(() => _notifyOnMatch = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow contact'),
              value: _allowContact,
              onChanged: (v) => setState(() => _allowContact = v),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Publish listing', loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
