import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  final _inspectorNameCtrl = TextEditingController();
  final _facilityNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  FacilityCondition _condition = FacilityCondition.good;
  String? _photoBase64;
  bool _saving = false;
  bool _gettingLocation = false;

  int _cleanlinessRating = 5;
  int _safetyRating = 5;
  int _usabilityRating = 5;

  /// Lấy vị trí GPS (Hỗ trợ cơ chế tự động Fallback sang IP nếu Web bị lỗi/Timeout)
  /// Lấy vị trí GPS (Trên Web/Laptop nếu bị Timeout sẽ tự gán tọa độ ảo tạm thời)
  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);

    try {
      if (kIsWeb) {
        try {
          // Thử lấy GPS thực tế từ trình duyệt (Timeout 3 giây)
          Position pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 3),
            ),
          );
          if (!mounted) return;
          _locationCtrl.text =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        } catch (_) {
          // Laptop không lấy được GPS -> Điền tọa độ ảo tạm thời (Ví dụ: Trường VKU)
          if (!mounted) return;
          _locationCtrl.text = '15.97529, 108.25321 (Tọa độ ảo)';

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Đã sử dụng tọa độ thử nghiệm tạm thời cho Laptop.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Trên thiết bị Mobile (Android/iOS)
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw 'Dịch vụ định vị (GPS) chưa được bật trên thiết bị.';
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw 'Quyền truy cập vị trí bị từ chối.';
          }
        }

        Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );

        if (!mounted) return;
        _locationCtrl.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy vị trí: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

    final entry = SurveyEntry(
      id: const Uuid().v4(),
      inspectorName: _inspectorNameCtrl.text.trim(),
      facilityName: _facilityNameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      condition: _condition,
      notes: _notesCtrl.text.trim(),
      photoBase64: _photoBase64,
      createdAt: DateTime.now(),
      synced: false,
      cleanlinessRating: _cleanlinessRating,
      safetyRating: _safetyRating,
      usabilityRating: _usabilityRating,
    );

    await widget.repository.add(entry, isOnline: isOnline);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  Widget _buildRatingBar(
      String label, int currentRating, ValueChanged<int> onRatingChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Row(
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(starValue),
                child: Icon(
                  starValue <= currentRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 26,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inspectorNameCtrl.dispose();
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
              controller: _inspectorNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên người khảo sát *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facilityNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên cơ sở vật chất *',
                prefixIcon: Icon(Icons.apartment),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: 'Vị trí / Tọa độ GPS *',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: _gettingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, color: Colors.blue),
                  onPressed: _gettingLocation ? null : _getCurrentLocation,
                  tooltip: 'Lấy vị trí GPS hiện tại',
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FacilityCondition>(
              initialValue: _condition,
              decoration:
                  const InputDecoration(labelText: 'Tình trạng tổng quan'),
              items: FacilityCondition.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (c) =>
                  setState(() => _condition = c ?? FacilityCondition.good),
            ),
            const SizedBox(height: 16),
            const Text('Đánh giá tiêu chí',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildRatingBar('Độ sạch sẽ:', _cleanlinessRating,
                      (val) => setState(() => _cleanlinessRating = val)),
                  _buildRatingBar('Mức độ an toàn:', _safetyRating,
                      (val) => setState(() => _safetyRating = val)),
                  _buildRatingBar('Khả năng hoạt động:', _usabilityRating,
                      (val) => setState(() => _usabilityRating = val)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_photoBase64 == null
                  ? 'Đính kèm ảnh'
                  : 'Đã chọn ảnh — chọn lại'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu & Đồng bộ phiếu khảo sát'),
            ),
          ],
        ),
      ),
    );
  }
}
