import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'verriflo_event.dart';
import 'video_quality.dart';
import 'classroom_state.dart';
import 'verriflo_player_controller.dart';

/// Callback signature for SDK events.
typedef VerrifloEventCallback = void Function(VerrifloEvent event);

/// Callback signature for classroom state changes.
typedef StateChangeCallback = void Function(ClassroomState state);

/// Primary widget for embedding Verriflo live classroom.
///
/// Renders an interactive WebView containing the classroom stream with
/// built-in controls for quality selection and fullscreen mode. Events
/// from the classroom are forwarded to your app through callbacks.
///
/// Basic usage with token:
/// ```dart
/// VerrifloPlayer(
///   token: 'eyJhbGciOiJIUz...',
///   onClassEnded: () => Navigator.pop(context),
///   onKicked: (reason) => showKickedDialog(reason),
/// )
/// ```
///
/// Or with full iframe URL (recommended):
/// ```dart
/// VerrifloPlayer(
///   iframeUrl: 'https://live.verriflo.com/iframe/live?token=eyJ...',
///   onClassEnded: () => Navigator.pop(context),
///   onKicked: (reason) => showKickedDialog(reason),
/// )
/// ```
///
/// With programmatic control:
/// ```dart
/// final controller = VerrifloPlayerController();
///
/// VerrifloPlayer(
///   iframeUrl: iframeUrl,
///   controller: controller,
/// );
///
/// await controller.forceLeave();
/// ```
class VerrifloPlayer extends StatefulWidget {
  /// Authentication token for the classroom.
  /// Obtain this by calling the SDK join API endpoint.
  /// Optional if [iframeUrl] is provided.
  final String? token;

  /// Optional controller for programmatic control.
  final VerrifloPlayerController? controller;

  /// Full iframe URL containing the token.
  /// If provided, [token] and [liveBaseUrl] are extracted from this URL.
  /// Example: 'https://staging.live.verriflo.com/iframe/live?token=eyJ...'
  final String? iframeUrl;

  /// Base URL for the Verriflo Live iframe.
  /// Defaults to 'https://live.verriflo.com/iframe/live'.
  /// Ignored if [iframeUrl] is provided.
  final String liveBaseUrl;

  /// Background color shown while loading or on error.
  final Color backgroundColor;

  /// Called when fullscreen toggle is requested by user.
  /// Implement your own fullscreen logic in the parent widget.
  final VoidCallback? onFullscreenToggle;

  /// Called when chat button is tapped (fullscreen mode only).
  final VoidCallback? onChatToggle;

  /// Current fullscreen state. Controls which icon is shown.
  final bool isFullscreen;

  /// Initial video quality. Defaults to [VideoQuality.auto].
  final VideoQuality initialQuality;

  /// Called for every SDK event. Use for comprehensive event handling.
  final VerrifloEventCallback? onEvent;

  /// Called when classroom state changes.
  final StateChangeCallback? onStateChanged;

  /// Convenience callback when the class ends.
  /// Equivalent to checking for [VerrifloEventType.classEnded] in onEvent.
  final VoidCallback? onClassEnded;

  /// Convenience callback when user is kicked.
  /// Receives the kick reason if provided.
  final void Function(String? reason)? onKicked;

  /// Called when an error occurs.
  final void Function(String message, dynamic error)? onError;

  /// Whether to show the built-in control bar.
  /// Set to false if you want to build custom controls.
  final bool showControls;

  const VerrifloPlayer({
    super.key,
    this.token,
    this.controller,
    this.iframeUrl,
    this.liveBaseUrl = 'https://live.verriflo.com/iframe/live',
    this.backgroundColor = Colors.transparent,
    this.onFullscreenToggle,
    this.onChatToggle,
    this.isFullscreen = false,
    this.initialQuality = VideoQuality.auto,
    this.onEvent,
    this.onStateChanged,
    this.onClassEnded,
    this.onKicked,
    this.onError,
    this.showControls = true,
  }) : assert(
          (token != null && iframeUrl == null) ||
              (token == null && iframeUrl != null),
          'Either token or iframeUrl must be provided, but not both',
        );

