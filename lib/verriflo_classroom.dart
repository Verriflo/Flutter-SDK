/// Verriflo Classroom SDK
/// 
/// A video player SDK for real-time streaming in education apps.
/// 
/// Usage:
/// ```dart
/// import 'package:verriflo_classroom/verriflo_classroom.dart';
/// 
/// VerrifloPlayer(
///   config: VerrifloConfig(
///     serverUrl: 'wss://livek.verriflo.com',
///     token: livekitToken,
///   ),
///   onEvent: (event) {
///     if (event.type == VerrifloEventType.classEnded) {
///       Navigator.pop(context);
///     }
///   },
/// )
/// ```

library;

export 'src/verriflo_player.dart';
export 'src/verriflo_event.dart';
export 'src/verriflo_config.dart';
