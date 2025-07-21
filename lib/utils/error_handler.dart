import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// Centralized error handling utility for consistent error management
/// across the entire application
class ErrorHandler {
  /// Show standardized error message to user
  static void showError(BuildContext context, String message,
      {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show standardized success message to user
  static void showSuccess(BuildContext context, String message,
      {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show standardized warning message to user
  static void showWarning(BuildContext context, String message,
      {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade600,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show standardized info message to user
  static void showInfo(BuildContext context, String message,
      {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade600,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Process and standardize error messages from various sources
  static String processError(dynamic error, {String? fallbackMessage}) {
    if (error is DioException) {
      return _processDioError(error);
    }

    if (error is Exception) {
      return _processException(error);
    }

    // Handle string errors
    if (error is String) {
      return error.isNotEmpty
          ? error
          : 'Terjadi kesalahan yang tidak diketahui';
    }

    // Fallback message
    return fallbackMessage ?? 'Terjadi kesalahan yang tidak diketahui';
  }

  /// Process DioException into user-friendly messages
  static String _processDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Koneksi timeout. Periksa koneksi internet Anda.';
      case DioExceptionType.sendTimeout:
        return 'Timeout saat mengirim data. Coba lagi.';
      case DioExceptionType.receiveTimeout:
        return 'Timeout saat menerima data. Coba lagi.';
      case DioExceptionType.badResponse:
        return _processHttpError(
            error.response?.statusCode, error.response?.data);
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.connectionError:
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan jaringan yang tidak diketahui.';
      default:
        return 'Terjadi kesalahan jaringan.';
    }
  }

  /// Process HTTP status codes into user-friendly messages
  static String _processHttpError(int? statusCode, dynamic responseData) {
    // Try to extract message from response data
    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      serverMessage = responseData['message'] ??
          responseData['error'] ??
          responseData['msg'];
    }

    switch (statusCode) {
      case 400:
        return serverMessage ??
            'Permintaan tidak valid. Periksa data yang dimasukkan.';
      case 401:
        return serverMessage ?? 'Sesi login telah habis. Silakan login ulang.';
      case 403:
        return serverMessage ??
            'Anda tidak memiliki akses untuk melakukan tindakan ini.';
      case 404:
        return serverMessage ?? 'Data yang diminta tidak ditemukan.';
      case 422:
        return serverMessage ?? 'Data yang dimasukkan tidak valid.';
      case 429:
        return serverMessage ?? 'Terlalu banyak permintaan. Coba lagi nanti.';
      case 500:
        return serverMessage ??
            'Terjadi kesalahan pada server. Coba lagi nanti.';
      case 502:
        return 'Server sedang tidak tersedia. Coba lagi nanti.';
      case 503:
        return 'Layanan sedang dalam pemeliharaan. Coba lagi nanti.';
      default:
        return serverMessage ??
            'Terjadi kesalahan pada server (Kode: $statusCode).';
    }
  }

  /// Process general exceptions
  static String _processException(Exception error) {
    final errorString = error.toString();

    // Remove "Exception: " prefix if present
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }

    return errorString;
  }

  /// Log error for debugging purposes
  static void logError(String context, dynamic error,
      {StackTrace? stackTrace}) {
    if (kDebugMode) {

      if (error is DioException) {

      }
      if (stackTrace != null) {

      }

    }
  }

  /// Handle async operations with standardized error handling
  static Future<T?> handleAsync<T>(
    BuildContext context,
    Future<T> operation, {
    String? errorContext,
    String? successMessage,
    bool showLoadingIndicator = false,
  }) async {
    try {
      final result = await operation;

      if (successMessage != null && context.mounted) {
        showSuccess(context, successMessage);
      }

      return result;
    } catch (error, stackTrace) {
      final errorMessage = processError(error);
      final context_name = errorContext ?? 'Operation';

      logError(context_name, error, stackTrace: stackTrace);

      if (context.mounted) {
        showError(context, errorMessage);
      }

      return null;
    }
  }

  /// Handle async operations that return boolean success indicators
  static Future<bool> handleAsyncBool(
    BuildContext context,
    Future<bool> operation, {
    String? errorContext,
    String? successMessage,
    String? failureMessage,
  }) async {
    try {
      final success = await operation;

      if (context.mounted) {
        if (success && successMessage != null) {
          showSuccess(context, successMessage);
        } else if (!success && failureMessage != null) {
          showError(context, failureMessage);
        }
      }

      return success;
    } catch (error, stackTrace) {
      final errorMessage = processError(error);
      final context_name = errorContext ?? 'Operation';

      logError(context_name, error, stackTrace: stackTrace);

      if (context.mounted) {
        showError(context, errorMessage);
      }

      return false;
    }
  }

  /// Standard confirmation dialog with consistent styling
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    Color? confirmColor,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ??
                  (isDestructive ? Colors.red : Theme.of(context).primaryColor),
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Standard validation error display
  static void showValidationError(BuildContext context, List<String> errors) {
    if (errors.isEmpty) return;

    final message = errors.length == 1
        ? errors.first
        : 'Terdapat ${errors.length} kesalahan:\n${errors.map((e) => '• $e').join('\n')}';

    showError(context, message, duration: const Duration(seconds: 6));
  }

  /// Network connectivity error handler
  static void handleNetworkError(BuildContext context) {
    showError(
      context,
      'Tidak dapat terhubung ke server.\nPeriksa koneksi internet Anda dan coba lagi.',
      duration: const Duration(seconds: 5),
    );
  }

  /// Authentication error handler
  static void handleAuthError(BuildContext context,
      {VoidCallback? onLoginRequired}) {
    showError(
      context,
      'Sesi login telah habis. Silakan login ulang.',
      duration: const Duration(seconds: 5),
    );

    if (onLoginRequired != null) {
      onLoginRequired();
    }
  }

  /// Permission error handler
  static void handlePermissionError(BuildContext context, String action) {
    showError(
      context,
      'Anda tidak memiliki akses untuk $action.',
      duration: const Duration(seconds: 4),
    );
  }
}

/// Extension for BuildContext to make error handling more convenient
extension ErrorHandlerExtension on BuildContext {
  void showError(String message, {Duration? duration}) {
    ErrorHandler.showError(this, message, duration: duration);
  }

  void showSuccess(String message, {Duration? duration}) {
    ErrorHandler.showSuccess(this, message, duration: duration);
  }

  void showWarning(String message, {Duration? duration}) {
    ErrorHandler.showWarning(this, message, duration: duration);
  }

  void showInfo(String message, {Duration? duration}) {
    ErrorHandler.showInfo(this, message, duration: duration);
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    Color? confirmColor,
    bool isDestructive = false,
  }) {
    return ErrorHandler.showConfirmDialog(
      this,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      isDestructive: isDestructive,
    );
  }
}
