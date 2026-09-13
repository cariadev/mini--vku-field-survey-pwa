import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/survey_entry.dart';
import '../services/survey_repository.dart';

class AddEditSurveyScreen extends StatefulWidget {
  final SurveyRepository repository;
  const AddEditSurveyScreen({super.key, required this.repository});

  @override
  State<AddEditSurveyScreen> createState() => _AddEditSurveyScreenState();
}

class _AddEditSurveyScreenState extends State<AddEditSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _facilityNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  FacilityCondition _condition = FacilityCondition.good;
  String? _photoBase64;
  bool _saving = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photoBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final entry = SurveyEntry(
      id: const Uuid().v4(),
      facilityName: _facilityNameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      condition: _condition,
      notes: _notesCtrl.text.trim(),
      photoBase64: _photoBase64,
      createdAt: DateTime.now(),
      synced: false,
    );

    // Writes straight to the local Hive/IndexedDB box — no network call,
    // so this succeeds even with zero connectivity.
    await widget.repository.add(entry);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _facilityNameCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phiếu khảo sát mới')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _facilityNameCtrl,
              decoration: const InputDecoration(labelText: 'Tên cơ sở vật chất *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Vị trí / Phòng *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FacilityCondition>(
              value: _condition,
              decoration: const InputDecoration(labelText: 'Tình trạng'),
              items: FacilityCondition.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (c) => setState(() => _condition = c ?? FacilityCondition.good),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_photoBase64 == null ? 'Đính kèm ảnh (tuỳ chọn)' : 'Đã chọn ảnh — chọn lại'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu phiếu khảo sát'),
            ),
          ],
        ),
      ),
    );
  }
}
