/// Standardized iframe command types for communication with the classroom.
///
/// These commands are sent via postMessage to the iframe to control
/// the classroom behavior programmatically.
///
/// Usage:
/// ```dart
/// controller.runJavaScript('''
///   window.postMessage({
///     type: '${IframeCommand.forceLeave}',
///     data: { reason: 'App closing' }
///   }, '*');
/// ''');
/// ```
abstract class IframeCommand {
  IframeCommand._(); // Prevent instantiation

  // === Lifecycle Commands ===

  /// Force disconnect the participant from the room.
  ///
  /// Data: { reason?: string }
  /// Triggers the iframe to disconnect and show the kicked overlay.
  static const String forceLeave = 'verriflo_force_leave';

  /// Gracefully disconnect from the room.
  ///
  /// Data: { }
  /// Triggers a clean disconnect without the kicked overlay.
  static const String disconnect = 'verriflo_disconnect';

  // === Media Commands ===

  /// Set video quality preference.
  ///
  /// Data: { quality: 'auto' | 'low' | 'medium' | 'high' | 'off' }
  static const String setQuality = 'setQuality';

  /// Resume audio context for autoplay.
  ///
  /// Data: { }
  /// Should be called after user interaction to enable audio.
  static const String enableAudio = 'enableAudio';

  /// Mute/unmute local audio.
  ///
  /// Data: { muted: boolean }
  static const String setAudioMuted = 'verriflo_set_audio_muted';

  /// Enable/disable local video.
  ///
  /// Data: { enabled: boolean }
  static const String setVideoEnabled = 'verriflo_set_video_enabled';

  // === UI Commands ===

  /// Toggle fullscreen mode.
  ///
  /// Data: { fullscreen: boolean }
  static const String setFullscreen = 'verriflo_set_fullscreen';

  /// Show/hide the chat panel.
  ///
  /// Data: { visible: boolean }
  static const String setChatVisible = 'verriflo_set_chat_visible';

  /// Show/hide the participants panel.
  ///
  /// Data: { visible: boolean }
  static const String setParticipantsVisible =
      'verriflo_set_participants_visible';

  // === Interaction Commands ===

  /// Raise or lower hand.
  ///
  /// Data: { raised: boolean }
  static const String setHandRaised = 'verriflo_set_hand_raised';

  /// Send a chat message.
  ///
  /// Data: { message: string }
  static const String sendChatMessage = 'verriflo_send_chat_message';

  // === Admin Commands ===

  /// Mute a participant (admin only).
  ///
  /// Data: { participantId: string }
  static const String muteParticipant = 'verriflo_mute_participant';

  /// Kick a participant (admin only).
  ///
  /// Data: { participantId: string, reason?: string }
  static const String kickParticipant = 'verriflo_kick_participant';

  /// End the class (admin only).
  ///
  /// Data: { }
  static const String endClass = 'verriflo_end_class';
}

/// Event types sent from the iframe to the SDK.
///
/// These are the message types received via the JavaScript channel.
abstract class IframeEvent {
  IframeEvent._(); // Prevent instantiation

  // === Lifecycle Events ===

  /// Successfully connected to the room.
  static const String connected = 'connected';

  /// Disconnected from the room.
  static const String disconnected = 'disconnected';

  /// Attempting to reconnect.
  static const String reconnecting = 'reconnecting';

  /// Successfully reconnected.
  static const String reconnected = 'reconnected';

  // === Session Events ===

  /// Class was ended by the instructor.
  static const String classEnded = 'classEnded';

  /// Current user was kicked.
  static const String participantKicked = 'participantKicked';

  // === Participant Events ===

  /// A participant joined.
  static const String participantJoined = 'participantJoined';

  /// A participant left.
  static const String participantLeft = 'participantLeft';

  // === Media Events ===

  /// Track was subscribed.
  static const String trackSubscribed = 'trackSubscribed';

  /// Track was unsubscribed.
  static const String trackUnsubscribed = 'trackUnsubscribed';

  /// Quality setting changed.
  static const String qualityChanged = 'qualityChanged';

  // === Error Events ===

  /// An error occurred.
  static const String error = 'error';
}

/// Helper to build command payloads.
class IframeCommandBuilder {
  /// Builds a force leave command payload.
  static Map<String, dynamic> forceLeave({String? reason}) {
    return {
      'type': IframeCommand.forceLeave,
      'data': {
        if (reason != null) 'reason': reason,
      },
    };
  }

  /// Builds a set quality command payload.
  static Map<String, dynamic> setQuality(String quality) {
    return {
      'type': IframeCommand.setQuality,
      'data': {'quality': quality},
    };
  }

  /// Builds an enable audio command payload.
  static Map<String, dynamic> enableAudio() {
    return {
      'type': IframeCommand.enableAudio,
      'data': {},
    };
  }

  /// Builds a send chat message command payload.
  static Map<String, dynamic> sendChatMessage(String message) {
    return {
      'type': IframeCommand.sendChatMessage,
      'data': {'message': message},
    };
  }

  /// Builds a set hand raised command payload.
  static Map<String, dynamic> setHandRaised(bool raised) {
    return {
      'type': IframeCommand.setHandRaised,
      'data': {'raised': raised},
    };
  }
}
