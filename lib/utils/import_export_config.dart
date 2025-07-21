/// Configuration for Import/Export operations
class ImportExportConfig {
  // File size limits
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxFileSizeMB = 10;

  // Supported file formats
  static const List<String> supportedExcelFormats = ['xlsx', 'xls'];
  static const List<String> supportedPdfFormats = ['pdf'];

  // API timeouts
  static const Duration importTimeout = Duration(minutes: 5);
  static const Duration exportTimeout = Duration(minutes: 3);
  static const Duration downloadTimeout = Duration(minutes: 2);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Progress update intervals
  static const Duration progressUpdateInterval = Duration(milliseconds: 100);

  // File naming patterns
  static String getExportFileName(String format) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'buku_export_$dateStr.$format';
  }

  static String getTemplateFileName() {
    return 'template_buku_import.xlsx';
  }

  // Error messages
  static const String fileTooLargeError =
      'File terlalu besar. Maksimal $maxFileSizeMB MB.';
  static const String unsupportedFormatError = 'Format file tidak didukung.';
  static const String noFileSelectedError = 'Tidak ada file yang dipilih.';
  static const String apiNotAvailableError =
      'API tidak tersedia. Periksa koneksi internet.';
  static const String networkError =
      'Terjadi kesalahan jaringan. Silakan coba lagi.';
  static const String unknownError = 'Terjadi kesalahan yang tidak diketahui.';

  // Success messages
  static const String exportSuccessMessage = 'Export berhasil!';
  static const String importSuccessMessage = 'Import berhasil!';
  static const String downloadSuccessMessage = 'Download berhasil!';

  // Validation methods
  static bool isValidFileSize(int fileSize) {
    return fileSize <= maxFileSizeBytes;
  }

  static bool isValidExcelFormat(String extension) {
    return supportedExcelFormats.contains(extension.toLowerCase());
  }

  static bool isValidPdfFormat(String extension) {
    return supportedPdfFormats.contains(extension.toLowerCase());
  }

  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
