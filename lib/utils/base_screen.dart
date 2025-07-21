import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';

/// Base class for all screens that provides standardized error handling
/// and common UI patterns
abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  /// Whether the screen is currently loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Screen identifier for error logging
  String get screenName => runtimeType.toString();

  /// Set loading state and refresh UI
  @protected
  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  /// Show standardized error message
  @protected
  void showError(String message, {Duration? duration}) {
    if (mounted) {
      ErrorHandler.showError(context, message, duration: duration);
    }
  }

  /// Show standardized success message
  @protected
  void showSuccess(String message, {Duration? duration}) {
    if (mounted) {
      ErrorHandler.showSuccess(context, message, duration: duration);
    }
  }

  /// Show standardized warning message
  @protected
  void showWarning(String message, {Duration? duration}) {
    if (mounted) {
      ErrorHandler.showWarning(context, message, duration: duration);
    }
  }

  /// Show standardized info message
  @protected
  void showInfo(String message, {Duration? duration}) {
    if (mounted) {
      ErrorHandler.showInfo(context, message, duration: duration);
    }
  }

  /// Handle async operations with standardized error handling
  @protected
  Future<U?> handleAsync<U>(
    Future<U> operation, {
    String? operationName,
    String? successMessage,
    bool showLoading = true,
  }) async {
    if (showLoading) setLoading(true);

    try {
      final result = await operation;

      if (successMessage != null && mounted) {
        showSuccess(successMessage);
      }

      return result;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.processError(error);
      final context_name = operationName ?? 'Operation in $screenName';

      ErrorHandler.logError(context_name, error, stackTrace: stackTrace);

      if (mounted) {
        showError(errorMessage);
      }

      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  /// Handle async operations that return boolean success indicators
  @protected
  Future<bool> handleAsyncBool(
    Future<bool> operation, {
    String? operationName,
    String? successMessage,
    String? failureMessage,
    bool showLoading = true,
  }) async {
    if (showLoading) setLoading(true);

    try {
      final success = await operation;

      if (mounted) {
        if (success && successMessage != null) {
          showSuccess(successMessage);
        } else if (!success && failureMessage != null) {
          showError(failureMessage);
        }
      }

      return success;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.processError(error);
      final context_name = operationName ?? 'Operation in $screenName';

      ErrorHandler.logError(context_name, error, stackTrace: stackTrace);

      if (mounted) {
        showError(errorMessage);
      }

      return false;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  /// Show confirmation dialog with standardized styling
  @protected
  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    Color? confirmColor,
    bool isDestructive = false,
  }) {
    return ErrorHandler.showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      isDestructive: isDestructive,
    );
  }

  /// Handle validation errors
  @protected
  void showValidationErrors(List<String> errors) {
    if (errors.isEmpty) return;
    ErrorHandler.showValidationError(context, errors);
  }

  /// Handle network connectivity issues
  @protected
  void handleNetworkError() {
    ErrorHandler.handleNetworkError(context);
  }

  /// Handle authentication errors
  @protected
  void handleAuthError({VoidCallback? onLoginRequired}) {
    ErrorHandler.handleAuthError(context, onLoginRequired: onLoginRequired);
  }

  /// Handle permission errors
  @protected
  void handlePermissionError(String action) {
    ErrorHandler.handlePermissionError(context, action);
  }

  /// Build loading indicator overlay
  @protected
  Widget buildLoadingOverlay({Widget? child, String? message}) {
    return Stack(
      children: [
        if (child != null) child,
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build standard app bar
  @protected
  PreferredSizeWidget buildAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    Color? backgroundColor,
    Color? foregroundColor,
    bool centerTitle = true,
    double? elevation,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation ?? 0,
      leading: leading,
      actions: actions,
    );
  }

  /// Build empty state widget
  @protected
  Widget buildEmptyState({
    required String message,
    IconData? icon,
    Widget? action,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Build error state widget
  @protected
  Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Log debug information (only in debug mode)
  @protected
  void logDebug(String message, [dynamic data]) {
    if (kDebugMode) {
      if (data != null) {}
    }
  }

  /// Log error information
  @protected
  void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    ErrorHandler.logError('$screenName.$context', error,
        stackTrace: stackTrace);
  }
}

/// Mixin for screens that need refresh functionality
mixin RefreshableMixin<T extends StatefulWidget> on BaseScreen<T> {
  /// Whether refresh is currently in progress
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  /// Set refreshing state
  @protected
  void setRefreshing(bool refreshing) {
    if (mounted) {
      setState(() {
        _isRefreshing = refreshing;
      });
    }
  }

  /// Perform refresh operation
  @protected
  Future<void> refresh();

  /// Handle refresh with error handling
  @protected
  Future<void> handleRefresh() async {
    setRefreshing(true);
    try {
      await refresh();
    } catch (error, stackTrace) {
      logError('refresh', error, stackTrace);
      if (mounted) {
        final errorMessage = ErrorHandler.processError(error);
        showError(errorMessage);
      }
    } finally {
      setRefreshing(false);
    }
  }

  /// Build refresh indicator
  @protected
  Widget buildRefreshIndicator({required Widget child}) {
    return RefreshIndicator(
      onRefresh: handleRefresh,
      child: child,
    );
  }
}

/// Mixin for screens that need form validation
mixin FormValidationMixin<T extends StatefulWidget> on BaseScreen<T> {
  /// Global form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Validate form and show errors if any
  @protected
  bool validateForm({bool showErrors = true}) {
    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid && showErrors) {
      showWarning('Mohon lengkapi semua field yang diperlukan.');
    }

    return isValid;
  }

  /// Save form data
  @protected
  void saveForm() {
    formKey.currentState?.save();
  }

  /// Reset form
  @protected
  void resetForm() {
    formKey.currentState?.reset();
  }
}

/// Mixin for screens that need pagination
mixin PaginationMixin<T extends StatefulWidget> on BaseScreen<T> {
  /// Current page number
  int _currentPage = 1;
  int get currentPage => _currentPage;

  /// Items per page
  int _itemsPerPage = 10;
  int get itemsPerPage => _itemsPerPage;

  /// Total pages
  int _totalPages = 1;
  int get totalPages => _totalPages;

  /// Whether there are more pages to load
  bool get hasMorePages => _currentPage < _totalPages;

  /// Whether pagination is currently loading
  bool _isPaginationLoading = false;
  bool get isPaginationLoading => _isPaginationLoading;

  /// Set pagination state
  @protected
  void setPaginationState({
    int? currentPage,
    int? itemsPerPage,
    int? totalPages,
    bool? isLoading,
  }) {
    if (mounted) {
      setState(() {
        if (currentPage != null) _currentPage = currentPage;
        if (itemsPerPage != null) _itemsPerPage = itemsPerPage;
        if (totalPages != null) _totalPages = totalPages;
        if (isLoading != null) _isPaginationLoading = isLoading;
      });
    }
  }

  /// Reset pagination to first page
  @protected
  void resetPagination() {
    setPaginationState(currentPage: 1, totalPages: 1);
  }

  /// Load next page
  @protected
  Future<void> loadNextPage();

  /// Handle pagination with error handling
  @protected
  Future<void> handlePagination() async {
    if (_isPaginationLoading || !hasMorePages) return;

    setPaginationState(isLoading: true);
    try {
      await loadNextPage();
    } catch (error, stackTrace) {
      logError('pagination', error, stackTrace);
      if (mounted) {
        final errorMessage = ErrorHandler.processError(error);
        showError(errorMessage);
      }
    } finally {
      setPaginationState(isLoading: false);
    }
  }
}
