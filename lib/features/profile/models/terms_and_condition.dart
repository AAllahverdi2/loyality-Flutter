class TermsAndCondition {
  final String id;
  final String title;
  final String? description;
  final bool isActive;

  const TermsAndCondition({
    required this.id,
    required this.title,
    this.description,
    this.isActive = true,
  });

  factory TermsAndCondition.fromJson(Map<String, dynamic> json) {
    return TermsAndCondition(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isActive': isActive,
    };
  }

  /// Təmiz mətn - HTML teqlərini və xüsusi simvolları təmizləyir
  String get plainDescription {
    if (description == null || description!.trim().isEmpty) return '';
    return description!
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
