import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/survey_entry.dart';

class SurveyRepository {
  final Box _box;

  // URL Google Apps Script Web App
  final String googleSheetsScriptUrl =
      'https://script.google.com/macros/s/AKfycbtc1NmBnSQzDVaY_WMoEPhxRnnZz1GL3nrYhLZgviSVkPvfFArXEmo4xSQqwg4nGN9LA/exec';

  SurveyRepository(this._box);

  /// Khởi tạo Box Hive
  static Future<SurveyRepository> init() async {
    final box = await Hive.openBox('survey_entries');
    return SurveyRepository(box);
  }

  /// Lấy danh sách phiếu khảo sát từ Hive Local (luôn hiển thị được dữ liệu)
  List<SurveyEntry> getAll() {
    try {
      return _box.values
          .map((e) => SurveyEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error parsing local data: $e');
      return [];
    }
  }

  /// Đếm số phiếu chưa đồng bộ
  int get pendingCount => getAll().where((e) => !e.synced).length;

  /// Kéo toàn bộ phiếu từ Google Sheet về (Có Timeout 5 giây để tránh treo App)
  Future<void> fetchFromGoogleSheets() async {
    try {
      final response = await http
          .get(Uri.parse(googleSheetsScriptUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 302) {
        final dynamic rawData = jsonDecode(response.body);

        if (rawData is List) {
          for (var item in rawData) {
            // Safe parse Condition Enum
            FacilityCondition conditionEnum = FacilityCondition.good;
            final conditionStr = item['condition']?.toString() ?? '';
            for (var c in FacilityCondition.values) {
              if (c.label.trim().toLowerCase() ==
                  conditionStr.trim().toLowerCase()) {
                conditionEnum = c;
                break;
              }
            }

            final entry = SurveyEntry(
              id: item['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              inspectorName: item['inspectorName']?.toString() ?? '',
              facilityName: item['facilityName']?.toString() ?? '',
              location: item['location']?.toString() ?? '',
              condition: conditionEnum,
              cleanlinessRating:
                  (item['cleanlinessRating'] as num?)?.toInt() ?? 3,
              safetyRating: (item['safetyRating'] as num?)?.toInt() ?? 3,
              usabilityRating: (item['usabilityRating'] as num?)?.toInt() ?? 3,
              notes: item['notes']?.toString() ?? '',
              createdAt:
                  DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
                      DateTime.now(),
              synced: true,
            );

            if (entry.id.isNotEmpty) {
              await _box.put(entry.id, entry.toMap());
            }
          }
        }
      }
    } catch (e) {
      print('Fetch Error or Timeout: $e');
    }
  }

  /// Thêm phiếu mới: Lưu vào Hive TRƯỚC, sau đó mới gửi lên Sheet
  Future<void> add(SurveyEntry entry, {bool isOnline = true}) async {
    // 1. Luôn lưu vào Hive trước với trạng thái chưa đồng bộ để màn hình hiển thị ngay lập tức
    await _box.put(entry.id, entry.toMap());

    // 2. Nếu đang Online thì tiến hành gửi lên Google Sheet
    if (isOnline) {
      bool success = await _uploadToGoogleSheets([entry]);
      if (success) {
        final updatedEntry = entry.copyWith(synced: true);
        await _box.put(updatedEntry.id, updatedEntry.toMap());
      }
    }
  }

  /// Xóa bản ghi
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Đồng bộ các phiếu chưa gửi
  Future<int> syncPending() async {
    final pendingEntries = getAll().where((e) => !e.synced).toList();
    if (pendingEntries.isEmpty) return 0;

    bool success = await _uploadToGoogleSheets(pendingEntries);
    if (success) {
      for (var entry in pendingEntries) {
        final updated = entry.copyWith(synced: true);
        await _box.put(updated.id, updated.toMap());
      }
      return pendingEntries.length;
    }
    return 0;
  }

  /// Đẩy dữ liệu lên Google Sheets
  Future<bool> _uploadToGoogleSheets(List<SurveyEntry> entries) async {
    if (entries.isEmpty) return false;

    try {
      final payload = entries
          .map((e) => {
                'id': e.id,
                'inspectorName': e.inspectorName,
                'facilityName': e.facilityName,
                'location': e.location,
                'condition': e.condition.label,
                'cleanlinessRating': e.cleanlinessRating,
                'safetyRating': e.safetyRating,
                'usabilityRating': e.usabilityRating,
                'notes': e.notes,
                'createdAt': e.createdAt.toIso8601String(),
              })
          .toList();

      await http
          .post(
            Uri.parse(googleSheetsScriptUrl),
            headers: {'Content-Type': 'text/plain;charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 7));

      return true;
    } catch (e) {
      print('Sync Upload Error: $e');
      return false;
    }
  }
}
