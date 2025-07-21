import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ImportExportHistoryManager {
  static const String _historyKey = 'import_export_history';

  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        return historyList
            .map((item) => {
                  ...Map<String, dynamic>.from(item),
                  'timestamp': DateTime.parse(item['timestamp']),
                })
            .toList()
          ..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      }
      return [];
    } catch (e) {

      return [];
    }
  }

  static Future<void> addOperation({
    required String type, // 'import' or 'export'
    required String format, // 'excel' or 'pdf'
    required String status, // 'completed' or 'failed'
    required String fileName,
    int recordCount = 0,
    String? error,
    String? message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operations = await getHistory();

      // Convert back to serializable format
      final serializableOperations = operations
          .map((op) => {
                ...op,
                'timestamp': op['timestamp'].toIso8601String(),
              })
          .toList();

      // Add new operation
      final newOperation = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': type,
        'format': format,
        'status': status,
        'fileName': fileName,
        'timestamp': DateTime.now().toIso8601String(),
        'recordCount': recordCount,
        if (error != null) 'error': error,
        if (message != null) 'message': message,
      };

      serializableOperations.insert(
          0, newOperation); // Add to beginning (newest first)

      // Keep only last 50 operations to prevent storage bloat
      if (serializableOperations.length > 50) {
        serializableOperations.removeRange(50, serializableOperations.length);
      }

      await prefs.setString(_historyKey, json.encode(serializableOperations));
    } catch (e) {

    }
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {

    }
  }
}
