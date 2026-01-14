import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'iframe_commands.dart';
import 'video_quality.dart';
import 'classroom_state.dart';

/// Controller for programmatic control of the Verriflo classroom player.
///
/// Provides methods to control the classroom from outside the player widget,
/// such as forcing a participant to leave, controlling media, and sending
/// custom commands to the iframe.
///
/// Usage:
/// ```dart
/// final controller = VerrifloPlayerController();
///
/// // Use in player
/// VerrifloPlayer(
///   token: token,
///   controller: controller,
/// )
///
/// // Control programmatically
/// await controller.forceLeave(reason: 'App closing');
/// ```
class VerrifloPlayerController extends ChangeNotifier {
  WebViewController? _webViewController;

  ClassroomState _state = ClassroomState.idle;
  bool _isInitialized = false;
  bool _isAudioEnabled = false;
  bool _isVideoEnabled = false;
  bool _isHandRaised = false;
  VideoQuality _quality = VideoQuality.auto;

  // === State Getters ===

  /// Current classroom state.
  ClassroomState get state => _state;

  /// Whether the controller has been initialized with a WebView.
  bool get isInitialized => _isInitialized;

  /// Whether the classroom is currently connected.
  bool get isConnected => _state == ClassroomState.connected;

  /// Whether the session has ended (class ended or kicked).
  bool get isTerminated => _state.isTerminated;

  /// Whether audio is currently enabled.
  bool get isAudioEnabled => _isAudioEnabled;

  /// Whether video is currently enabled.
  bool get isVideoEnabled => _isVideoEnabled;

  /// Whether hand is currently raised.
  bool get isHandRaised => _isHandRaised;

  /// Current video quality setting.
  VideoQuality get quality => _quality;

  // === Lifecycle ===

  /// Initialize the controller with the WebView controller.
  ///
  /// Called internally by [VerrifloPlayer]. Do not call directly.
  @internal
  void attach(WebViewController webViewController) {
    _webViewController = webViewController;
    _isInitialized = true;
    notifyListeners();
  }

  /// Detach the WebView controller.
  ///
  /// Called internally by [VerrifloPlayer]. Do not call directly.
  @internal
  void detach() {
    _webViewController = null;
    _isInitialized = false;
    _state = ClassroomState.idle;
    notifyListeners();
  }

  /// Update the internal state.
  ///
  /// Called internally by [VerrifloPlayer]. Do not call directly.
  @internal
  void updateState(ClassroomState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  // === Lifecycle Commands ===

  /// Force the participant to leave the classroom.
  ///
  /// Sends a force leave command to the iframe, which will disconnect
  /// the participant and show a notification.
  ///
  /// [reason] Optional reason message to display.
  /// [roomName] Optional room name to verify (for security).
  Future<void> forceLeave({String? reason, String? roomName}) async {
    final payload = jsonEncode({
      'type': 'verriflo_force_leave',
      if (roomName != null) 'roomName': roomName,
      if (reason != null) 'reason': reason,
    });
    final script = "window.postMessage($payload, '*');";

    try {
      await _webViewController?.runJavaScript(script);
      debugPrint('[VerrifloController] Sent force leave command');
    } catch (e) {
      debugPrint('[VerrifloController] Failed to send force leave: $e');
    }
  }

  /// Gracefully disconnect from the classroom.
  ///
  /// This cleanly exits without showing the kicked overlay.
  Future<void> disconnect() async {
    await _sendCommand(IframeCommand.disconnect, {});
  }

  /// Reload the classroom WebView.
  ///
  /// Useful for recovering from errors or refreshing the connection.
  Future<void> reload() async {
    await _webViewController?.reload();
  }

  // === Media Commands ===

  /// Set the video quality preference.
  Future<void> setQuality(VideoQuality quality) async {
    _quality = quality;
    await _sendCommand(IframeCommand.setQuality, {
      'quality': quality.jsValue,
    });
    notifyListeners();
  }

  /// Enable audio playback.
  ///
  /// Should be called after user interaction to satisfy autoplay policies.
  Future<void> enableAudio() async {
    await _sendCommand(IframeCommand.enableAudio, {});
    _isAudioEnabled = true;
    notifyListeners();
  }

  /// Mute or unmute local audio.
  Future<void> setAudioMuted(bool muted) async {
    await _sendCommand(IframeCommand.setAudioMuted, {'muted': muted});
    _isAudioEnabled = !muted;
    notifyListeners();
  }

  /// Enable or disable local video.
  Future<void> setVideoEnabled(bool enabled) async {
    await _sendCommand(IframeCommand.setVideoEnabled, {'enabled': enabled});
    _isVideoEnabled = enabled;
    notifyListeners();
  }

  // === UI Commands ===

  /// Toggle fullscreen mode.
  Future<void> setFullscreen(bool fullscreen) async {
    await _sendCommand(IframeCommand.setFullscreen, {'fullscreen': fullscreen});
  }

  /// Show or hide the chat panel.
  Future<void> setChatVisible(bool visible) async {
    await _sendCommand(IframeCommand.setChatVisible, {'visible': visible});
  }

  /// Show or hide the participants panel.
  Future<void> setParticipantsVisible(bool visible) async {
    await _sendCommand(
        IframeCommand.setParticipantsVisible, {'visible': visible});
  }

  // === Interaction Commands ===

  /// Raise or lower hand.
  Future<void> setHandRaised(bool raised) async {
    await _sendCommand(IframeCommand.setHandRaised, {'raised': raised});
    _isHandRaised = raised;
    notifyListeners();
  }

  /// Toggle hand raised state.
  Future<void> toggleHandRaised() async {
    await setHandRaised(!_isHandRaised);
  }

  /// Send a chat message.
  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;
    await _sendCommand(
        IframeCommand.sendChatMessage, {'message': message.trim()});
  }

  // === Admin Commands ===

  /// Mute a participant (admin only).
  Future<void> muteParticipant(String participantId) async {
    await _sendCommand(IframeCommand.muteParticipant, {
      'participantId': participantId,
    });
  }

  /// Kick a participant (admin only).
  Future<void> kickParticipant(String participantId, {String? reason}) async {
    await _sendCommand(IframeCommand.kickParticipant, {
      'participantId': participantId,
      if (reason != null) 'reason': reason,
    });
  }

  /// End the class for everyone (admin only).
  Future<void> endClass() async {
    await _sendCommand(IframeCommand.endClass, {});
  }

  // === Custom Commands ===

  /// Send a custom command to the iframe.
  ///
  /// Use for advanced integrations or custom features.
  Future<void> sendCustomCommand(String type, Map<String, dynamic> data) async {
    await _sendCommand(type, data);
  }

  /// Run custom JavaScript in the WebView.
  ///
  /// Use with caution - only for advanced use cases.
  Future<void> runJavaScript(String script) async {
    await _webViewController?.runJavaScript(script);
  }

  // === Internal ===

  /// Send a command to the iframe via postMessage.
  Future<void> _sendCommand(String type, Map<String, dynamic> data) async {
    if (_webViewController == null) {
      debugPrint('[VerrifloController] Cannot send command: not initialized');
      return;
    }

    final payload = jsonEncode({'type': type, 'data': data});
    final script = "window.postMessage($payload, '*');";

    try {
      await _webViewController!.runJavaScript(script);
      debugPrint('[VerrifloController] Sent command: $type');
    } catch (e) {
      debugPrint('[VerrifloController] Failed to send command: $e');
    }
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }
}

/// Annotation for internal-only methods.
class _Internal {
  const _Internal();
}

const internal = _Internal();
