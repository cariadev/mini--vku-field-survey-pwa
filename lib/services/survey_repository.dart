import 'package:hive_flutter/hive_flutter.dart';
import '../models/survey_entry.dart';

/// Wraps a Hive box that, on Flutter Web, is automatically backed by the
/// browser's IndexedDB. This gives the form true offline persistence:
/// entries survive page reloads and full network loss, and are queued
/// locally until the user chooses to "sync" (see [markAllSynced]).
class SurveyRepository {
  static const String boxName = 'vku_survey_entries';
  late Box<Map> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(boxName);
  }

  List<SurveyEntry> getAll() {
    return _box.values
        .map((m) => SurveyEntry.fromMap(m))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> add(SurveyEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  int get pendingCount =>
      _box.values.where((m) => (m['synced'] as bool? ?? false) == false).length;

  /// Simulates pushing queued offline entries to a backend once the device
  /// is back online. Replace the body with a real HTTP call (e.g. via
  /// package:http) pointed at your API when one is available.
  Future<int> syncPending() async {
    final pending = _box.keys.where((k) {
      final m = _box.get(k);
      return (m?['synced'] as bool? ?? false) == false;
    }).toList();

    for (final key in pending) {
      final m = Map<String, dynamic>.from(_box.get(key)!);
      m['synced'] = true;
      await _box.put(key, m);
    }
    return pending.length;
  }
}
