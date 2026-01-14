import 'participant.dart';
import 'customization.dart';
import 'room_settings.dart';

/// Request payload for creating a new Verriflo classroom room.
///
/// Contains all necessary information for creating a room and generating
/// a token for the initial participant (usually teacher).
///
/// Example:
/// ```dart
/// final request = CreateRoomRequest(
///   roomId: 'class-123',
///   title: 'Math 101',
///   participant: Participant(
///     uid: 'teacher-789',
///     name: 'John Doe',
///     role: ParticipantRole.teacher,
///   ),
///   customization: Customization(
///     showLobby: true,
///     needChat: true,
///   ),
/// );
/// ```
class CreateRoomRequest {
  /// Unique room identifier.
  ///
  /// Should be consistent for the same classroom session.
  final String roomId;

  /// Display title for the classroom.
  final String title;

  /// Optional description of the class.
  final String? description;

  /// Initial participant information (usually teacher).
  final Participant participant;

  /// Optional UI customization settings.
  final Customization? customization;

  /// Optional room configuration settings.
  final RoomSettings? settings;

  /// Creates a create room request.
  const CreateRoomRequest({
    required this.roomId,
    required this.title,
    this.description,
    required this.participant,
    this.customization,
    this.settings,
  });

  /// Converts to JSON map for API request.
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'title': title,
      if (description != null) 'description': description,
      'participant': participant.toJson(),
      if (customization != null) 'customization': customization!.toJson(),
      if (settings != null)
        'settings': {
          if (settings!.maxParticipants != null)
            'maxParticipants': settings!.maxParticipants,
          'autoClose': settings!.autoClose,
          // Note: emptyTimeout is handled by the server with a default of 1200s (20 min)
        },
    };
  }

  /// Creates a copy with modified fields.
  CreateRoomRequest copyWith({
    String? roomId,
    String? title,
    String? description,
    Participant? participant,
    Customization? customization,
    RoomSettings? settings,
  }) {
    return CreateRoomRequest(
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      description: description ?? this.description,
      participant: participant ?? this.participant,
      customization: customization ?? this.customization,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() =>
      'CreateRoomRequest(roomId: $roomId, title: $title, participant: ${participant.name})';
}
