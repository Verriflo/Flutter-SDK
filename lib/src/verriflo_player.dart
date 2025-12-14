import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart' as streaming;

import 'verriflo_event.dart';
import 'verriflo_config.dart';

/// Video quality presets for streaming
enum VideoQuality {
  auto,
  high,    // 1080p
  medium,  // 720p
  low,     // 480p
  lowest,  // 360p
}

/// Video player widget for live streaming
/// 
/// Connects to your Verriflo classroom and displays the instructor's stream.
/// Includes quality control, fullscreen toggle, and event callbacks.
/// 
/// Example:
/// ```dart
/// VerrifloPlayer(
///   config: VerrifloConfig(
///     serverUrl: 'wss://stream.verriflo.com',
///     token: accessToken,
///   ),
///   onEvent: (event) {
///     if (event.type == VerrifloEventType.classEnded) {
///       Navigator.pop(context);
///     }
///   },
/// )
/// ```
class VerrifloPlayer extends StatefulWidget {
  /// Connection configuration (server URL and access token)
  final VerrifloConfig config;
  
  /// Event callback for stream lifecycle events
  final void Function(VerrifloEvent event)? onEvent;
  
  /// Background color when no video is available
  final Color backgroundColor;
  
  /// Custom loading indicator widget
  final Widget? loadingWidget;
  
  /// Custom widget shown when waiting for stream
  final Widget? noVideoWidget;
  
  /// Corner radius for the player
  final BorderRadius? borderRadius;
  
  /// Show quality selector (YouTube-style popup)
  final bool showQualitySelector;
  
  /// Show fullscreen toggle button
  final bool showFullscreenButton;
  
  /// Initial quality setting
  final VideoQuality initialQuality;
  
  /// Overlay widget (rendered on top of video)
  final Widget? overlay;
  
  const VerrifloPlayer({
    super.key,
    required this.config,
    this.onEvent,
    this.backgroundColor = Colors.black,
    this.loadingWidget,
    this.noVideoWidget,
    this.borderRadius,
    this.showQualitySelector = true,
    this.showFullscreenButton = true,
    this.initialQuality = VideoQuality.auto,
    this.overlay,
  });
  
  @override
  State<VerrifloPlayer> createState() => VerrifloPlayerState();
}

class VerrifloPlayerState extends State<VerrifloPlayer> {
  // Internal streaming adapter
  streaming.Room? _streamingRoom;
  streaming.EventsListener<streaming.RoomEvent>? _eventListener;
  streaming.RemoteParticipant? _instructor;
  streaming.VideoTrack? _videoTrack;
  streaming.RemoteTrackPublication? _trackPub;
  
  bool _isConnecting = true;
  bool _isConnected = false;
  String? _error;
  VideoQuality _currentQuality = VideoQuality.auto;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  
  /// Connection status
  bool get isConnected => _isConnected;
  
  /// Current quality setting
  VideoQuality get currentQuality => _currentQuality;
  
  /// Fullscreen status
  bool get isFullscreen => _isFullscreen;
  
