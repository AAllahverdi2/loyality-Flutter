class TermsAndCondition {
  final String id;
  final String title;
  final String? description;
  final bool isActive;
  final int sortOrder;
  final DateTime? updatedDate;

  const TermsAndCondition({
    required this.id,
    required this.title,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
    this.updatedDate,
  });

  static bool _parseBool(dynamic value, {bool defaultValue = true}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final lower = value.toString().trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    return defaultValue;
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? defaultValue;
  }

  factory TermsAndCondition.fromJson(Map<String, dynamic> json) {
    final rawDate =
        json['updatedDate'] ??
        json['updatedAt'] ??
        json['modifiedDate'] ??
        json['createdDate'] ??
        json['createdAt'];

    return TermsAndCondition(
      id: (json['id'] ?? json['termsAndConditionId'])?.toString() ?? '',
      title:
          (json['title'] ??
                  json['name'] ??
                  json['heading'] ??
                  json['header'] ??
                  json['subject'])
              ?.toString() ??
          '',
      description:
          (json['description'] ??
                  json['content'] ??
                  json['body'] ??
                  json['text'] ??
                  json['htmlContent'] ??
                  json['value'])
              ?.toString(),
      isActive: _parseBool(json['isActive'] ?? json['active']),
      sortOrder: _parseInt(
        json['sortOrder'] ?? json['order'] ?? json['displayOrder'],
      ),
      updatedDate: rawDate != null
          ? DateTime.tryParse(rawDate.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedDate': updatedDate?.toIso8601String(),
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
