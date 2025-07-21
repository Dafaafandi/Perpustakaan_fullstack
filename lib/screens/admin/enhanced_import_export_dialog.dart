import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/api_service.dart';
import 'import_export_status_screen.dart';
import '../../utils/import_export_history_manager.dart';
import '../../utils/error_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class EnhancedImportExportDialog extends StatefulWidget {
  const EnhancedImportExportDialog({super.key});

  @override
  State<EnhancedImportExportDialog> createState() =>
      _EnhancedImportExportDialogState();
}

class _EnhancedImportExportDialogState extends State<EnhancedImportExportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isApiHealthy = true;
  double _progress = 0.0;
  bool _showProgress = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

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
      setState(() {
        _isLoading = true;
        _statusMessage = 'Memeriksa koneksi API...';
      });

      await _apiService.getCategories();

      setState(() {
        _isApiHealthy = true;
        _statusMessage = 'Koneksi API sehat. Siap untuk operasi import/export.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isApiHealthy = false;
        _statusMessage =
            'Koneksi API bermasalah. Periksa jaringan atau login ulang.';
        _isLoading = false;
      });
    }
  }

  Future<void> _retryOperation(Future<void> Function() operation) async {
    if (_retryCount >= _maxRetries) {
      if (mounted) {
        ErrorHandler.showError(context,
            'Operasi gagal setelah $_maxRetries kali percobaan. Silakan coba lagi nanti.');
      }
      return;
    }

    _retryCount++;
    setState(() {
      _statusMessage =
          'Mencoba ulang... (Percobaan $_retryCount dari $_maxRetries)';
    });

    try {
      await operation();
      _retryCount = 0; // Reset retry count on success
    } catch (e) {
      if (_retryCount < _maxRetries) {
        await Future.delayed(
            Duration(seconds: _retryCount * 2)); // Exponential backoff
        await _retryOperation(operation);
      } else {
        if (mounted) {
          ErrorHandler.showError(context, 'Operasi gagal: ${e.toString()}');
        }
      }
    }
  }

  void _updateProgress(double progress) {
    setState(() {
      _progress = progress;
      _showProgress = progress > 0 && progress < 1;
    });
  }

  void _downloadFile(String url, String fileName) async {
    try {
      // Use url_launcher instead of dart:html for cross-platform compatibility
      final Uri downloadUri = Uri.parse(url);

      if (await canLaunchUrl(downloadUri)) {
        await launchUrl(
          downloadUri,
          mode: LaunchMode.externalApplication,
        );

        if (mounted) {
          ErrorHandler.showSuccess(
            context,
            'Download started! File $fileName will be saved to your Downloads folder.',
          );
        }
      } else {
        throw 'Could not launch download URL';
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
          context,
          'Gagal mendownload file: ${e.toString()}',
        );
      }
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
                const Icon(Icons.import_export, size: 28, color: Colors.indigo),
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
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isApiHealthy
                          ? 'API siap digunakan'
                          : 'API tidak tersedia',
                      style: TextStyle(
                        color: _isApiHealthy
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!_isApiHealthy)
                    TextButton(
                      onPressed: _checkApiHealth,
                      child: const Text('Coba Lagi'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress Bar
            if (_showProgress)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_isLoading) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Export Data', icon: Icon(Icons.download)),
                Tab(text: 'Import Data', icon: Icon(Icons.upload)),
              ],
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
            ),
            const SizedBox(height: 16),

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
                  onPressed: () => _retryOperation(_exportExcel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildExportButton(
                  title: 'Export ke PDF',
                  description: 'Download laporan buku dalam format .pdf',
                  icon: Icons.picture_as_pdf,
                  color: Colors.red,
                  onPressed: () => _retryOperation(_exportPDF),
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
                      'Template Import Excel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Download template Excel untuk import data buku baru',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _retryOperation(_downloadTemplate),
                    icon: const Icon(Icons.download),
                    label: const Text('Download Template'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
            'Upload file Excel untuk menambah data buku secara massal',
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
                    Icon(Icons.info, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Petunjuk Import',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Download template Excel terlebih dahulu\n'
                  '2. Isi data buku sesuai format template\n'
                  '3. Upload file Excel (.xlsx atau .xls)\n'
                  '4. Maksimal ukuran file: 10MB',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Import Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Pilih File Excel untuk Import',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Klik tombol di bawah untuk memilih file Excel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _retryOperation(_importExcel),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pilih File Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Export'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportExcel() async {
    if (!_isApiHealthy) {
      ErrorHandler.showError(context,
          'Tidak dapat melakukan export. Periksa koneksi atau login ulang.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memproses export Excel...';
    });

    _updateProgress(0.1);

    try {
      _updateProgress(0.3);
      final downloadUrl = await _apiService.exportBooksToExcel();
      _updateProgress(0.7);

      if (downloadUrl != null) {
        _downloadFile(downloadUrl, 'buku_export.xlsx');
        _updateProgress(1.0);

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

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Export Excel berhasil!');
        }
      } else {
        setState(() {
          _statusMessage = 'Gagal membuat file Excel. Silakan coba lagi.';
        });

        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'excel',
          status: 'failed',
          fileName: 'buku_export_failed.xlsx',
          error: 'Gagal membuat file Excel',
        );

        if (mounted) {
          ErrorHandler.showError(context, 'Gagal membuat file Excel');
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });

      await ImportExportHistoryManager.addOperation(
        type: 'export',
        format: 'excel',
        status: 'failed',
        fileName: 'buku_export_error.xlsx',
        error: 'Error: $e',
      );

      if (mounted) {
        ErrorHandler.showError(context, 'Export Excel gagal: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _updateProgress(0.0);
    }
  }

  Future<void> _exportPDF() async {
    if (!_isApiHealthy) {
      ErrorHandler.showError(context,
          'Tidak dapat melakukan export. Periksa koneksi atau login ulang.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memproses export PDF...';
    });

    _updateProgress(0.1);

    try {
      _updateProgress(0.3);
      final downloadUrl = await _apiService.exportBooksToPdf();
      _updateProgress(0.7);

      if (downloadUrl != null) {
        _downloadFile(downloadUrl, 'buku_export.pdf');
        _updateProgress(1.0);

        setState(() {
          _statusMessage = 'Export PDF berhasil! File sedang didownload...';
        });

        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'pdf',
          status: 'completed',
          fileName:
              'buku_export_${DateTime.now().toIso8601String().split('T')[0]}.pdf',
          recordCount: await _getBookCount(),
          message: 'Export PDF berhasil',
        );

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Export PDF berhasil!');
        }
      } else {
        setState(() {
          _statusMessage = 'Gagal membuat file PDF. Silakan coba lagi.';
        });

        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'pdf',
          status: 'failed',
          fileName: 'buku_export_failed.pdf',
          error: 'Gagal membuat file PDF',
        );

        if (mounted) {
          ErrorHandler.showError(context, 'Gagal membuat file PDF');
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });

      await ImportExportHistoryManager.addOperation(
        type: 'export',
        format: 'pdf',
        status: 'failed',
        fileName: 'buku_export_error.pdf',
        error: 'Error: $e',
      );

      if (mounted) {
        ErrorHandler.showError(context, 'Export PDF gagal: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _updateProgress(0.0);
    }
  }

  Future<void> _downloadTemplate() async {
    if (!_isApiHealthy) {
      ErrorHandler.showError(context,
          'Tidak dapat mendownload template. Periksa koneksi atau login ulang.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memproses template Excel...';
    });

    _updateProgress(0.1);

    try {
      _updateProgress(0.5);
      final downloadUrl = await _apiService.downloadBookTemplate();
      _updateProgress(0.8);

      if (downloadUrl != null) {
        _downloadFile(downloadUrl, 'template_buku_import.xlsx');
        _updateProgress(1.0);

        setState(() {
          _statusMessage = 'Template Excel berhasil didownload!';
        });

        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'excel',
          status: 'completed',
          fileName: 'template_buku_import.xlsx',
          recordCount: 0,
          message: 'Template Excel berhasil didownload',
        );

        if (mounted) {
          ErrorHandler.showSuccess(
              context, 'Template Excel berhasil didownload!');
        }
      } else {
        setState(() {
          _statusMessage =
              'Gagal mendownload template Excel. Silakan coba lagi.';
        });

        await ImportExportHistoryManager.addOperation(
          type: 'export',
          format: 'excel',
          status: 'failed',
          fileName: 'template_download_failed.xlsx',
          error: 'Gagal mendownload template Excel',
        );

        if (mounted) {
          ErrorHandler.showError(context, 'Gagal mendownload template Excel');
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });

      await ImportExportHistoryManager.addOperation(
        type: 'export',
        format: 'excel',
        status: 'failed',
        fileName: 'template_download_error.xlsx',
        error: 'Error: $e',
      );

      if (mounted) {
        ErrorHandler.showError(
            context, 'Download template gagal: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _updateProgress(0.0);
    }
  }

  Future<void> _importExcel() async {
    if (!_isApiHealthy) {
      ErrorHandler.showError(context,
          'Tidak dapat melakukan import. Periksa koneksi atau login ulang.');
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

        // Validate file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          ErrorHandler.showError(context, 'File terlalu besar. Maksimal 10MB.');
          return;
        }

        setState(() {
          _isLoading = true;
          _statusMessage = 'Mengimpor data dari file: ${file.name}...';
        });

        _updateProgress(0.1);

        // Call import API
        _updateProgress(0.3);
        final importResult = await _apiService.importBooksFromExcel(
          file.bytes!,
          file.name,
        );
        _updateProgress(0.8);

        if (importResult['success']) {
          _updateProgress(1.0);
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

          if (mounted) {
            ErrorHandler.showSuccess(context, 'Import berhasil!');

            // Show success dialog
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

          await ImportExportHistoryManager.addOperation(
            type: 'import',
            format: 'excel',
            status: 'failed',
            fileName: file.name,
            error: importResult['message'] ?? 'Import gagal',
          );

          if (mounted) {
            ErrorHandler.showError(
                context, 'Import gagal: ${importResult['message']}');
          }
        }
      } else {
        ErrorHandler.showError(context, 'Tidak ada file yang dipilih.');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saat import: $e';
      });

      if (mounted) {
        ErrorHandler.showError(context, 'Error saat import: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _updateProgress(0.0);
    }
  }

  Future<int> _getBookCount() async {
    try {
      final response = await _apiService.getBooks();
      return response.length;
    } catch (e) {
      return 0;
    }
  }
}
