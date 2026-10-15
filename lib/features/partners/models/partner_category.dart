class PartnerCategory {
  final String id;
  final String name;

  const PartnerCategory({
    required this.id,
    required this.name,
  });

  factory PartnerCategory.fromJson(Map<String, dynamic> json) {
    return PartnerCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
