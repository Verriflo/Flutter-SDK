import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models/models.dart';
import 'exceptions.dart';

/// HTTP client for Verriflo API with retry logic and error handling.
///
/// Enterprise-grade client with:
/// - Automatic retry for transient failures
/// - Request timeout handling
/// - Typed error responses
/// - Debug logging
///
/// Example:
/// ```dart
/// final client = VerrifloClient(
///   baseUrl: 'https://api.verriflo.com',
///   organizationId: 'your-org-id',
/// );
///
/// final response = await client.createRoom(CreateRoomRequest(...));
/// final joinResponse = await client.joinRoom('room-id', JoinRequest(...));
/// ```
class VerrifloClient {
  /// Base URL for the API (without trailing slash).
  final String baseUrl;

  /// Organization ID for authentication (sent as VF-ORG-ID header).
  final String organizationId;

  /// Request timeout duration.
  final Duration timeout;

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Enable debug logging.
  final bool debug;

  /// HTTP client instance.
  final http.Client _httpClient;

  /// Creates a new Verriflo API client.
  ///
  /// [baseUrl] should be the API server URL without trailing slash (e.g., 'https://api.verriflo.com').
  /// [organizationId] is your organization ID (sent as VF-ORG-ID header).
  VerrifloClient({
    required this.baseUrl,
    required this.organizationId,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.debug = false,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Create a new classroom room.
  ///
  /// Creates a room and returns a token for the initial participant (usually teacher).
  /// Returns a [CreateRoomResponse] containing the token and iframe URL.
  ///
  /// Throws:
  /// - [VerrifloValidationException] if request is invalid
  /// - [VerrifloNetworkException] for network errors
  Future<CreateRoomResponse> createRoom(CreateRoomRequest request) async {
    final response = await _post(
      '/v1/room/create',
      body: request.toJson(),
    );

    return CreateRoomResponse.fromJson(response);
  }

  /// Join an existing classroom room.
  ///
  /// Generates a join token for a participant to join an existing room.
  /// Returns a [JoinResponse] containing the token and iframe URL.
  ///
  /// Throws:
  /// - [VerrifloRoomNotFoundException] if room doesn't exist
  /// - [VerrifloValidationException] if request is invalid
  /// - [VerrifloNetworkException] for network errors
  Future<JoinResponse> joinRoom(String roomId, JoinRoomRequest request) async {
    final response = await _post(
      '/v1/room/$roomId/join',
      body: request.toJson(),
    );

    return JoinResponse.fromJson(response);
  }

  /// Join a classroom and get a session token (deprecated).
  ///
  /// Use [joinRoom] instead. This method is kept for backward compatibility.
  @Deprecated('Use joinRoom instead')
  Future<JoinResponse> joinClass(JoinRequest request) async {
    return joinRoom(
        request.roomId,
        JoinRoomRequest(
          participant: request.participant,
          customization: request.customization,
        ));
  }

  /// Check if a room is active and accepting participants.
  Future<bool> isRoomActive(String roomId) async {
    try {
      final response = await _get('/v1/room/$roomId/status');
      return response['isActive'] as bool? ?? false;
    } on VerrifloRoomNotFoundException {
      return false;
    }
  }

  /// Perform a GET request with retry logic.
  Future<Map<String, dynamic>> _get(String path) async {
    return _request('GET', path);
  }

  /// Perform a POST request with retry logic.
  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request('POST', path, body: body);
  }

  /// Perform an HTTP request with retry logic.
  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    int attempts = 0;
    Exception? lastError;

    while (attempts < maxRetries) {
      attempts++;

      try {
        final uri = Uri.parse('$baseUrl$path');
        final headers = _buildHeaders();

        _log('$method $uri (attempt $attempts)');

        late http.Response response;

        switch (method) {
          case 'GET':
            response =
                await _httpClient.get(uri, headers: headers).timeout(timeout);
            break;
          case 'POST':
            response = await _httpClient
                .post(
                  uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(timeout);
            break;
          default:
            throw VerrifloException('Unsupported HTTP method: $method');
        }

        return _handleResponse(response);
      } on TimeoutException {
        lastError = VerrifloNetworkException.timeout();
        _log('Request timed out (attempt $attempts)');
      } on SocketException catch (e) {
        lastError = VerrifloNetworkException.noConnection(e.message);
        _log('Connection error: ${e.message} (attempt $attempts)');
      } on VerrifloNetworkException catch (e) {
        // Only retry network errors marked as retryable
        if (!e.isRetryable || attempts >= maxRetries) {
          rethrow;
        }
        lastError = e;
        _log('Retryable error: ${e.message} (attempt $attempts)');
      } on VerrifloException {
        // Don't retry non-network errors
        rethrow;
      } catch (e) {
        lastError = VerrifloException('Unexpected error: $e', cause: e);
        _log('Unexpected error: $e (attempt $attempts)');
      }

      // Wait before retrying
      if (attempts < maxRetries) {
        await Future.delayed(retryDelay * attempts);
      }
    }

    throw lastError ??
        VerrifloException('Request failed after $maxRetries attempts');
  }

  /// Build request headers.
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'VF-ORG-ID': organizationId,
      'X-SDK-Version': '2.0.0',
      'X-SDK-Platform': _getPlatform(),
    };
  }

  /// Get current platform identifier.
  String _getPlatform() {
    if (kIsWeb) return 'flutter-web';
    if (Platform.isAndroid) return 'flutter-android';
    if (Platform.isIOS) return 'flutter-ios';
    if (Platform.isMacOS) return 'flutter-macos';
    if (Platform.isWindows) return 'flutter-windows';
    if (Platform.isLinux) return 'flutter-linux';
    return 'flutter-unknown';
  }

  /// Handle HTTP response and convert to typed result or exception.
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    Map<String, dynamic>? body;

    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Body is not JSON
    }

    _log('Response: $statusCode');

    // Success responses
    if (statusCode >= 200 && statusCode < 300) {
      return body ?? {};
    }

    // Handle specific error codes
    final message = body?['message'] as String? ??
        body?['error'] as String? ??
        'Request failed';
    final code = body?['code'] as String?;
    final requestId = response.headers['x-request-id'];

    switch (statusCode) {
      case 400:
        final errors = body?['errors'] as Map<String, dynamic>?;
        throw VerrifloValidationException(
          message,
          code: code,
          fieldErrors: errors?.map((k, v) => MapEntry(k, v.toString())),
        );

      case 401:
        throw VerrifloAuthException.invalidCredentials(message);

      case 403:
        throw VerrifloAuthException.unauthorized(message);

      case 404:
        throw VerrifloRoomNotFoundException(message, code: code);

      case 429:
        final retryAfter = int.tryParse(
          response.headers['retry-after'] ?? '',
        );
        throw retryAfter != null
            ? VerrifloRateLimitException.retryAfter(retryAfter)
            : VerrifloRateLimitException(message);

      case 500:
      case 502:
      case 503:
      case 504:
        throw VerrifloServerException(
          message,
          statusCode: statusCode,
          requestId: requestId,
        );

      default:
        throw VerrifloNetworkException(
          message,
          statusCode: statusCode,
          isRetryable: statusCode >= 500,
        );
    }
  }

  /// Log debug message.
  void _log(String message) {
    if (debug) {
      debugPrint('[VerrifloClient] $message');
    }
  }

  /// Close the HTTP client.
  ///
  /// Call this when the client is no longer needed.
  void dispose() {
    _httpClient.close();
  }
}
