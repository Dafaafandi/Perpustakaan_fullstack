import 'package:flutter/material.dart';
import 'package:perpus_app/utils/error_handler.dart';
import 'package:perpus_app/utils/retry_manager.dart';

/// Mixin that provides standardized error handling for screens
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Show loading state
  void showLoading() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
  }

  /// Hide loading state
  void hideLoading() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Set error message
  void setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  /// Clear error message
  void clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  /// Execute operation with standardized error handling
  Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? context,
    String? successMessage,
    bool showLoading = true,
    bool useRetry = false,
    int maxRetries = 3,
  }) async {
    if (showLoading) {
      this.showLoading();
    }

    try {
      final result = useRetry
          ? await RetryManager.retryNetworkOperation(
              operation,
              context: context,
              maxRetries: maxRetries,
            )
          : await operation();

      if (mounted) {
        clearError();
        if (successMessage != null) {
          ErrorHandler.showSuccess(this.context, successMessage);
        }
      }

      return result;
    } catch (e) {
      final errorMsg = ErrorHandler.processError(e);
      setError(errorMsg);

      if (mounted) {
        ErrorHandler.showError(this.context, errorMsg);
      }

      return null;
    } finally {
      if (showLoading) {
        hideLoading();
      }
    }
  }

  /// Execute boolean operation with error handling
  Future<bool> executeBoolWithErrorHandling(
    Future<bool> Function() operation, {
    String? context,
    String? successMessage,
    String? failureMessage,
    bool showLoading = true,
    bool useRetry = false,
    int maxRetries = 3,
  }) async {
    if (showLoading) {
      this.showLoading();
    }

    try {
      final result = useRetry
          ? await RetryManager.executeBoolWithRetry(
              operation,
              context: context,
              maxRetries: maxRetries,
            )
          : await operation();

      if (mounted) {
        clearError();
        if (result && successMessage != null) {
          ErrorHandler.showSuccess(this.context, successMessage);
        } else if (!result && failureMessage != null) {
          ErrorHandler.showError(this.context, failureMessage);
        }
      }

      return result;
    } catch (e) {
      final errorMsg = ErrorHandler.processError(e);
      setError(errorMsg);

      if (mounted) {
        ErrorHandler.showError(this.context, errorMsg);
      }

      return false;
    } finally {
      if (showLoading) {
        hideLoading();
      }
    }
  }

  /// Show confirmation dialog with error handling
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Tidak',
    Color? confirmColor,
  }) async {
    if (!mounted) return false;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: confirmColor != null
                  ? TextButton.styleFrom(foregroundColor: confirmColor)
                  : null,
              child: Text(confirmText),
            ),
          ],
        ),
      );

      return result ?? false;
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
            context, 'Error showing dialog: ${e.toString()}');
      }
      return false;
    }
  }

  /// Show loading dialog
  void showLoadingDialog({
    String title = 'Loading...',
    String? message,
    bool barrierDismissible = false,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  void hideLoadingDialog() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Build error widget for display
  Widget buildErrorWidget({
    String? customMessage,
    VoidCallback? onRetry,
    IconData? icon,
  }) {
    final message = customMessage ?? _errorMessage ?? 'Terjadi kesalahan';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.error_outline,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build loading widget
  Widget buildLoadingWidget({
    String? message,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mixin for screens that need refresh functionality
mixin RefreshableMixin<T extends StatefulWidget> on State<T> {
  bool _isRefreshing = false;

  bool get isRefreshing => _isRefreshing;

  /// Refresh data
  Future<void> refresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Override this method to implement refresh logic
  Future<void> onRefresh();

  /// Build refresh indicator
  Widget buildRefreshIndicator({
    required Widget child,
    Color? color,
  }) {
    return RefreshIndicator(
      onRefresh: refresh,
      color: color ?? Theme.of(context).primaryColor,
      child: child,
    );
  }
}

/// Mixin for screens with form validation
mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  final Map<String, String?> _fieldErrors = {};

  /// Set field error
  void setFieldError(String field, String? error) {
    setState(() {
      _fieldErrors[field] = error;
    });
  }

  /// Get field error
  String? getFieldError(String field) {
    return _fieldErrors[field];
  }

  /// Clear field error
  void clearFieldError(String field) {
    setState(() {
      _fieldErrors.remove(field);
    });
  }

  /// Clear all field errors
  void clearAllFieldErrors() {
    setState(() {
      _fieldErrors.clear();
    });
  }

  /// Check if form has errors
  bool get hasErrors => _fieldErrors.isNotEmpty;

  /// Validate required field
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validate email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  /// Validate password
  String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.length < minLength) {
      return 'Password minimal $minLength karakter';
    }

    return null;
  }

  /// Validate confirm password
  String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (value != password) {
      return 'Password tidak cocok';
    }

    return null;
  }
}
