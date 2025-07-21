import 'package:flutter/material.dart';
import '../../utils/import_export_history_manager.dart';

class ImportExportStatusScreen extends StatefulWidget {
  const ImportExportStatusScreen({super.key});

  @override
  State<ImportExportStatusScreen> createState() =>
      _ImportExportStatusScreenState();
}

class _ImportExportStatusScreenState extends State<ImportExportStatusScreen> {
  List<Map<String, dynamic>> _operations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOperationHistory();
  }

  Future<void> _loadOperationHistory() async {
    setState(() => _isLoading = true);

    try {
      _operations = await ImportExportHistoryManager.getHistory();
    } catch (e) {

      _operations = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus semua riwayat import/export?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ImportExportHistoryManager.clearHistory();
        setState(() {
          _operations = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Riwayat berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error menghapus riwayat: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportCount =
        _operations.where((op) => op['type'] == 'export').length;
    final importCount =
        _operations.where((op) => op['type'] == 'import').length;
    final successCount =
        _operations.where((op) => op['status'] == 'completed').length;
    final failedCount =
        _operations.where((op) => op['status'] == 'failed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Import/Export'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadOperationHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Riwayat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Export',
                          exportCount,
                          Colors.blue,
                          Icons.file_download,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Import',
                          importCount,
                          Colors.green,
                          Icons.file_upload,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Berhasil',
                          successCount,
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Gagal',
                          failedCount,
                          Colors.red,
                          Icons.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Operations List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Riwayat Operasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_operations.length} operasi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Operations List
                  Expanded(
                    child: _operations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada riwayat operasi',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lakukan operasi import/export untuk melihat riwayat',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _operations.length,
                            itemBuilder: (context, index) {
                              final operation = _operations[index];
                              return _buildOperationCard(operation);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
      String title, int value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationCard(Map<String, dynamic> operation) {
    final isExport = operation['type'] == 'export';
    final isCompleted = operation['status'] == 'completed';
    final timestamp = operation['timestamp'] as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Operation Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExport ? Colors.blue.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isExport ? Icons.file_download : Icons.file_upload,
                color: isExport ? Colors.blue : Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Operation Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isExport ? 'Export' : 'Import',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: operation['format'] == 'excel'
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          operation['format'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: operation['format'] == 'excel'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    operation['fileName'] ?? 'Unknown file',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  if (operation['message'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      operation['message'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (operation['error'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      operation['error'],
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status and Record Count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Berhasil' : 'Gagal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (isCompleted &&
                    operation['recordCount'] != null &&
                    operation['recordCount'] > 0)
                  Text(
                    '${operation['recordCount']} record',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
