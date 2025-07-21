class LoginResult {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String message;

  LoginResult({
    required this.success,
    this.token,
    this.user,
    required this.message,
  });
}

class RegisterResult {
  final bool success;
  final String message;

  RegisterResult({
    required this.success,
    required this.message,
  });
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