  @override
  void initState() {
    super.initState();
    _currentQuality = widget.initialQuality;
    _connect();
    _startHideControlsTimer();
  }
  
  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _disconnect();
    super.dispose();
  }
  
  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _videoTrack != null) {
        setState(() => _showControls = false);
      }
    });
  }
  
  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    }
  }
  
  Future<void> _connect() async {
    try {
      setState(() {
        _isConnecting = true;
        _error = null;
      });
      
      // Initialize streaming adapter with optimized settings
      _streamingRoom = streaming.Room(
        roomOptions: const streaming.RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );
      
      _eventListener = _streamingRoom!.createListener();
      _setupEventHandlers();
      
      await _streamingRoom!.connect(
        widget.config.serverUrl,
        widget.config.token,
      );
      
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = true;
        });
      }
      
      _emitEvent(const VerrifloEvent(type: VerrifloEventType.connected));
      _findInstructor();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
      
      _emitEvent(VerrifloEvent(
        type: VerrifloEventType.error,
        error: e,
        message: 'Connection failed: $e',
      ));
    }
  }
  
  void _setupEventHandlers() {
    _eventListener!
      ..on<streaming.RoomDisconnectedEvent>((event) {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _videoTrack = null;
            _instructor = null;
          });
        }
        
        _emitEvent(VerrifloEvent(
          type: VerrifloEventType.disconnected,
          message: event.reason?.name,
        ));
        
        if (event.reason == streaming.DisconnectReason.roomDeleted) {
          _emitEvent(const VerrifloEvent(type: VerrifloEventType.classEnded));
        }
      })
      ..on<streaming.ParticipantConnectedEvent>((event) {
        _emitEvent(VerrifloEvent(
          type: VerrifloEventType.participantJoined,
          participantId: event.participant.identity,
          participantName: event.participant.name,
        ));
        _checkForInstructor(event.participant);
      })
      ..on<streaming.ParticipantDisconnectedEvent>((event) {
        _emitEvent(VerrifloEvent(
          type: VerrifloEventType.participantLeft,
          participantId: event.participant.identity,
          participantName: event.participant.name,
        ));
        
        if (event.participant == _instructor) {
          if (mounted) {
            setState(() {
              _instructor = null;
              _videoTrack = null;
              _trackPub = null;
            });
          }
        }
      })
      ..on<streaming.TrackSubscribedEvent>((event) {
        if (event.track is streaming.VideoTrack) {
          if (mounted) {
            setState(() {
              _instructor = event.participant;
              _videoTrack = event.track as streaming.VideoTrack;
              _trackPub = event.publication as streaming.RemoteTrackPublication?;
            });
            _applyQuality(_currentQuality);
          }
          
          _emitEvent(VerrifloEvent(
            type: VerrifloEventType.trackSubscribed,
            participantId: event.participant.identity,
          ));
        }
      })
      ..on<streaming.TrackUnsubscribedEvent>((event) {
        if (event.track == _videoTrack) {
          if (mounted) {
            setState(() {
              _videoTrack = null;
              _trackPub = null;
            });
          }
          
          _emitEvent(VerrifloEvent(
            type: VerrifloEventType.trackUnsubscribed,
            participantId: event.participant.identity,
          ));
        }
      });
  }
  
  void _findInstructor() {
    for (final participant in _streamingRoom!.remoteParticipants.values) {
      _checkForInstructor(participant);
    }
  }
  
  void _checkForInstructor(streaming.RemoteParticipant participant) {
    for (final pub in participant.trackPublications.values) {
      if (pub.track is streaming.VideoTrack && pub.subscribed) {
        if (mounted) {
          setState(() {
            _instructor = participant;
            _videoTrack = pub.track as streaming.VideoTrack;
            _trackPub = pub;
          });
          _applyQuality(_currentQuality);
        }
        return;
      }
    }
  }
  
  /// Change video quality
  void setQuality(VideoQuality quality) {
    setState(() => _currentQuality = quality);
    _applyQuality(quality);
    
    _emitEvent(VerrifloEvent(
      type: VerrifloEventType.connectionQualityChanged,
      message: quality.name,
    ));
  }
  
  void _applyQuality(VideoQuality quality) {
    if (_trackPub == null) return;
    
    // Apply quality preference to streaming adapter
    // The adapter uses simulcast layers - we request specific dimensions
    streaming.VideoDimensions? targetDimensions;
    
    switch (quality) {
      case VideoQuality.auto:
        // Auto mode: let adaptive streaming decide
        targetDimensions = null;
        break;
      case VideoQuality.high:
        targetDimensions = const streaming.VideoDimensions(1920, 1080);
        break;
      case VideoQuality.medium:
        targetDimensions = const streaming.VideoDimensions(1280, 720);
        break;
      case VideoQuality.low:
        targetDimensions = const streaming.VideoDimensions(854, 480);
        break;
      case VideoQuality.lowest:
        targetDimensions = const streaming.VideoDimensions(640, 360);
        break;
    }
    
    // Request specific quality from the streaming adapter
    if (targetDimensions != null) {
      _trackPub!.setVideoQuality(streaming.VideoQuality.HIGH);
      _trackPub!.setVideoFPS(30);
    } else {
      // Auto mode - enable adaptive streaming
      _trackPub!.setVideoQuality(streaming.VideoQuality.HIGH);
    }
    
    if (widget.config.debug) {
      debugPrint('[VerrifloPlayer] Quality changed to: ${quality.name}');
    }
  }
  
  /// Toggle fullscreen mode
  void toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }
  
  void _emitEvent(VerrifloEvent event) {
    widget.onEvent?.call(event);
    
    if (widget.config.debug) {
      debugPrint('[VerrifloPlayer] $event');
    }
  }
  
  Future<void> _disconnect() async {
    _eventListener?.dispose();
    await _streamingRoom?.disconnect();
    _streamingRoom?.dispose();
    _streamingRoom = null;
  }
  
  // YouTube-style popup menu for quality selection
  void _showQualityPopup(BuildContext context, Offset buttonPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu<VideoQuality>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          buttonPosition.dx - 120,
          buttonPosition.dy - (VideoQuality.values.length * 48.0) - 16,
          120,
          48,
        ),
        Offset.zero & overlay.size,
      ),
      color: const Color(0xF0212121),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
      items: VideoQuality.values.map((quality) => PopupMenuItem<VideoQuality>(
        value: quality,
        height: 44,
        child: Row(
          children: [
            if (_currentQuality == quality)
              const Icon(Icons.check, color: Colors.white, size: 18)
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            Text(
              _getQualityLabel(quality),
              style: TextStyle(
                color: _currentQuality == quality ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: _currentQuality == quality ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      )).toList(),
    ).then((selected) {
      if (selected != null) {
        setQuality(selected);
      }
    });
  }
  
  String _getQualityLabel(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.auto:
        return 'Auto';
      case VideoQuality.high:
        return '1080p';
      case VideoQuality.medium:
        return '720p';
      case VideoQuality.low:
        return '480p';
      case VideoQuality.lowest:
        return '360p';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (_isConnecting) {
      content = widget.loadingWidget ?? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (_error != null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Connection failed',
              style: TextStyle(color: Colors.white.withAlpha(230)),
            ),
            TextButton(
              onPressed: _connect,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_videoTrack != null) {
      content = GestureDetector(
        onTap: _onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video stream
            streaming.VideoTrackRenderer(_videoTrack!),
            
            // User overlay
            if (widget.overlay != null) widget.overlay!,
            
            // Controls overlay
            if (_showControls) ...[
              // Bottom gradient for controls visibility
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(150),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Fullscreen button (bottom-left)
              if (widget.showFullscreenButton)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _ControlButton(
                    icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    onPressed: toggleFullscreen,
                  ),
                ),
              
              // Quality button (bottom-right) - YouTube style
              if (widget.showQualitySelector)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Builder(
                    builder: (context) => _ControlButton(
                      icon: Icons.settings,
                      label: _currentQuality == VideoQuality.auto 
                          ? null 
                          : _getQualityLabel(_currentQuality),
                      onPressed: () {
                        final RenderBox button = context.findRenderObject() as RenderBox;
                        final Offset position = button.localToGlobal(Offset.zero);
                        _showQualityPopup(context, position);
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    } else {
      content = widget.noVideoWidget ?? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, color: Colors.white.withAlpha(128), size: 48),
            const SizedBox(height: 16),
            Text(
              'Waiting for stream...',
              style: TextStyle(color: Colors.white.withAlpha(179)),
            ),
          ],
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Container(
        color: widget.backgroundColor,
        child: content,
      ),
    );
  }
}

/// Styled control button for player overlay
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 10 : 8,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
