/// UI customization options for the Verriflo classroom.
///
/// Controls visibility and behavior of various UI elements.
/// All options have sensible defaults for a full-featured classroom.
///
/// Example:
/// ```dart
/// final customization = Customization(
///   showLobby: true,
///   needChat: true,
///   allowHandRaise: true,
///   theme: ClassroomTheme.dark,
/// );
/// ```
class Customization {
  /// Show the lobby screen before joining.
  ///
  /// When `true`, participants see a preview screen with device
  /// selection before entering. Set to `false` for instant join.
  ///
  /// Default: `true`
  final bool showLobby;

  /// Show the class title in the header.
  ///
  /// Default: `true`
  final bool showClassTitle;

  /// Show the organization logo in the header.
  ///
  /// Default: `true`
  final bool showLogo;

  /// Show the header bar with title and logo.
  ///
  /// Default: `true`
  final bool showHeader;

  /// Show participant names on video tiles.
  ///
  /// Default: `true`
  final bool showParticipantName;

  /// Show microphone status indicator on tiles.
  ///
  /// Default: `true`
  final bool showMicIndicator;

  /// Enable the chat feature.
  ///
  /// Default: `true`
  final bool needChat;

  /// Show the bottom control bar.
  ///
  /// Set to `false` to implement custom controls via the controller.
  ///
  /// Default: `true`
  final bool needControlbar;

  /// Allow participants to share their screen.
  ///
  /// Default: `true`
  final bool allowScreenShare;

  /// Allow students to raise their hand.
  ///
  /// Default: `true`
  final bool allowHandRaise;

  /// Allow teachers to record the session.
  ///
  /// Default: `true`
  final bool allowRecording;

  /// Allow RTMP ingress/streaming.
  ///
  /// Default: `true`
  final bool allowIngress;

  /// Validate embedding domain against allowlist.
  ///
  /// Default: `true`
  final bool validateDomain;

  /// UI theme preference.
  ///
  /// Default: [ClassroomTheme.system]
  final ClassroomTheme theme;

  /// Creates customization with specified options.
  const Customization({
    this.showLobby = true,
    this.showClassTitle = true,
    this.showLogo = true,
    this.showHeader = true,
    this.showParticipantName = true,
    this.showMicIndicator = true,
    this.needChat = true,
    this.needControlbar = true,
    this.allowScreenShare = true,
    this.allowHandRaise = true,
    this.allowRecording = true,
    this.allowIngress = true,
    this.validateDomain = true,
    this.theme = ClassroomTheme.system,
  });

  /// Creates a minimal viewer customization.
  ///
  /// Disables lobby, controls, and most interactive features.
  /// Suitable for embedded viewer-only experiences.
  const Customization.viewer()
      : showLobby = false,
        showClassTitle = true,
        showLogo = true,
        showHeader = true,
        showParticipantName = true,
        showMicIndicator = true,
        needChat = false,
        needControlbar = false,
        allowScreenShare = false,
        allowHandRaise = false,
        allowRecording = false,
        allowIngress = false,
        validateDomain = true,
        theme = ClassroomTheme.system;

  /// Creates customization from JSON map.
  factory Customization.fromJson(Map<String, dynamic> json) {
    return Customization(
      showLobby: json['showLobby'] as bool? ?? true,
      showClassTitle: json['showClassTitle'] as bool? ?? true,
      showLogo: json['showLogo'] as bool? ?? true,
      showHeader: json['showHeader'] as bool? ?? true,
      showParticipantName: json['showParticipantName'] as bool? ?? true,
      showMicIndicator: json['showMicIndicator'] as bool? ?? true,
      needChat: json['needChat'] as bool? ?? true,
      needControlbar: json['needControlbar'] as bool? ?? true,
      allowScreenShare: json['allowScreenShare'] as bool? ?? true,
      allowHandRaise: json['allowHandRaise'] as bool? ?? true,
      allowRecording: json['allowRecording'] as bool? ?? true,
      allowIngress: json['allowIngress'] as bool? ?? true,
      validateDomain: json['validateDomain'] as bool? ?? true,
      theme: ClassroomThemeExtension.fromApiValue(
        json['theme'] as String? ?? 'system',
      ),
    );
  }

  /// Converts to JSON map for API requests.
  Map<String, dynamic> toJson() {
    return {
      'showLobby': showLobby,
      'showClassTitle': showClassTitle,
      'showLogo': showLogo,
      'showHeader': showHeader,
      'showParticipantName': showParticipantName,
      'showMicIndicator': showMicIndicator,
      'needChat': needChat,
      'needControlbar': needControlbar,
      'allowScreenShare': allowScreenShare,
      'allowHandRaise': allowHandRaise,
      'allowRecording': allowRecording,
      'allowIngress': allowIngress,
      'validateDomain': validateDomain,
      'theme': theme.apiValue,
    };
  }

  /// Creates a copy with modified fields.
  Customization copyWith({
    bool? showLobby,
    bool? showClassTitle,
    bool? showLogo,
    bool? showHeader,
    bool? showParticipantName,
    bool? showMicIndicator,
    bool? needChat,
    bool? needControlbar,
    bool? allowScreenShare,
    bool? allowHandRaise,
    bool? allowRecording,
    bool? allowIngress,
    bool? validateDomain,
    ClassroomTheme? theme,
  }) {
    return Customization(
      showLobby: showLobby ?? this.showLobby,
      showClassTitle: showClassTitle ?? this.showClassTitle,
      showLogo: showLogo ?? this.showLogo,
      showHeader: showHeader ?? this.showHeader,
      showParticipantName: showParticipantName ?? this.showParticipantName,
      showMicIndicator: showMicIndicator ?? this.showMicIndicator,
      needChat: needChat ?? this.needChat,
      needControlbar: needControlbar ?? this.needControlbar,
      allowScreenShare: allowScreenShare ?? this.allowScreenShare,
      allowHandRaise: allowHandRaise ?? this.allowHandRaise,
      allowRecording: allowRecording ?? this.allowRecording,
      allowIngress: allowIngress ?? this.allowIngress,
      validateDomain: validateDomain ?? this.validateDomain,
      theme: theme ?? this.theme,
    );
  }

  @override
  String toString() =>
      'Customization(lobby: $showLobby, chat: $needChat, theme: ${theme.apiValue})';
}

/// Theme options for the classroom UI.
enum ClassroomTheme {
  /// Light theme with white backgrounds.
  light,

  /// Dark theme with dark backgrounds.
  dark,

  /// Follow system preference.
  system,
}

/// Extension methods for [ClassroomTheme].
extension ClassroomThemeExtension on ClassroomTheme {
  /// Converts to API string value.
  String get apiValue {
    switch (this) {
      case ClassroomTheme.light:
        return 'light';
      case ClassroomTheme.dark:
        return 'dark';
      case ClassroomTheme.system:
        return 'system';
    }
  }

  /// Creates from API string value.
  static ClassroomTheme fromApiValue(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ClassroomTheme.light;
      case 'dark':
        return ClassroomTheme.dark;
      default:
        return ClassroomTheme.system;
    }
  }
}
