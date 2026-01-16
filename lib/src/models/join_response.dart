import 'customization.dart';
import 'organization.dart';
import 'room_settings.dart';

/// Response from the join API containing session token and configuration.
///
/// Use [token] to initialize the [VerrifloPlayer] widget.
class JoinResponse {
  /// JWT token for authenticating with the classroom.
  ///
  /// Pass this to [VerrifloPlayer.token] to connect.
  final String token;

  /// Full iframe URL with token parameter.
  ///
  /// Use this URL directly in the WebView or iframe.
  final String iframeUrl;

  /// LiveKit server URL for media streaming.
  final String serverUrl;

  /// Resolved customization settings.
  ///
  /// May include defaults merged with request customization.
  final Customization? customization;

  /// Room configuration.
  final RoomSettings? roomSettings;

  /// Organization branding.
  final OrganizationInfo? organization;

  /// Token expiration timestamp.
  ///
  /// The session will be invalidated after this time.
  final DateTime? expiresAt;

  /// Additional metadata from the server.
  final Map<String, dynamic>? metadata;

  /// Creates a join response.
  const JoinResponse({
    required this.token,
    required this.iframeUrl,
    required this.serverUrl,
    this.customization,
    this.roomSettings,
    this.organization,
    this.expiresAt,
    this.metadata,
  });

  /// Creates from API response JSON.
  factory JoinResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    DateTime? expiresAt;
    if (data['expiresAt'] != null) {
      expiresAt = DateTime.parse(data['expiresAt'] as String);
    } else if (data['tokenExp'] != null) {
      // JWT exp is in seconds since epoch (backward compatibility)
      expiresAt = DateTime.fromMillisecondsSinceEpoch(
        (data['tokenExp'] as int) * 1000,
      );
    }

    final iframeUrl = data['iframeUrl'] as String? ?? '';

    return JoinResponse(
      token: data['token'] as String? ??
          data['accessToken'] as String? ??
          (throw const FormatException(
              'Missing required field: token or accessToken')),
      iframeUrl: iframeUrl,
      serverUrl: data['serverUrl'] as String? ?? '',
      customization: data['customization'] != null
          ? Customization.fromJson(
              data['customization'] as Map<String, dynamic>,
            )
          : null,
      roomSettings: data['room'] != null
          ? RoomSettings.fromJson(data['room'] as Map<String, dynamic>)
          : null,
      organization: data['organization'] != null
          ? OrganizationInfo.fromJson(
              data['organization'] as Map<String, dynamic>,
            )
          : null,
      expiresAt: expiresAt,
      metadata: data['metadata'] as Map<String, dynamic>?,
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
      'JoinResponse(iframeUrl: $iframeUrl, expires: $expiresAt)';
}