  @override
  State<VerrifloPlayer> createState() => _VerrifloPlayerState();
}

class _VerrifloPlayerState extends State<VerrifloPlayer> {
  late final WebViewController _controller;

  bool _isLoading = true;
  String? _errorMessage;
  bool _controlsVisible = true;

  ClassroomState _state = ClassroomState.connecting;
  VideoQuality _currentQuality = VideoQuality.auto;

  // Overlay state for ended/kicked screens
  bool _showEndedOverlay = false;
  bool _showKickedOverlay = false;
  String? _kickReason;

  // Parsed values from iframeUrl
  late final String _effectiveToken;
  late final String _effectiveBaseUrl;

  @override
  void initState() {
    super.initState();
    _currentQuality = widget.initialQuality;

    // Parse iframeUrl if provided, otherwise use separate token/baseUrl
    if (widget.iframeUrl != null) {
      final parsed = _parseIframeUrl(widget.iframeUrl!);
      _effectiveToken = parsed.token;
      _effectiveBaseUrl = parsed.baseUrl;
    } else {
      _effectiveToken = widget.token!;
      _effectiveBaseUrl = widget.liveBaseUrl;
    }

    _initializeWebView();
  }

  /// Parse iframe URL to extract token and base URL.
  ({String token, String baseUrl}) _parseIframeUrl(String iframeUrl) {
    final uri = Uri.parse(iframeUrl);
    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      throw ArgumentError('iframeUrl must contain a token parameter');
    }

    // Extract base URL (everything before query parameters)
    final baseUrl =
        '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}${uri.path}';

