
import 'package:flutter/material.dart';
import 'session_record.dart';

class SessionHistoryCard extends StatelessWidget {
  final SessionRecord record;
  final VoidCallback onDelete;
  final VoidCallback onRecall;

  const SessionHistoryCard({
    required this.record,
    required this.onDelete,
    required this.onRecall,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: _buildLeading(),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        children: [_buildDetailsView()],
      ),
    );
  }

  // --- Helper Methods (Flatten the hierarchy) ---

  Widget _buildLeading() => CircleAvatar(
        backgroundColor: Colors.blueGrey[800],
        child: Text('${record.sessionIndex}', style: const TextStyle(color: Colors.white)),
      );

  Widget _buildTitle() => Row(
        children: [
          Text(((record.sessionType?.name) ?? "undefined").toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(record.lapTime ?? "--:--", style: const TextStyle(fontSize: 18, color: Colors.blue)),
        ],
      );

  Widget _buildSubtitle() => Text(
        "Cold: ${record.coldPressures.lf} | ${record.coldPressures.rf} Bar",
        style: const TextStyle(fontSize: 12),
      );

  Widget _buildDetailsView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.notes.isNotEmpty) ...[
            const Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(record.notes),
            const Divider(),
          ],
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onRecall,
          icon: const Icon(Icons.settings_backup_restore),
          label: const Text("Recall Setup"),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
      ],
    );
  }
}