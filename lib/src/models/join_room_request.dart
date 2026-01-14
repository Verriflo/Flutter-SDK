import 'participant.dart';
import 'customization.dart';

/// Request payload for joining an existing Verriflo classroom room.
///
/// Contains participant information and customization settings.
///
/// Example:
/// ```dart
/// final request = JoinRoomRequest(
///   participant: Participant(
///     uid: 'student-789',
///     name: 'Jane Doe',
///     role: ParticipantRole.student,
///   ),
///   customization: Customization(
///     showLobby: true,
///   ),
/// );
/// ```
class JoinRoomRequest {
  /// Participant information including identity and role.
  final Participant participant;

  /// Optional UI customization settings.
  final Customization? customization;

  /// Creates a join room request.
  const JoinRoomRequest({
    required this.participant,
    this.customization,
  });

  /// Converts to JSON map for API request.
  Map<String, dynamic> toJson() {
    return {
      'participant': participant.toJson(),
      if (customization != null) 'customization': customization!.toJson(),
    };
  }

  /// Creates a copy with modified fields.
  JoinRoomRequest copyWith({
    Participant? participant,
    Customization? customization,
  }) {
    return JoinRoomRequest(
      participant: participant ?? this.participant,
      customization: customization ?? this.customization,
    );
  }

  @override
  String toString() => 'JoinRoomRequest(participant: ${participant.name})';
}
