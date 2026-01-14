import 'participant.dart';
import 'customization.dart';
import 'room_settings.dart';
import 'organization.dart';

/// Request payload for joining a Verriflo classroom.
///
/// Contains all necessary information for creating a session token
/// and configuring the classroom experience.
///
/// Example:
/// ```dart
/// final request = JoinRequest(
///   roomId: 'class-123',
///   organizationId: 'org-456',
///   participant: Participant(
///     uid: 'student-789',
///     name: 'John Doe',
///     role: ParticipantRole.student,
///   ),
///   customization: Customization(
///     showLobby: true,
///     theme: ClassroomTheme.dark,
///   ),
/// );
/// ```
class JoinRequest {
  /// Unique room identifier.
  ///
  /// Should be consistent for the same classroom session.
  final String roomId;

  /// Organization identifier for billing and branding.
  final String organizationId;

  /// Participant information including identity and role.
  final Participant participant;

  /// Optional UI customization settings.
  final Customization? customization;

  /// Optional room configuration.
  final RoomSettings? roomSettings;

  /// Optional organization branding information.
  final OrganizationInfo? organization;

  /// Optional list of allowed embedding domains.
  ///
  /// Used when [Customization.validateDomain] is enabled.
  final List<String>? allowedDomains;

  /// Creates a join request.
  const JoinRequest({
    required this.roomId,
    required this.organizationId,
    required this.participant,
    this.customization,
    this.roomSettings,
    this.organization,
    this.allowedDomains,
  });

  /// Converts to JSON map for API request.
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'orgId': organizationId,
      'participant': participant.toJson(),
      if (customization != null) 'customization': customization!.toJson(),
      if (roomSettings != null) 'room': roomSettings!.toJson(),
      if (organization != null) 'organization': organization!.toJson(),
      if (allowedDomains != null) 'allowedDomains': allowedDomains,
    };
  }

  /// Creates a copy with modified fields.
  JoinRequest copyWith({
    String? roomId,
    String? organizationId,
    Participant? participant,
    Customization? customization,
    RoomSettings? roomSettings,
    OrganizationInfo? organization,
    List<String>? allowedDomains,
  }) {
    return JoinRequest(
      roomId: roomId ?? this.roomId,
      organizationId: organizationId ?? this.organizationId,
      participant: participant ?? this.participant,
      customization: customization ?? this.customization,
      roomSettings: roomSettings ?? this.roomSettings,
      organization: organization ?? this.organization,
      allowedDomains: allowedDomains ?? this.allowedDomains,
    );
  }

  @override
  String toString() =>
      'JoinRequest(roomId: $roomId, participant: ${participant.name})';
}
