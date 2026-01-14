/// Base exception for all Verriflo SDK errors.
///
/// All SDK exceptions extend this class for unified error handling.
class VerrifloException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Error code for programmatic handling.
  final String? code;

  /// Underlying error that caused this exception.
  final dynamic cause;

  /// Stack trace when the error occurred.
  final StackTrace? stackTrace;

  /// Creates a Verriflo exception.
  const VerrifloException(
    this.message, {
    this.code,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() =>
      'VerrifloException: $message${code != null ? ' ($code)' : ''}';
}

/// Network-related errors (timeout, connection failure, etc.).
class VerrifloNetworkException extends VerrifloException {
  /// HTTP status code if available.
  final int? statusCode;

  /// Whether this is a timeout error.
  final bool isTimeout;

  /// Whether retry might succeed.
  final bool isRetryable;

  /// Creates a network exception.
  const VerrifloNetworkException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
    this.statusCode,
    this.isTimeout = false,
    this.isRetryable = true,
  });

  /// Creates from a timeout error.
  factory VerrifloNetworkException.timeout([String? message]) {
    return VerrifloNetworkException(
      message ?? 'Request timed out. Please check your connection.',
      code: 'TIMEOUT',
      isTimeout: true,
      isRetryable: true,
    );
  }

  /// Creates from a connection error.
  factory VerrifloNetworkException.noConnection([String? message]) {
    return VerrifloNetworkException(
      message ?? 'Unable to connect. Please check your internet connection.',
      code: 'NO_CONNECTION',
      isRetryable: true,
    );
  }

  @override
  String toString() =>
      'VerrifloNetworkException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Authentication or authorization errors.
class VerrifloAuthException extends VerrifloException {
  /// Whether the token has expired.
  final bool isExpired;

  /// Whether the user lacks permission.
  final bool isUnauthorized;

  /// Creates an auth exception.
  const VerrifloAuthException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
    this.isExpired = false,
    this.isUnauthorized = false,
  });

  /// Creates from an expired token.
  factory VerrifloAuthException.expired([String? message]) {
    return VerrifloAuthException(
      message ?? 'Your session has expired. Please rejoin the classroom.',
      code: 'TOKEN_EXPIRED',
      isExpired: true,
    );
  }

  /// Creates from invalid credentials.
  factory VerrifloAuthException.invalidCredentials([String? message]) {
    return VerrifloAuthException(
      message ?? 'Invalid API key or token.',
      code: 'INVALID_CREDENTIALS',
    );
  }

  /// Creates from insufficient permissions.
  factory VerrifloAuthException.unauthorized([String? message]) {
    return VerrifloAuthException(
      message ?? 'You do not have permission to perform this action.',
      code: 'UNAUTHORIZED',
      isUnauthorized: true,
    );
  }

  @override
  String toString() => 'VerrifloAuthException: $message';
}

/// Room not found or no longer exists.
class VerrifloRoomNotFoundException extends VerrifloException {
  /// The room ID that was not found.
  final String? roomId;

  /// Creates a room not found exception.
  const VerrifloRoomNotFoundException(
    super.message, {
    super.code = 'ROOM_NOT_FOUND',
    super.cause,
    super.stackTrace,
    this.roomId,
  });

  /// Creates with a room ID.
  factory VerrifloRoomNotFoundException.forRoom(String roomId) {
    return VerrifloRoomNotFoundException(
      'Classroom "$roomId" was not found or has ended.',
      roomId: roomId,
    );
  }

  @override
  String toString() => 'VerrifloRoomNotFoundException: $message';
}

/// Rate limit exceeded.
class VerrifloRateLimitException extends VerrifloException {
  /// When the rate limit will reset.
  final DateTime? resetAt;

  /// Number of seconds until reset.
  final int? retryAfterSeconds;

  /// Creates a rate limit exception.
  const VerrifloRateLimitException(
    super.message, {
    super.code = 'RATE_LIMITED',
    super.cause,
    super.stackTrace,
    this.resetAt,
    this.retryAfterSeconds,
  });

  /// Creates with retry information.
  factory VerrifloRateLimitException.retryAfter(int seconds) {
    return VerrifloRateLimitException(
      'Too many requests. Please wait $seconds seconds before trying again.',
      retryAfterSeconds: seconds,
      resetAt: DateTime.now().add(Duration(seconds: seconds)),
    );
  }

  @override
  String toString() => 'VerrifloRateLimitException: $message';
}

/// Validation error for invalid input.
class VerrifloValidationException extends VerrifloException {
  /// Map of field names to error messages.
  final Map<String, String>? fieldErrors;

  /// Creates a validation exception.
  const VerrifloValidationException(
    super.message, {
    super.code = 'VALIDATION_ERROR',
    super.cause,
    super.stackTrace,
    this.fieldErrors,
  });

  /// Creates from field errors.
  factory VerrifloValidationException.fields(Map<String, String> errors) {
    final message =
        errors.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return VerrifloValidationException(
      'Validation failed: $message',
      fieldErrors: errors,
    );
  }

  @override
  String toString() => 'VerrifloValidationException: $message';
}

/// Server-side error.
class VerrifloServerException extends VerrifloException {
  /// HTTP status code.
  final int statusCode;

  /// Request ID for debugging.
  final String? requestId;

  /// Creates a server exception.
  const VerrifloServerException(
    super.message, {
    super.code = 'SERVER_ERROR',
    super.cause,
    super.stackTrace,
    required this.statusCode,
    this.requestId,
  });

  @override
  String toString() =>
      'VerrifloServerException: $message (HTTP $statusCode)${requestId != null ? ' [Request: $requestId]' : ''}';
}
