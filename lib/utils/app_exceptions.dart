/// Custom exception classes for the Perpustakaan application
/// These provide specific error types for better error handling and user feedback

/// Base exception class for all application-specific errors
abstract class AppException implements Exception {
  final String message;
  final String? context;
  final int? statusCode;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.context,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Authentication related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'NetworkException: $message';
}

/// API related exceptions
class ApiException extends AppException {
  const ApiException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'ApiException: $message';
}

/// Validation related exceptions
class ValidationException extends AppException {
  final List<String> errors;

  const ValidationException(
    String message,
    this.errors, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() =>
      'ValidationException: $message (${errors.length} errors)';
}

/// Permission related exceptions
class PermissionException extends AppException {
  const PermissionException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'PermissionException: $message';
}

/// Data not found exceptions
class NotFoundException extends AppException {
  const NotFoundException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Business logic related exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'BusinessLogicException: $message';
}

/// Timeout related exceptions
class TimeoutException extends AppException {
  const TimeoutException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Server error exceptions
class ServerException extends AppException {
  const ServerException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'ServerException: $message';
}

/// Configuration/Setup related exceptions
class ConfigurationException extends AppException {
  const ConfigurationException(
    String message, {
    String? context,
    int? statusCode,
    dynamic originalError,
  }) : super(message,
            context: context,
            statusCode: statusCode,
            originalError: originalError);

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Utility class for creating specific exceptions
class ExceptionFactory {
  /// Create authentication exception from various sources
  static AuthenticationException createAuthException(dynamic error,
      {String? context}) {
    if (error is AuthenticationException) return error;

    String message = 'Sesi login telah habis. Silakan login ulang.';
    int? statusCode;

    if (error is Map<String, dynamic>) {
      message = error['message'] ?? error['error'] ?? message;
      statusCode = error['status'] ?? error['statusCode'];
    } else if (error is String) {
      message = error.isNotEmpty ? error : message;
    }

    return AuthenticationException(
      message,
      context: context,
      statusCode: statusCode,
      originalError: error,
    );
  }

  /// Create validation exception from form errors
  static ValidationException createValidationException(
    List<String> errors, {
    String? context,
    String? message,
  }) {
    final defaultMessage = errors.length == 1
        ? errors.first
        : 'Terdapat ${errors.length} kesalahan validasi';

    return ValidationException(
      message ?? defaultMessage,
      errors,
      context: context,
    );
  }

  /// Create network exception from connection errors
  static NetworkException createNetworkException(dynamic error,
      {String? context}) {
    if (error is NetworkException) return error;

    String message =
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';

    if (error is String && error.isNotEmpty) {
      message = error;
    }

    return NetworkException(
      message,
      context: context,
      originalError: error,
    );
  }

  /// Create API exception from HTTP errors
  static ApiException createApiException(
    dynamic error, {
    String? context,
    int? statusCode,
  }) {
    if (error is ApiException) return error;

    String message = 'Terjadi kesalahan pada server.';

    if (error is Map<String, dynamic>) {
      message = error['message'] ?? error['error'] ?? message;
      statusCode ??= error['status'] ?? error['statusCode'];
    } else if (error is String && error.isNotEmpty) {
      message = error;
    }

    return ApiException(
      message,
      context: context,
      statusCode: statusCode,
      originalError: error,
    );
  }

  /// Create permission exception
  static PermissionException createPermissionException(
    String action, {
    String? context,
    String? customMessage,
  }) {
    final message = customMessage ?? 'Anda tidak memiliki akses untuk $action.';

    return PermissionException(
      message,
      context: context,
    );
  }

  /// Create not found exception
  static NotFoundException createNotFoundException(
    String resource, {
    String? context,
    String? customMessage,
  }) {
    final message = customMessage ?? '$resource tidak ditemukan.';

    return NotFoundException(
      message,
      context: context,
    );
  }

  /// Create business logic exception
  static BusinessLogicException createBusinessLogicException(
    String message, {
    String? context,
  }) {
    return BusinessLogicException(
      message,
      context: context,
    );
  }

  /// Create timeout exception
  static TimeoutException createTimeoutException({
    String? context,
    String? customMessage,
  }) {
    final message = customMessage ?? 'Operasi timeout. Silakan coba lagi.';

    return TimeoutException(
      message,
      context: context,
    );
  }

  /// Create server exception
  static ServerException createServerException(
    dynamic error, {
    String? context,
    int? statusCode,
  }) {
    if (error is ServerException) return error;

    String message = 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';

    if (error is Map<String, dynamic>) {
      message = error['message'] ?? error['error'] ?? message;
      statusCode ??= error['status'] ?? error['statusCode'];
    } else if (error is String && error.isNotEmpty) {
      message = error;
    }

    return ServerException(
      message,
      context: context,
      statusCode: statusCode,
      originalError: error,
    );
  }
}

/// Result wrapper for operations that can succeed or fail
class Result<T> {
  final T? data;
  final AppException? error;
  final bool isSuccess;

  const Result.success(this.data)
      : error = null,
        isSuccess = true;

  const Result.failure(this.error)
      : data = null,
        isSuccess = false;

  /// Check if the result is a success
  bool get isFailure => !isSuccess;

  /// Get data or throw exception if failed
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    } else if (error != null) {
      throw error!;
    } else {
      throw Exception('No data available');
    }
  }

  /// Get data or return default value if failed
  T getDataOr(T defaultValue) {
    return isSuccess && data != null ? data! : defaultValue;
  }

  /// Execute callback if success
  Result<U> map<U>(U Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return Result.success(mapper(data!));
      } catch (e) {
        return Result.failure(
          ConfigurationException(e.toString(), originalError: e),
        );
      }
    } else {
      return Result.failure(error!);
    }
  }

  /// Execute callback if failure
  Result<T> mapError(AppException Function(AppException error) mapper) {
    if (isFailure && error != null) {
      return Result.failure(mapper(error!));
    } else {
      return this;
    }
  }

  /// Execute callback based on result
  U fold<U>(
    U Function(T data) onSuccess,
    U Function(AppException error) onFailure,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    } else {
      return onFailure(error!);
    }
  }
}

/// Extension methods for easier exception handling
extension ExceptionExtensions on Exception {
  /// Convert any exception to appropriate AppException
  AppException toAppException({String? context}) {
    if (this is AppException) return this as AppException;

    final message = toString();

    // Detect common exception types
    if (message.contains('SocketException') ||
        message.contains('HttpException') ||
        message.contains('Connection')) {
      return NetworkException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        context: context,
        originalError: this,
      );
    }

    if (message.contains('TimeoutException') || message.contains('timeout')) {
      return TimeoutException(
        'Operasi timeout. Silakan coba lagi.',
        context: context,
        originalError: this,
      );
    }

    if (message.contains('FormatException') || message.contains('Invalid')) {
      return ValidationException(
        'Format data tidak valid.',
        [message],
        context: context,
        originalError: this,
      );
    }

    // Default to generic app exception
    return ConfigurationException(
      message.isNotEmpty ? message : 'Terjadi kesalahan yang tidak diketahui.',
      context: context,
      originalError: this,
    );
  }
}
