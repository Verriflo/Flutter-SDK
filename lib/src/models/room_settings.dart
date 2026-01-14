/// Room settings for creating or configuring a classroom.
///
/// Contains metadata and constraints for the room.
class RoomSettings {
  /// Display title for the classroom.
  final String? title;

  /// Optional description of the class.
  final String? description;

  /// Maximum number of participants allowed.
  ///
  /// Set to `null` for unlimited (subject to plan limits).
  final int? maxParticipants;

  /// Whether the room should auto-close when empty.
  ///
  /// Default: `false`
  final bool autoClose;

  /// Creates room settings.
  const RoomSettings({
    this.title,
    this.description,
    this.maxParticipants,
    this.autoClose = false,
  });

  /// Creates from JSON map.
  factory RoomSettings.fromJson(Map<String, dynamic> json) {
    return RoomSettings(
      title: json['title'] as String?,
      description: json['description'] as String?,
      maxParticipants: json['maxParticipants'] as int?,
      autoClose: json['autoClose'] as bool? ?? false,
    );
  }

  /// Converts to JSON map for API request.
  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (autoClose) 'autoClose': autoClose,
      // Note: emptyTimeout is handled separately in CreateRoomRequest
    };
  }

  /// Creates a copy with modified fields.
  RoomSettings copyWith({
    String? title,
    String? description,
    int? maxParticipants,
    bool? autoClose,
  }) {
    return RoomSettings(
      title: title ?? this.title,
      description: description ?? this.description,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      autoClose: autoClose ?? this.autoClose,
    );
  }

  @override
  String toString() =>
      'RoomSettings(title: $title, maxParticipants: $maxParticipants)';
}
