import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/api_service.dart';
import 'import_export_status_screen.dart';
import '../../utils/import_export_history_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/error_handler.dart';

class ImportExportDialog extends StatefulWidget {
  const ImportExportDialog({super.key});

  @override
  State<ImportExportDialog> createState() => _ImportExportDialogState();
}

class _ImportExportDialogState extends State<ImportExportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isApiHealthy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkApiHealth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkApiHealth() async {
    try {
      // Simple health check by trying to get categories
      await _apiService.getCategories();
      setState(() {
        _isApiHealthy = true;
        _statusMessage = 'Koneksi API sehat. Siap untuk operasi import/export.';
      });
    } catch (e) {
      setState(() {
        _isApiHealthy = false;
        _statusMessage =
            'Koneksi API bermasalah. Periksa jaringan atau login ulang.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.import_export, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Import & Export Data Buku',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // API Health Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _isApiHealthy ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isApiHealthy
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isApiHealthy ? Icons.check_circle : Icons.error,
                    color: _isApiHealthy ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isApiHealthy
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkApiHealth,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade700,
              tabs: const [
                Tab(
                  icon: Icon(Icons.download),
                  text: 'Export Data',
                ),
                Tab(
                  icon: Icon(Icons.upload),
                  text: 'Import Data',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExportTab(),
                  _buildImportTab(),
                ],
              ),
            ),

            // History Button
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ImportExportStatusScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Lihat Riwayat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Download data buku dalam format Excel atau PDF',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Export Options
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  title: 'Export ke Excel',
                  description: 'Download semua data buku dalam format .xlsx',
                  icon: Icons.table_chart,
                  color: Colors.green,
                  onPressed: _exportExcel,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildExportButton(
                  title: 'Export ke PDF',
                  description: 'Download laporan buku dalam format .pdf',
                  icon: Icons.picture_as_pdf,
                  color: Colors.red,
                  onPressed: _exportPDF,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Download Template
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Template Import',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Download template Excel kosong untuk panduan format import data buku.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Template'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload file Excel untuk menambahkan data buku secara massal',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Import Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Panduan Import',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Download template Excel terlebih dahulu\n'
                  '2. Isi data buku sesuai format template\n'
                  '3. Gunakan kategori ID yang valid:\n'
                  '   • 1: Islam, 6: Antologi, 7: Dongeng\n'
                  '   • 8: Biografi, 12: Karya Ilmiah, dll\n'
                  '4. Upload file Excel yang sudah diisi\n'
                  '5. Pastikan format data sudah benar',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Import Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _importExcel,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isLoading ? 'Mengimpor...' : 'Pilih File Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // File constraints
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Persyaratan File:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Format: .xlsx atau .xls\n'
                  '• Ukuran maksimal: 10MB\n'
                  '• Gunakan template yang disediakan',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Download'),
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getBookCount() async {
    try {
      final books = await _apiService.getBooks();
      return books.length;
    } catch (e) {
      return 0;
    }
  }

  void _exportExcel() async {
    if (!_isApiHealthy) {
      setState(() {
        _statusMessage =
            'Tidak dapat melakukan export. Periksa koneksi atau login ulang.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memproses export Excel...';
    });

    try {
      final downloadUrl = await _apiService.exportBooksToExcel();

      if (downloadUrl != null) {
        _downloadFile(downloadUrl, 'buku_export.xlsx');
        setState(() {
          _statusMessage = 'Export Excel berhasil! File sedang didownload...';
        });

        // Add to history
        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'excel',
          status: 'completed',
          fileName:
              'buku_export_${DateTime.now().toIso8601String().split('T')[0]}.xlsx',
          recordCount: await _getBookCount(),
          message: 'Export Excel berhasil',
        );
      } else {
        setState(() {
          _statusMessage = 'Gagal membuat file Excel. Silakan coba lagi.';
        });

        // Add failed operation to history
        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'excel',
          status: 'failed',
          fileName: 'buku_export_failed.xlsx',
          error: 'Gagal membuat file Excel',
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });

      // Add failed operation to history
      await ImportExportHistoryManager.addOperation(
        type: 'export',
        format: 'excel',
        status: 'failed',
        fileName: 'buku_export_error.xlsx',
        error: 'Error: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _exportPDF() async {
    if (!_isApiHealthy) {
      setState(() {
        _statusMessage =
            'Tidak dapat melakukan export. Periksa koneksi atau login ulang.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memproses export PDF...';
    });

    try {
      final downloadUrl = await _apiService.exportBooksToPdf();

      if (downloadUrl != null) {
        _downloadFile(downloadUrl, 'buku_export.pdf');
        setState(() {
          _statusMessage = 'Export PDF berhasil! File sedang didownload...';
        });

        // Add to history
        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'pdf',
          status: 'completed',
          fileName:
              'buku_export_${DateTime.now().toIso8601String().split('T')[0]}.pdf',
          recordCount: await _getBookCount(),
          message: 'Export PDF berhasil',
        );
      } else {
        setState(() {
          _statusMessage = 'Gagal membuat file PDF. Silakan coba lagi.';
        });

        // Add failed operation to history
        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'pdf',
          status: 'failed',
          fileName: 'buku_export_failed.pdf',
          error: 'Gagal membuat file PDF',
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });

      // Add failed operation to history
      await ImportExportHistoryManager.addOperation(
        type: 'export',
        format: 'pdf',
        status: 'failed',
        fileName: 'buku_export_error.pdf',
        error: 'Error: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _downloadTemplate() async {
    if (!_isApiHealthy) {
      setState(() {
        _statusMessage =
            'Tidak dapat mendownload template. Periksa koneksi atau login ulang.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memproses template Excel...';
    });

    try {
      final downloadUrl = await _apiService.downloadBookTemplate();

      if (downloadUrl != null) {
        _downloadFile(downloadUrl, 'template_buku_import.xlsx');
        setState(() {
          _statusMessage = 'Template Excel berhasil didownload!';
        });

        // Add to history
        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'excel',
          status: 'completed',
          fileName: 'template_buku_import.xlsx',
          recordCount: 0,
          message: 'Template Excel berhasil didownload',
        );
      } else {
        setState(() {
          _statusMessage = 'Gagal membuat template Excel. Silakan coba lagi.';
        });

        // Add failed operation to history
        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'excel',
          status: 'failed',
          fileName: 'template_download_failed.xlsx',
          error: 'Gagal mendownload template Excel',
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });

      // Add failed operation to history
      await ImportExportHistoryManager.addOperation(
        type: 'export',
        format: 'excel',
        status: 'failed',
        fileName: 'template_download_error.xlsx',
        error: 'Error: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _importExcel() async {
    if (!_isApiHealthy) {
      setState(() {
        _statusMessage =
            'Tidak dapat melakukan import. Periksa koneksi atau login ulang.';
      });
      return;
    }

    try {
      // Pick Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;

        setState(() {
          _isLoading = true;
          _statusMessage = 'Mengimpor data dari file: ${file.name}...';
        });

        // Validate file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          setState(() {
            _statusMessage = 'File terlalu besar. Maksimal 10MB.';
            _isLoading = false;
          });
          return;
        }

        // Call import API
        final importResult = await _apiService.importBooksFromExcel(
          file.bytes!,
          file.name,
        );

        if (importResult['success']) {
          setState(() {
            _statusMessage = 'Import berhasil! ${importResult['message']}';
          });

          // Add to history
          await ImportExportHistoryManager.addOperation(
            type: 'import',
            format: 'excel',
            status: 'completed',
            fileName: file.name,
            recordCount: importResult['recordCount'] ?? 0,
            message: importResult['message'] ?? 'Import berhasil',
          );

          // Show success dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Berhasil'),
                content: Text(importResult['message']),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close success dialog
                      Navigator.of(context).pop(); // Close import dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          setState(() {
            _statusMessage = 'Import gagal: ${importResult['message']}';
          });

          // Add failed operation to history
          await ImportExportHistoryManager.addOperation(
            type: 'import',
            format: 'excel',
            status: 'failed',
            fileName: file.name,
            error: importResult['message'] ?? 'Import gagal',
          );

          // Show detailed error dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Gagal'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Error: ${importResult['message']}'),
                    const SizedBox(height: 8),
                    const Text('Kemungkinan penyebab:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('• Kategori ID tidak exist di database'),
                    const Text('• Format file Excel tidak sesuai'),
                    const Text('• Data duplikasi kode buku'),
                    const Text('• Field wajib kosong'),
                    const SizedBox(height: 8),
                    const Text(
                        'Solusi: Periksa data Excel dan gunakan kategori ID yang valid.'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        setState(() {
          _statusMessage = 'Tidak ada file yang dipilih.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Terjadi kesalahan: $e';
      });

      // Add failed operation to history
      await ImportExportHistoryManager.addOperation(
        type: 'import',
        format: 'excel',
        status: 'failed',
        fileName: 'import_error.xlsx',
        error: 'Terjadi kesalahan: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _downloadFile(String url, String filename) async {
    try {
      final Uri downloadUri = Uri.parse(url);

      if (await canLaunchUrl(downloadUri)) {
        await launchUrl(
          downloadUri,
          mode: LaunchMode.externalApplication,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Download started! File $filename will be saved to your Downloads folder.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw 'Could not launch download URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendownload file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
