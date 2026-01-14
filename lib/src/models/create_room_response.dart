/// Response from the create room API containing session token and iframe URL.
///
/// Use [token] to initialize the [VerrifloPlayer] widget.
class CreateRoomResponse {
  /// JWT token for authenticating with the classroom.
  ///
  /// Pass this to [VerrifloPlayer.token] to connect.
  final String token;

  /// Full iframe URL with token parameter.
  ///
  /// Use this URL directly in the WebView or iframe.
  final String iframeUrl;

  /// Token expiration timestamp.
  ///
  /// The session will be invalidated after this time.
  final DateTime? expiresAt;

  /// Room ID that was created.
  final String roomId;

  /// Creates a create room response.
  const CreateRoomResponse({
    required this.token,
    required this.iframeUrl,
    required this.roomId,
    this.expiresAt,
  });

  /// Creates from API response JSON.
  factory CreateRoomResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    DateTime? expiresAt;
    if (data['expiresAt'] != null) {
      expiresAt = DateTime.parse(data['expiresAt'] as String);
    }

    return CreateRoomResponse(
      token: data['token'] as String,
      iframeUrl: data['iframeUrl'] as String,
      roomId: data['roomId'] as String,
      expiresAt: expiresAt,
    );
  }

  /// Whether the token has expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Time remaining until expiration.
  Duration? get timeUntilExpiration {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  String toString() =>
      'CreateRoomResponse(roomId: $roomId, iframeUrl: $iframeUrl, expires: $expiresAt)';
}
