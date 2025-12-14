/// Types of events emitted by the Verriflo SDK.
///
/// Subscribe to these events via [VerrifloPlayer.onEvent] to respond
/// to connection state changes, participant activity, and errors.
enum VerrifloEventType {
  /// Successfully connected to the classroom.
  ///
  /// Emitted when the WebSocket connection is established and the
  /// participant has joined the room. The player is ready to receive
  /// video streams.
  connected,

  /// Disconnected from the classroom.
  ///
  /// Check [VerrifloEvent.message] for the disconnect reason:
  /// - `clientInitiated` — User left voluntarily
  /// - `serverShutdown` — Server closed the connection
  /// - `networkError` — Network connectivity lost
  disconnected,

  /// A participant joined the classroom.
  ///
  /// [VerrifloEvent.participantId] contains their unique identifier.
  /// [VerrifloEvent.participantName] contains their display name.
  participantJoined,

  /// A participant left the classroom.
  ///
  /// [VerrifloEvent.participantId] contains their unique identifier.
  participantLeft,

  /// The classroom session has ended.
  ///
  /// Emitted when the instructor ends the class or the room is closed
  /// by an administrator. Your app should navigate away from the player
  /// when receiving this event.
  classEnded,

  /// A video/audio track was subscribed.
  ///
  /// The player has started receiving media from a participant.
  /// [VerrifloEvent.participantId] identifies the stream source.
  trackSubscribed,

  /// A video/audio track was unsubscribed.
  ///
  /// The player is no longer receiving media from a participant.
  /// This may occur when the instructor pauses their camera.
  trackUnsubscribed,

  /// Video quality setting was changed.
  ///
  /// [VerrifloEvent.message] contains the new quality level name
  /// (e.g., `auto`, `high`, `medium`, `low`, `lowest`).
  connectionQualityChanged,

  /// An error occurred.
  ///
  /// [VerrifloEvent.message] contains a human-readable error description.
  /// [VerrifloEvent.error] contains the underlying exception if available.
  error,
}

/// Event data emitted by the Verriflo SDK.
///
/// Events provide information about connection state, participant activity,
/// and errors. Use the [type] field to determine the event category, then
/// access relevant properties for details.
///
/// ```dart
/// VerrifloPlayer(
///   config: config,
///   onEvent: (event) {
///     switch (event.type) {
///       case VerrifloEventType.connected:
///         print('Connected to classroom');
///         break;
///       case VerrifloEventType.classEnded:
///         Navigator.pop(context);
///         break;
///       case VerrifloEventType.error:
///         showError(event.message);
///         break;
///       default:
///         break;
///     }
///   },
/// )
/// ```
class VerrifloEvent {
  /// The category of this event.
  final VerrifloEventType type;

  /// Unique identifier of the participant this event relates to.
  ///
  /// Non-null for [VerrifloEventType.participantJoined],
  /// [VerrifloEventType.participantLeft], [VerrifloEventType.trackSubscribed],
  /// and [VerrifloEventType.trackUnsubscribed].
  final String? participantId;

  /// Display name of the participant this event relates to.
  ///
  /// Available when [participantId] is present.
  final String? participantName;

  /// Human-readable message with additional details.
  ///
  /// For [VerrifloEventType.error], this contains the error description.
  /// For [VerrifloEventType.disconnected], this contains the reason.
  /// For [VerrifloEventType.connectionQualityChanged], this contains the quality level.
  final String? message;

  /// Underlying error object for [VerrifloEventType.error] events.
  ///
  /// May be an [Exception], [Error], or other throwable type.
  /// Use for logging or detailed error analysis.
  final dynamic error;

  /// Creates a new event instance.
  ///
  /// [type] is required. Other fields are populated based on event type.
  const VerrifloEvent({
    required this.type,
    this.participantId,
    this.participantName,
    this.message,
    this.error,
  });

  /// Whether this is an error event.
  bool get isError => type == VerrifloEventType.error;

  /// Whether this is a connection state event.
  bool get isConnectionEvent =>
      type == VerrifloEventType.connected ||
      type == VerrifloEventType.disconnected;

  /// Whether this event relates to a specific participant.
  bool get hasParticipant => participantId != null;

  @override
  String toString() {
    final buffer = StringBuffer('VerrifloEvent($type');
    if (participantId != null) buffer.write(', participant: $participantId');
    if (message != null) buffer.write(', message: $message');
    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerrifloEvent &&
          type == other.type &&
          participantId == other.participantId &&
          message == other.message;

  @override
  int get hashCode => Object.hash(type, participantId, message);
}
