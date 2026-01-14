/// Organization information for branding.
///
/// Used to customize the classroom UI with organization branding.
class OrganizationInfo {
  /// Organization display name.
  final String? name;

  /// Logo URL for header display.
  final String? logoUrl;

  /// Optional slogan or tagline.
  final String? slogan;

  /// Creates organization info.
  const OrganizationInfo({
    this.name,
    this.logoUrl,
    this.slogan,
  });

  /// Creates from JSON map.
  factory OrganizationInfo.fromJson(Map<String, dynamic> json) {
    return OrganizationInfo(
      name: json['name'] as String?,
      logoUrl: json['logoUrl'] as String?,
      slogan: json['slogan'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (slogan != null) 'slogan': slogan,
    };
  }

  /// Creates a copy with modified fields.
  OrganizationInfo copyWith({
    String? name,
    String? logoUrl,
    String? slogan,
  }) {
    return OrganizationInfo(
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      slogan: slogan ?? this.slogan,
    );
  }

  @override
  String toString() => 'OrganizationInfo(name: $name)';
}
