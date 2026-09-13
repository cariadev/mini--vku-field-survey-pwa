import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/survey_entry.dart';
import '../theme.dart';

class SurveyCard extends StatelessWidget {
  final SurveyEntry entry;
  final VoidCallback onDelete;

  const SurveyCard({super.key, required this.entry, required this.onDelete});

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.photoBase64 != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(entry.photoBase64!),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: VkuColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apartment, color: VkuColors.blue),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.facilityName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _conditionColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          entry.condition.label,
                          style: TextStyle(color: _conditionColor(), fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(entry.location, style: TextStyle(color: Colors.grey.shade700)),
                  if (entry.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(entry.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        entry.synced ? Icons.cloud_done : Icons.cloud_off,
                        size: 14,
                        color: entry.synced ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.synced ? 'Đã đồng bộ' : 'Chờ đồng bộ',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
