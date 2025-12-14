/// Configuration for connecting to Verriflo streaming services.
///
/// Create an instance with your streaming endpoint and access token,
/// then pass it to [VerrifloPlayer] to establish a connection.
///
/// ```dart
/// final config = VerrifloConfig(
///   serverUrl: 'wss://stream.verriflo.com',
///   token: accessToken,
///   debug: true, // Enable for development
/// );
/// ```
class VerrifloConfig {
  /// WebSocket URL for the streaming server.
  ///
  /// This should be the `serverUrl` returned by the SDK join API.
  /// Example: `wss://stream.verriflo.com`
  final String serverUrl;

  /// Access token for authentication.
  ///
  /// Obtain this token by calling the `/v1/live/sdk/join` API endpoint.
  /// The token contains participant identity, permissions, and metadata.
  final String token;

  /// Optional room identifier.
  ///
  /// Usually extracted from the token automatically. Only specify if
  /// connecting to a different room than encoded in the token.
  final String? roomName;

  /// Enable debug logging to console.
  ///
  /// When `true`, the SDK will print detailed connection events,
  /// quality changes, and internal state to the debug console.
  /// Recommended for development only.
  ///
  /// Default: `false`
  final bool debug;

  /// Automatically attempt to reconnect on connection loss.
  ///
  /// When `true`, the SDK will attempt to re-establish the connection
  /// if it drops due to network issues. Set to `false` if you want to
  /// handle reconnection manually via events.
  ///
  /// Default: `true`
  final bool autoReconnect;

  /// Creates a new configuration instance.
  ///
  /// [serverUrl] and [token] are required. All other parameters have
  /// sensible defaults for production use.
  const VerrifloConfig({
    required this.serverUrl,
    required this.token,
    this.roomName,
    this.debug = false,
    this.autoReconnect = true,
  });

  /// Creates a copy of this config with the given fields replaced.
  VerrifloConfig copyWith({
    String? serverUrl,
    String? token,
    String? roomName,
    bool? debug,
    bool? autoReconnect,
  }) {
    return VerrifloConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      token: token ?? this.token,
      roomName: roomName ?? this.roomName,
      debug: debug ?? this.debug,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }

  @override
  String toString() {
    return 'VerrifloConfig(serverUrl: $serverUrl, debug: $debug, autoReconnect: $autoReconnect)';
  }
}
