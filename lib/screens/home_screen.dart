import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/survey_entry.dart';
import '../services/survey_repository.dart';
import '../theme.dart';
import '../widgets/survey_card.dart';
import 'add_edit_survey_screen.dart';
import 'survey_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final SurveyRepository repository;
  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SurveyEntry> _entries = [];
  bool _isOnline = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _watchConnectivity();
  }

  /// Khởi tạo ban đầu: Đọc dữ liệu Hive local trước, sau đó tải dữ liệu mới nhất từ Sheet về
  Future<void> _initialLoad() async {
    _refresh();

    final results = await Connectivity().checkConnectivity();
    final online = !results.contains(ConnectivityResult.none);

    if (mounted) {
      setState(() => _isOnline = online);
    }

    if (online) {
      await _fetchDataFromSheets();
    }
  }

  /// Tải toàn bộ dữ liệu từ Google Sheets về Hive
  Future<void> _fetchDataFromSheets() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    await widget.repository.fetchFromGoogleSheets();
    _refresh();

    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  /// Lắng nghe trạng thái kết nối mạng
  Future<void> _watchConnectivity() async {
    Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() => _isOnline = online);
      }
    });
  }

  /// Làm mới lại dữ liệu từ Hive
  void _refresh() {
    if (mounted) {
      setState(() {
        _entries = widget.repository.getAll();
      });
    }
  }

  /// Mở màn hình tạo phiếu mới
  Future<void> _openAddScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditSurveyScreen(repository: widget.repository),
      ),
    );
    if (created == true) _refresh();
  }

  /// Xóa phiếu khảo sát
  Future<void> _deleteEntry(SurveyEntry entry) async {
    await widget.repository.delete(entry.id);
    _refresh();
  }

  /// Thực hiện đồng bộ: Đẩy dữ liệu Pending lên Sheet, sau đó tải lại toàn bộ danh sách mới nhất về
  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    // 1. Đẩy các phiếu chờ đồng bộ lên Google Sheet
    final syncedCount = await widget.repository.syncPending();

    // 2. Kéo toàn bộ dữ liệu mới nhất trên Sheet về
    await widget.repository.fetchFromGoogleSheets();
    _refresh();

    if (!mounted) return;
    setState(() => _isSyncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          syncedCount == 0
              ? 'Đã cập nhật dữ liệu từ Google Sheet!'
              : 'Đã đồng bộ thành công $syncedCount phiếu!',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  /// Điều hướng sang màn hình Chi tiết
  void _openDetailScreen(SurveyEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyDetailScreen(entry: entry),
      ),
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
            tooltip: _isOnline
                ? 'Đang trực tuyến'
                : 'Ngoại tuyến — dữ liệu vẫn được lưu cục bộ',
            icon: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: _isOnline ? Colors.greenAccent : Colors.orangeAccent,
            ),
            onPressed: null,
          ),
          IconButton(
            tooltip: 'Đồng bộ & Tải lại dữ liệu',
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Badge(
                    label: Text('$pending'),
                    isLabelVisible: pending > 0,
                    child: const Icon(Icons.sync),
                  ),
            onPressed: (_isOnline && !_isSyncing) ? _syncNow : null,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _isOnline ? _fetchDataFromSheets : () async {},
        child: _entries.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fact_check_outlined,
                                size: 64, color: VkuColors.blue),
                            const SizedBox(height: 12),
                            const Text(
                              'Chưa có phiếu khảo sát nào',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bấm "+" để tạo phiếu kiểm tra mới.\nDữ liệu trên Sheet sẽ được tự động tải về khi có mạng.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _entries.length,
                itemBuilder: (context, i) => SurveyCard(
                  entry: _entries[i],
                  onDelete: () => _deleteEntry(_entries[i]),
                  onTap: () => _openDetailScreen(_entries[i]),
                ),
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
