/// Verriflo Classroom SDK for Flutter.
///
/// Embed live video classrooms in your Flutter application with full
/// event handling, quality control, and session state management.
///
/// Quick start:
/// ```dart
/// import 'package:verriflo_classroom/verriflo_classroom.dart';
///
/// /// // Obtain token from your backend (call SDK join API)
/// final token = 'eyJhbGciOiJI...';
///
/// // Embed the player
/// VerrifloPlayer(
///   token: token,
///   onClassEnded: () => Navigator.pop(context),
///   onKicked: (reason) => showDialog(...),
///   onEvent: (event) => print('Event: ${event.type}'),
/// )
/// ```
library;

// Core player widget
export 'src/verriflo_player.dart' show VerrifloPlayer, VerrifloEventCallback, StateChangeCallback;

// Configuration
export 'src/verriflo_config.dart' show VerrifloConfig;

// Events and types
export 'src/verriflo_event.dart' show VerrifloEvent, VerrifloEventType;

// State management
export 'src/classroom_state.dart' show ClassroomState, ClassroomStateExtension;

// Quality control
export 'src/video_quality.dart' show VideoQuality, VideoQualityExtension;
