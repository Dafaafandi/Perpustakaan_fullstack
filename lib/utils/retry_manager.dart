import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Enhanced retry mechanism for network operations with exponential backoff
class RetryManager {
  static const int defaultMaxRetries = 3;
  static const Duration defaultBaseDelay = Duration(seconds: 2);
  static const double defaultMultiplier = 2.0;
  static const Duration defaultMaxDelay = Duration(minutes: 1);

  /// Execute an operation with retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double multiplier = defaultMultiplier,
    Duration maxDelay = defaultMaxDelay,
    String? context,
    bool Function(Exception)? retryIf,
  }) async {
    int attemptCount = 0;
    Exception? lastException;

    while (attemptCount <= maxRetries) {
      try {
        if (kDebugMode && context != null && attemptCount > 0) {
        }

        final result = await operation();

        if (kDebugMode && context != null && attemptCount > 0) {
        }

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (kDebugMode && context != null) {
        }

        // Check if we should retry
        if (attemptCount >= maxRetries) {
          break;
        }

        // Check custom retry condition
        if (retryIf != null && !retryIf(lastException)) {
          if (kDebugMode && context != null) {
          }
          break;
        }

        // Check if error is retryable
        if (!_isRetryableError(lastException)) {
          if (kDebugMode && context != null) {
          }
          break;
        }

        // Calculate delay with exponential backoff
        final delay =
            _calculateDelay(attemptCount, baseDelay, multiplier, maxDelay);

        if (kDebugMode && context != null) {
        }

        await Future.delayed(delay);
        attemptCount++;
      }
    }

    // If we get here, all retries failed
    if (kDebugMode && context != null) {
    }

    throw lastException!;
  }

  /// Execute an operation with retry logic for boolean results
  static Future<bool> executeBoolWithRetry(
    Future<bool> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double multiplier = defaultMultiplier,
    Duration maxDelay = defaultMaxDelay,
    String? context,
    bool Function(Exception)? retryIf,
  }) async {
    try {
      final result = await executeWithRetry(
        operation,
        maxRetries: maxRetries,
        baseDelay: baseDelay,
        multiplier: multiplier,
        maxDelay: maxDelay,
        context: context,
        retryIf: retryIf,
      );
      return result;
    } catch (e) {
      if (kDebugMode && context != null) {
      }
      return false;
    }
  }

  /// Calculate delay with exponential backoff
  static Duration _calculateDelay(
    int attemptCount,
    Duration baseDelay,
    double multiplier,
    Duration maxDelay,
  ) {
    final delayMs = baseDelay.inMilliseconds *
        (multiplier.clamp(1.0, 10.0)).round().toDouble().pow(attemptCount);

    final calculatedDelay = Duration(milliseconds: delayMs.toInt());

    return calculatedDelay > maxDelay ? maxDelay : calculatedDelay;
  }

  /// Check if an error is retryable
  static bool _isRetryableError(Exception error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;

        case DioExceptionType.badResponse:
          // Retry on server errors (5xx) but not client errors (4xx)
          final statusCode = error.response?.statusCode;
          return statusCode != null && statusCode >= 500;

        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return false;
      }
    }

    // For other types of exceptions, check the message
    final message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket');
  }

  /// Retry specifically for network operations
  static Future<T> retryNetworkOperation<T>(
    Future<T> Function() operation, {
    String? context,
    int maxRetries = 3,
  }) async {
    return executeWithRetry(
      operation,
      maxRetries: maxRetries,
      context: context,
      retryIf: (error) => _isRetryableError(error),
    );
  }

  /// Retry for import/export operations with longer delays
  static Future<T> retryImportExportOperation<T>(
    Future<T> Function() operation, {
    String? context,
    int maxRetries = 2,
  }) async {
    return executeWithRetry(
      operation,
      maxRetries: maxRetries,
      baseDelay: const Duration(seconds: 5),
      multiplier: 1.5,
      maxDelay: const Duration(seconds: 30),
      context: context,
      retryIf: (error) => _isRetryableError(error),
    );
  }

  /// Create a retry configuration for specific scenarios
  static RetryConfig createConfig({
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double multiplier = defaultMultiplier,
    Duration maxDelay = defaultMaxDelay,
    bool Function(Exception)? retryIf,
  }) {
    return RetryConfig(
      maxRetries: maxRetries,
      baseDelay: baseDelay,
      multiplier: multiplier,
      maxDelay: maxDelay,
      retryIf: retryIf,
    );
  }
}

/// Configuration class for retry operations
class RetryConfig {
  final int maxRetries;
  final Duration baseDelay;
  final double multiplier;
  final Duration maxDelay;
  final bool Function(Exception)? retryIf;

  const RetryConfig({
    this.maxRetries = RetryManager.defaultMaxRetries,
    this.baseDelay = RetryManager.defaultBaseDelay,
    this.multiplier = RetryManager.defaultMultiplier,
    this.maxDelay = RetryManager.defaultMaxDelay,
    this.retryIf,
  });

  /// Execute operation with this configuration
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    return RetryManager.executeWithRetry(
      operation,
      maxRetries: maxRetries,
      baseDelay: baseDelay,
      multiplier: multiplier,
      maxDelay: maxDelay,
      context: context,
      retryIf: retryIf,
    );
  }
}

/// Extension for adding pow method to double
extension DoubleExtension on double {
  double pow(int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}
