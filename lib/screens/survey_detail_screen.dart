import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/survey_entry.dart';
import '../theme.dart';

class SurveyDetailScreen extends StatelessWidget {
  final SurveyEntry entry;

  const SurveyDetailScreen({super.key, required this.entry});

  Color _conditionColor() {
    switch (entry.condition) {
      case FacilityCondition.good:
        return Colors.green;
      case FacilityCondition.needsRepair:
        return VkuColors.yellow;
      case FacilityCondition.damaged:
        return VkuColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khảo sát'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị hình ảnh khảo sát (nếu có)
            if (entry.photoBase64 != null)
              Container(
                width: double.infinity,
                height: 220,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: MemoryImage(base64Decode(entry.photoBase64!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Trạng thái đồng bộ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    entry.synced ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: entry.synced
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.synced ? Icons.cloud_done : Icons.cloud_off,
                    color: entry.synced
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.synced
                        ? 'Đã đồng bộ lên Server'
                        : 'Chờ đồng bộ (Đã lưu nội bộ IndexedDB)',
                    style: TextStyle(
                      color: entry.synced
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Thông tin chi tiết
            _buildDetailItem(
                'Hạng mục / Thiết bị', entry.facilityName, Icons.apartment),
            _buildDetailItem('Vị trí', entry.location, Icons.location_on),

            // Tình trạng
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: VkuColors.blue, size: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tình trạng',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _conditionColor().withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          entry.condition.label,
                          style: TextStyle(
                              color: _conditionColor(),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _buildDetailItem(
                'Ghi chú',
                entry.notes.isEmpty ? 'Không có ghi chú' : entry.notes,
                Icons.notes),
            _buildDetailItem('Thời gian tạo', dateStr, Icons.access_time),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: VkuColors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
