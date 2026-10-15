class LookupItem {
  final String value;
  final String label;
  final bool disabled;

  const LookupItem({
    required this.value,
    required this.label,
    this.disabled = false,
  });

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      value: json['value']?.toString() ?? json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      disabled: json['disabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'disabled': disabled,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupItem &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
