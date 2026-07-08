import 'package:beltei_app/data/firebase/storage_upload_store.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:beltei_app/data/repositories/claims_repository.dart';
import 'package:beltei_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key, required this.item});

  final LostFoundItem item;

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final _message = TextEditingController();
  final _claims = Get.find<ClaimsRepository>();
  final _uploads = Get.find<StorageUploadStore>();
  final _proofUrls = <String>[];
  bool _loading = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final url = await _uploads.uploadImageFile(file, folder: 'claims');
      setState(() => _proofUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_message.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add more detail (at least 10 characters)')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _claims.submitClaim(
        itemId: widget.item.id,
        message: _message.text,
        proofImageUrls: _proofUrls,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim submitted successfully')),
      );
      Get.back(result: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit claim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'How can you prove this is yours / you found it?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add proof photo'),
            ),
            if (_proofUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _proofUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_proofUrls[i], width: 80, height: 80, fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Submit claim',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
