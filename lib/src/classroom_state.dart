/// Represents the current state of the classroom session.
///
/// Track this state to update your UI accordingly. The player will emit
/// state changes through the [VerrifloPlayer.onStateChanged] callback.
enum ClassroomState {
  /// Initial state before connection attempt.
  idle,

  /// Attempting to establish connection with the classroom.
  /// Show a loading indicator during this phase.
  connecting,

  /// Successfully connected and receiving media.
  /// The classroom is active and functioning normally.
  connected,

  /// Connection was lost, attempting to reconnect.
  /// Display a reconnecting overlay but don't navigate away.
  reconnecting,

  /// Session ended by the instructor or administrator.
  /// Navigate the user away from the classroom screen.
  ended,

  /// Current user was removed from the classroom.
  /// Show an appropriate message and navigate away.
  kicked,

  /// An unrecoverable error occurred.
  /// Display error message and offer retry option.
  error,
}

/// Extension methods for ClassroomState enum.
extension ClassroomStateExtension on ClassroomState {
  /// Whether the classroom is in an active state (connected or reconnecting).
  bool get isActive => this == ClassroomState.connected || this == ClassroomState.reconnecting;

  /// Whether the classroom has terminated (ended, kicked, or error).
  bool get isTerminated =>
      this == ClassroomState.ended ||
      this == ClassroomState.kicked ||
      this == ClassroomState.error;

  /// Whether the user should be shown a loading state.
  bool get isLoading => this == ClassroomState.connecting || this == ClassroomState.reconnecting;
}
