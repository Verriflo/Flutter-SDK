/// Video quality presets for stream subscription.
///
/// Controls the resolution and bitrate of video received from the classroom.
/// The player will request the appropriate simulcast layer from the server.
///
/// Usage:
/// ```dart
/// VerrifloPlayer(
///   token: token,
///   quality: VideoQuality.high,
/// )
/// ```
enum VideoQuality {
  /// Automatic quality selection based on network conditions.
  /// The player adjusts resolution dynamically to maintain smooth playback.
  /// Recommended for most use cases.
  auto,

  /// Low quality (480p equivalent).
  /// Best for limited bandwidth or data-conscious users.
  /// Approximate bitrate: 500-800 kbps
  low,

  /// Medium quality (720p equivalent).
  /// Good balance between quality and bandwidth.
  /// Approximate bitrate: 1.5-2.5 Mbps
  medium,

  /// High quality (1080p equivalent).
  /// Best visual experience, requires stable connection.
  /// Approximate bitrate: 3-5 Mbps
  high,
}

/// Extension methods for VideoQuality enum.
extension VideoQualityExtension on VideoQuality {
  /// Returns a human-readable label for display in UI.
  String get label {
    switch (this) {
      case VideoQuality.auto:
        return 'Auto';
      case VideoQuality.low:
        return '480p';
      case VideoQuality.medium:
        return '720p';
      case VideoQuality.high:
        return '1080p';
    }
  }

  /// Returns the JavaScript value to send to the iframe.
  String get jsValue {
    switch (this) {
      case VideoQuality.auto:
        return 'auto';
      case VideoQuality.low:
        return 'low';
      case VideoQuality.medium:
        return 'medium';
      case VideoQuality.high:
        return 'high';
    }
  }
}