    return (token: token, baseUrl: baseUrl);
  }

  @override
  void dispose() {
    debugPrint('[Verriflo] Disposing VerrifloPlayer & stopping playback');
    widget.controller?.detach();

    // Aggressively stop all media playback
    try {
      _controller.runJavaScript(
          "document.querySelectorAll('video, audio').forEach(el => el.pause()); document.body.innerHTML = '';");
      _controller.loadRequest(Uri.parse('about:blank'));
    } catch (e) {
      debugPrint('[Verriflo] Error during dispose cleanup: $e');
    }
    super.dispose();
  }

  /// Initialize the WebView with platform-specific configuration.
  void _initializeWebView() {
    // Platform-specific creation params for media handling
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          _setLoading(true);
          _pageLoadedSuccessfully = false;
        },
        onPageFinished: (_) {
          _setLoading(false);
          _pageLoadedSuccessfully = true;
          // Clear any error message if page loaded successfully
          if (_errorMessage != null && mounted) {
            setState(() => _errorMessage = null);
          }
        },
        onWebResourceError: (error) {
          debugPrint(
              '[Verriflo] WebView resource error: ${error.description} (type: ${error.errorType}, code: ${error.errorCode})');

          // Only show error overlay if page hasn't loaded successfully
          // If page has loaded, these are likely non-critical sub-resource errors
          // (images, CSS, scripts, etc.) that don't prevent the stream from working
          if (!_pageLoadedSuccessfully) {
            // Only show error if page hasn't loaded yet - this might be a critical navigation error
            // Check error code: -2 is often network error, -6 is often hostname not found
            final isNetworkError =
                error.errorCode == -2 || error.errorCode == -6;
            if (isNetworkError) {
              _handleError('Failed to load classroom', error.description);
            } else {
              // For other errors before page load, log but don't show overlay immediately
              // Wait to see if page loads successfully
              debugPrint(
                  '[Verriflo] Resource error before page load, waiting to see if page loads');
            }
          } else {
            // Page has loaded successfully, so this is a non-critical sub-resource error
            // Don't show error overlay - the stream is working (audio is playing)
            debugPrint(
                '[Verriflo] Non-critical resource error ignored (page loaded successfully)');
          }
        },
        onNavigationRequest: (request) {
          // Allow all navigation requests
          return NavigationDecision.navigate;
        },
      ))
      ..addJavaScriptChannel(
        'VerrifloSDK',
        onMessageReceived: _handleJsMessage,
      )
      ..loadRequest(Uri.parse('$_effectiveBaseUrl?token=$_effectiveToken'));

    // Listen for postMessage events from iframe (for force leave and other events)
    _setupPostMessageListener(controller);

    // Set background color (not supported on macOS)
    if (!Platform.isMacOS) {
      try {
        controller.setBackgroundColor(widget.backgroundColor);
      } catch (_) {}
    }

    // Android-specific: configure media playback and deny camera/mic permission requests
    // This is a viewer-only SDK, so we deny all media capture permissions from the web content
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      // Deny all permission requests from the web content to prevent permission dialogs
      androidController.setOnPlatformPermissionRequest((request) {
        debugPrint('[Verriflo] Permission requested: ${request.types}');

        final types = request.types;
        final hasCapture =
            types.contains(WebViewPermissionResourceType.camera) ||
                types.contains(WebViewPermissionResourceType.microphone);

        if (hasCapture) {
          // Explicitly deny camera/mic access to prevent prompts
          request.deny();
        } else {
          // Grant other permissions (e.g. protected media ID for DRM/playback)
          request.grant();
        }
      });
    }

    // iOS/macOS note: WKWebView doesn't expose a permission request handler in webview_flutter.
    // iOS won't prompt for permissions unless NSCameraUsageDescription and NSMicrophoneUsageDescription
    // are present in Info.plist, so users should simply not add those keys.

    _controller = controller;

    // Attach controller if provided
    widget.controller?.attach(controller);

    // Send initial quality setting and enable audio after page loads
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _sendQualityToIframe(_currentQuality);
    });
  }

  /// Setup postMessage listener to receive events from iframe.
  ///
  /// The iframe sends events via window.postMessage with type 'verriflo_classroom'.
  void _setupPostMessageListener(WebViewController controller) {
    // Inject JavaScript to listen for postMessage events
    const script = '''
      (function() {
        window.addEventListener('message', function(event) {
          // Only handle messages from the iframe (verriflo_classroom type)
          if (event.data && event.data.type === 'verriflo_classroom') {
            // Forward to Flutter via JavaScript channel
            VerrifloSDK.postMessage(JSON.stringify({
              type: event.data.action || event.data.type,
              roomId: event.data.roomId,
              reason: event.data.reason,
              message: event.data.message || event.data.action
            }));
          }
        });
      })();
    ''';

    // Inject after page loads
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        controller.runJavaScript(script);
      }
    });
  }

  void _setLoading(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  /// Handle incoming messages from the iframe via JavaScript channel.
  void _handleJsMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;

      // Map action strings to event types
      final action = data['type'] as String? ?? '';
      VerrifloEventType eventType;

      switch (action) {
        case 'participant_left':
        case 'user_left':
          eventType = VerrifloEventType.disconnected;
          break;
        case 'class_ended':
          eventType = VerrifloEventType.classEnded;
          break;
        case 'kicked':
          eventType = VerrifloEventType.participantKicked;
          break;
        case 'participant_joined':
          eventType = VerrifloEventType.participantJoined;
          break;
        case 'force_leave_completed':
          eventType = VerrifloEventType.disconnected;
          break;
        default:
          // Try to parse as standard event format
          final event = VerrifloEvent.fromMessage(data);
          eventType = event.type;
      }

      final event = VerrifloEvent(
        type: eventType,
        participantId: data['participantId'] as String?,
        participantName: data['participantName'] as String?,
        message: data['message'] as String?,
        reason: data['reason'] as String?,
        timestamp: DateTime.now(),
      );

      // Forward to generic event handler
      widget.onEvent?.call(event);

      // Handle specific event types
      switch (event.type) {
        case VerrifloEventType.connected:
          _updateState(ClassroomState.connected);
          // Clear any error message when successfully connected
          if (_errorMessage != null && mounted) {
            setState(() => _errorMessage = null);
          }
          break;

        case VerrifloEventType.disconnected:
          if (action == 'participant_left' || action == 'user_left') {
            // User voluntarily left - don't show overlay
            _updateState(ClassroomState.idle);
          } else {
            _updateState(ClassroomState.idle);
          }
          break;

        case VerrifloEventType.reconnecting:
          _updateState(ClassroomState.reconnecting);
          break;

        case VerrifloEventType.reconnected:
          _updateState(ClassroomState.connected);
          break;

        case VerrifloEventType.classEnded:
          _updateState(ClassroomState.ended);
          setState(() => _showEndedOverlay = true);
          widget.onClassEnded?.call();
          break;

        case VerrifloEventType.participantKicked:
          _updateState(ClassroomState.kicked);
          setState(() {
            _showKickedOverlay = true;
            _kickReason = event.reason ?? event.message;
          });
          widget.onKicked?.call(event.reason ?? event.message);
          break;

        case VerrifloEventType.error:
          _handleError(event.message ?? 'Unknown error', event.error);
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('[Verriflo] Failed to parse JS message: $e');
    }
  }

  void _updateState(ClassroomState newState) {
    if (_state != newState) {
      setState(() => _state = newState);
      widget.onStateChanged?.call(newState);
      widget.controller?.updateState(newState);
    }
  }

  void _handleError(String message, dynamic error) {
    _updateState(ClassroomState.error);
    setState(() => _errorMessage = message);
    widget.onError?.call(message, error);
  }

  /// Toggle visibility of the control overlay.
  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  /// Update video quality and notify the iframe.
  void _setQuality(VideoQuality quality) {
    setState(() => _currentQuality = quality);
    _sendQualityToIframe(quality);
  }

  /// Send quality setting to the iframe via postMessage.
  void _sendQualityToIframe(VideoQuality quality) {
    final script = '''
      window.postMessage({
        type: 'setQuality',
        data: { quality: '${quality.jsValue}' }
      }, '*');
    ''';
    _controller.runJavaScript(script);
  }

  /// Enable audio playback in the iframe by resuming the AudioContext.
  /// This should be called after user interaction to satisfy browser autoplay policies.
  void _enableAudio() {
    const script = '''
      window.postMessage({
        type: 'enableAudio',
        data: {}
      }, '*');
    ''';
    _controller.runJavaScript(script);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Stack(
        children: [
          // WebView layer - Expanded to fill entire container
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: WebViewWidget(controller: _controller),
            ),
          ),

          // Loading indicator
          if (_isLoading) _buildLoadingOverlay(),

          // Error state - only show if page hasn't loaded successfully
          if (_errorMessage != null && !_isLoading && !_pageLoadedSuccessfully)
            _buildErrorOverlay(),

          // Class ended overlay
          if (_showEndedOverlay) _buildEndedOverlay(),

          // Kicked overlay
          if (_showKickedOverlay) _buildKickedOverlay(),

          // Reconnecting indicator
          if (_state == ClassroomState.reconnecting) _buildReconnectingBanner(),

          // Control bar
          if (widget.showControls &&
              _controlsVisible &&
              !_isLoading &&
              !_state.isTerminated)
            _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: widget.backgroundColor,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Connecting to classroom...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _errorMessage = null);
                  _controller.reload();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndedOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 64),
            SizedBox(height: 24),
            Text(
              'Class Ended',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The instructor has ended this session.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKickedOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, color: Colors.redAccent, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Removed from Class',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _kickReason ?? 'You have been removed from this classroom.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReconnectingBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.orange.withValues(alpha: 0.9),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Reconnecting...',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Quality selector
            _buildQualitySelector(),

            const Spacer(),

            // Chat toggle (fullscreen only)
            if (widget.onChatToggle != null)
              IconButton(
                icon:
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: widget.onChatToggle,
                tooltip: 'Toggle Chat',
              ),

            // Fullscreen toggle
            if (widget.onFullscreenToggle != null)
              IconButton(
                icon: Icon(
                  widget.isFullscreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: widget.onFullscreenToggle,
                tooltip: widget.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySelector() {
    return PopupMenuButton<VideoQuality>(
      onSelected: _setQuality,
      offset: const Offset(0, -160),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2A2A2A),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              _currentQuality.label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => VideoQuality.values.map((quality) {
        final isSelected = quality == _currentQuality;
        return PopupMenuItem<VideoQuality>(
          value: quality,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check, color: Colors.white, size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(
                quality.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
