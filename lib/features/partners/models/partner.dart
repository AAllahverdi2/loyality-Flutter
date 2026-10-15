import 'package:loyallig_flutter/core/constants/api_endpoints.dart';

class PartnerDiscount {
  final String id;
  final String? offerTypeId;
  final String? offerTypeName;
  final String title;
  final num? discountPercent;
  final String? discountText;
  final String? startsAt;
  final String? endsAt;

  const PartnerDiscount({
    required this.id,
    this.offerTypeId,
    this.offerTypeName,
    required this.title,
    this.discountPercent,
    this.discountText,
    this.startsAt,
    this.endsAt,
  });

  factory PartnerDiscount.fromJson(Map<String, dynamic> json) {
    return PartnerDiscount(
      id: json['id']?.toString() ?? '',
      offerTypeId: json['offerTypeId']?.toString(),
      offerTypeName: json['offerTypeName']?.toString(),
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      discountPercent: json['discountPercent'] as num?,
      discountText: json['discountText']?.toString() ??
          json['discountRate']?.toString() ??
          (json['discountPercent'] != null
              ? '${json['discountPercent']}% Endirim'
              : null),
      startsAt: json['startsAt']?.toString(),
      endsAt: json['endsAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offerTypeId': offerTypeId,
      'offerTypeName': offerTypeName,
      'title': title,
      'discountPercent': discountPercent,
      'discountText': discountText,
      'startsAt': startsAt,
      'endsAt': endsAt,
    };
  }

  /// Kartın yuxarı küncündəki badge üçün mətn
  String get badgeText {
    if (title.trim().isNotEmpty) {
      return title.trim();
    }
    if (discountText != null && discountText!.trim().isNotEmpty) {
      return discountText!.trim();
    }
    return '';
  }
}

class Partner {
  final String id;
  final String? partnerCategoryId;
  final String? categoryName;
  final String? fileId;
  final String? fileName;
  final String name;
  final String? description;
  final String? discount;
  final String? discountTitle;
  final bool isFavorite;
  final List<PartnerDiscount> discounts;

  const Partner({
    required this.id,
    this.partnerCategoryId,
    this.categoryName,
    this.fileId,
    this.fileName,
    required this.name,
    this.description,
    this.discount,
    this.discountTitle,
    this.isFavorite = false,
    this.discounts = const [],
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    final List<PartnerDiscount> discountsList = [];
    if (json['discounts'] is List) {
      for (final item in json['discounts']) {
        if (item is Map) {
          discountsList.add(
            PartnerDiscount.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final discountTitle = json['discountTitle']?.toString();
    String? discountStr = discountTitle ??
        json['discount']?.toString() ??
        json['discountRate']?.toString() ??
        json['discountPercent']?.toString();
    if ((discountStr == null || discountStr.isEmpty) && discountsList.isNotEmpty) {
      discountStr = discountsList.first.badgeText;
    }

    return Partner(
      id: json['id']?.toString() ?? '',
      partnerCategoryId: json['partnerCategoryId']?.toString(),
      categoryName: json['categoryName']?.toString() ??
          json['partnerCategoryName']?.toString() ??
          json['category']?.toString(),
      fileId: json['fileId']?.toString(),
      fileName: json['fileName']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      discount: discountStr,
      discountTitle: discountTitle,
      isFavorite: json['isFavorite'] as bool? ?? false,
      discounts: discountsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerCategoryId': partnerCategoryId,
      'categoryName': categoryName,
      'fileId': fileId,
      'fileName': fileName,
      'name': name,
      'description': description,
      'discount': discount,
      'discountTitle': discountTitle,
      'isFavorite': isFavorite,
      'discounts': discounts.map((d) => d.toJson()).toList(),
    };
  }

  Partner copyWith({
    String? id,
    String? partnerCategoryId,
    String? categoryName,
    String? fileId,
    String? fileName,
    String? name,
    String? description,
    String? discount,
    String? discountTitle,
    bool? isFavorite,
    List<PartnerDiscount>? discounts,
  }) {
    return Partner(
      id: id ?? this.id,
      partnerCategoryId: partnerCategoryId ?? this.partnerCategoryId,
      categoryName: categoryName ?? this.categoryName,
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      name: name ?? this.name,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      discountTitle: discountTitle ?? this.discountTitle,
      isFavorite: isFavorite ?? this.isFavorite,
      discounts: discounts ?? this.discounts,
    );
  }

  /// Kartın üzərində görünəcək endirim mətni
  String? get displayDiscountBadge {
    if (discountTitle != null && discountTitle!.trim().isNotEmpty) {
      return discountTitle!.trim();
    }
    if (discount != null && discount!.trim().isNotEmpty) {
      return discount!.trim();
    }
    if (discounts.isNotEmpty) {
      return discounts.first.badgeText;
    }
    return null;
  }

  /// Şəklin yüklənməsi üçün tam URL (/api/File/download/{fileId})
  String? get imageUrl {
    if (fileId != null && fileId!.trim().isNotEmpty) {
      return '${ApiEndpoints.baseUrl}${ApiEndpoints.fileDownload(fileId!.trim())}';
    }
    return null;
  }
}
