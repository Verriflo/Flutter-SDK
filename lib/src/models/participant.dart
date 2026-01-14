/// Participant role in a Verriflo classroom.
///
/// Determines permissions and UI features available to the participant.
enum ParticipantRole {
  /// Student with limited permissions (view-only, hand raise).
  student,

  /// Teacher with full control (mute, kick, end class, recording).
  teacher,

  /// Moderator with moderation permissions (mute, kick).
  moderator,

  /// Administrator with all permissions.
  admin,
}

/// Extension methods for [ParticipantRole].
extension ParticipantRoleExtension on ParticipantRole {
  /// Converts role to API string value.
  String get apiValue {
    switch (this) {
      case ParticipantRole.student:
        return 'STUDENT';
      case ParticipantRole.teacher:
        return 'TEACHER';
      case ParticipantRole.moderator:
        return 'MODERATOR';
      case ParticipantRole.admin:
        return 'ADMIN';
    }
  }

  /// Creates role from API string value.
  static ParticipantRole fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'TEACHER':
        return ParticipantRole.teacher;
      case 'MODERATOR':
        return ParticipantRole.moderator;
      case 'ADMIN':
        return ParticipantRole.admin;
      default:
        return ParticipantRole.student;
    }
  }

  /// Whether this role has moderation permissions.
  bool get canModerate =>
      this == ParticipantRole.teacher ||
      this == ParticipantRole.moderator ||
      this == ParticipantRole.admin;

  /// Whether this role can control the room (end class, recording).
  bool get canControlRoom =>
      this == ParticipantRole.teacher || this == ParticipantRole.admin;

  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case ParticipantRole.student:
        return 'Student';
      case ParticipantRole.teacher:
        return 'Teacher';
      case ParticipantRole.moderator:
        return 'Moderator';
      case ParticipantRole.admin:
        return 'Admin';
    }
  }
}

/// Participant information for joining a classroom.
///
/// Contains identity, display info, and role assignment.
///
/// Example:
/// ```dart
/// final participant = Participant(
///   uid: 'user-123',
///   name: 'John Doe',
///   role: ParticipantRole.student,
///   photoUrl: 'https://example.com/photo.jpg',
/// );
/// ```
class Participant {
  /// Unique identifier for the participant.
  ///
  /// Should be consistent across sessions for the same user.
  /// Used for tracking attendance and permissions.
  final String uid;

  /// Display name shown in the classroom.
  final String name;

  /// Role determining permissions and UI features.
  final ParticipantRole role;

  /// Optional profile photo URL.
  ///
  /// Displayed in participant list and video tiles when camera is off.
  final String? photoUrl;

  /// Optional custom metadata attached to the participant.
  ///
  /// Can be used for additional application-specific data.
  final Map<String, dynamic>? metadata;

  /// Creates a new participant.
  const Participant({
    required this.uid,
    required this.name,
    this.role = ParticipantRole.student,
    this.photoUrl,
    this.metadata,
  });

  /// Creates a participant from JSON map.
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      uid: json['uid'] as String,
      name: json['name'] as String,
      role: ParticipantRoleExtension.fromApiValue(
        json['role'] as String? ?? 'STUDENT',
      ),
      photoUrl: json['photoUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts participant to JSON map for API requests.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'role': role.apiValue,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Creates a copy with modified fields.
  Participant copyWith({
    String? uid,
    String? name,
    ParticipantRole? role,
    String? photoUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Participant(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'Participant(uid: $uid, name: $name, role: ${role.displayName})';
}
