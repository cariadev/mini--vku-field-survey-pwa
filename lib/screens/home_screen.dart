import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/survey_entry.dart';
import '../services/survey_repository.dart';
import '../theme.dart';
import '../widgets/survey_card.dart';
import 'add_edit_survey_screen.dart';

class HomeScreen extends StatefulWidget {
  final SurveyRepository repository;
  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SurveyEntry> _entries = [];
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _watchConnectivity();
  }

  void _watchConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = online);
    });
    Connectivity().checkConnectivity().then((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = online);
    });
  }

  void _refresh() {
    setState(() => _entries = widget.repository.getAll());
  }

  Future<void> _openAddScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditSurveyScreen(repository: widget.repository),
      ),
    );
    if (created == true) _refresh();
  }

  Future<void> _deleteEntry(SurveyEntry entry) async {
    await widget.repository.delete(entry.id);
    _refresh();
  }

  Future<void> _syncNow() async {
    final synced = await widget.repository.syncPending();
    _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(synced == 0 ? 'Không có dữ liệu chờ đồng bộ' : 'Đã đồng bộ $synced bản ghi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.repository.pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VKU Field Survey'),
        actions: [
          IconButton(
            tooltip: _isOnline ? 'Đang trực tuyến' : 'Ngoại tuyến — dữ liệu vẫn được lưu cục bộ',
            icon: Icon(_isOnline ? Icons.wifi : Icons.wifi_off),
            onPressed: null,
          ),
          IconButton(
            tooltip: 'Đồng bộ dữ liệu đang chờ',
            icon: Badge(
              label: Text('$pending'),
              isLabelVisible: pending > 0,
              child: const Icon(Icons.sync),
            ),
            onPressed: _isOnline ? _syncNow : null,
          ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fact_check_outlined, size: 64, color: VkuColors.blue),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa có phiếu khảo sát nào',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bấm "+" để tạo phiếu kiểm tra cơ sở vật chất mới.\nDữ liệu được lưu ngay trên thiết bị, kể cả khi không có mạng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _entries.length,
              itemBuilder: (context, i) => SurveyCard(
                entry: _entries[i],
                onDelete: () => _deleteEntry(_entries[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddScreen,
        icon: const Icon(Icons.add),
        label: const Text('Phiếu mới'),
      ),
    );
  }
}
