/// Event types emitted by the Verriflo classroom SDK.
///
/// Subscribe to these events through [VerrifloPlayer.onEvent] to respond
/// to connection changes, participant activity, and session lifecycle.
///
/// Core events for most integrations:
/// - [connected] / [disconnected] - Connection lifecycle
/// - [classEnded] - Session terminated by instructor
/// - [participantKicked] - Current user was removed
enum VerrifloEventType {
  /// Successfully connected to the classroom.
  /// WebSocket established and media streams are available.
  connected,

  /// Disconnected from the classroom.
  /// Check [VerrifloEvent.reason] for the disconnect cause.
  disconnected,

  /// A participant joined the classroom.
  /// [VerrifloEvent.participantId] and [participantName] will be set.
  participantJoined,

  /// A participant left the classroom.
  /// [VerrifloEvent.participantId] identifies who left.
  participantLeft,

  /// The instructor or admin ended the class.
  /// Your app should navigate away from the player screen.
  classEnded,

  /// Current user was kicked from the classroom.
  /// [VerrifloEvent.reason] may contain additional context.
  participantKicked,

  /// Connection lost, attempting to reconnect.
  /// Show a subtle reconnecting indicator.
  reconnecting,

  /// Successfully reconnected after connection loss.
  /// Resume normal operation.
  reconnected,

  /// Media track subscription started.
  /// [VerrifloEvent.participantId] identifies the stream source.
  trackSubscribed,

  /// Media track subscription ended.
  /// Participant may have paused their camera/mic.
  trackUnsubscribed,

  /// Video quality setting was changed.
  /// [VerrifloEvent.message] contains the quality level.
  qualityChanged,

  /// An error occurred during the session.
  /// [VerrifloEvent.message] contains error description.
  /// [VerrifloEvent.error] contains the underlying exception.
  error,
}

/// Event payload emitted by the Verriflo SDK.
///
/// Contains all relevant information about the event. Not all fields
/// are populated for every event type - check the type first.
///
/// Example usage:
/// ```dart
/// VerrifloPlayer(
///   joinUrl: url,
///   onEvent: (event) {
///     if (event.type == VerrifloEventType.classEnded) {
///       Navigator.of(context).pop();
///     }
///     if (event.type == VerrifloEventType.participantKicked) {
///       showDialog(/* kicked message */);
///     }
///   },
/// )
/// ```
class VerrifloEvent {
  /// The event category.
  final VerrifloEventType type;

  /// Unique ID of the participant this event relates to.
  /// Set for participant-related events (joined, left, kicked, tracks).
  final String? participantId;

  /// Display name of the related participant.
  final String? participantName;

  /// Human-readable message with event details.
  /// For errors: contains the error description.
  /// For disconnects/kicks: contains the reason.
  /// For quality changes: contains the new quality level.
  final String? message;

  /// Reason code for disconnect or kick events.
  /// Common values: 'networkError', 'kicked', 'serverShutdown', 'classEnded'
  final String? reason;

  /// Underlying error object for error events.
  /// Use for debugging or logging purposes.
  final dynamic error;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  const VerrifloEvent({
    required this.type,
    this.participantId,
    this.participantName,
    this.message,
    this.reason,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const _CurrentDateTime();

  /// Factory constructor for creating events from iframe messages.
  factory VerrifloEvent.fromMessage(Map<String, dynamic> data) {
    final typeString = data['type'] as String? ?? '';
    final eventType = _parseEventType(typeString);

    return VerrifloEvent(
      type: eventType,
      participantId: data['participantId'] as String?,
      participantName: data['participantName'] as String?,
      message: data['message'] as String?,
      reason: data['reason'] as String?,
      timestamp: DateTime.now(),
    );
  }

  static VerrifloEventType _parseEventType(String type) {
    switch (type) {
      case 'connected':
        return VerrifloEventType.connected;
      case 'disconnected':
        return VerrifloEventType.disconnected;
      case 'participantJoined':
        return VerrifloEventType.participantJoined;
      case 'participantLeft':
        return VerrifloEventType.participantLeft;
      case 'classEnded':
        return VerrifloEventType.classEnded;
      case 'participantKicked':
        return VerrifloEventType.participantKicked;
      case 'reconnecting':
        return VerrifloEventType.reconnecting;
      case 'reconnected':
        return VerrifloEventType.reconnected;
      case 'trackSubscribed':
        return VerrifloEventType.trackSubscribed;
      case 'trackUnsubscribed':
        return VerrifloEventType.trackUnsubscribed;
      case 'qualityChanged':
        return VerrifloEventType.qualityChanged;
      case 'error':
      default:
        return VerrifloEventType.error;
    }
  }

  /// Whether this is an error event.
  bool get isError => type == VerrifloEventType.error;

  /// Whether this event indicates session termination.
  bool get isTerminating =>
      type == VerrifloEventType.classEnded ||
      type == VerrifloEventType.participantKicked;

  /// Whether this event relates to connection state.
  bool get isConnectionEvent =>
      type == VerrifloEventType.connected ||
      type == VerrifloEventType.disconnected ||
      type == VerrifloEventType.reconnecting ||
      type == VerrifloEventType.reconnected;

  @override
  String toString() {
    final parts = ['VerrifloEvent($type'];
    if (participantId != null) parts.add(', participant: $participantId');
    if (message != null) parts.add(', message: $message');
    if (reason != null) parts.add(', reason: $reason');
    parts.add(')');
    return parts.join();
  }
}

/// Helper class for default timestamp in const constructor.
class _CurrentDateTime implements DateTime {
  const _CurrentDateTime();

  DateTime get _now => DateTime.now();

  @override
  bool get isUtc => _now.isUtc;
  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;

  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);

  @override
  String toString() => _now.toString();
}
