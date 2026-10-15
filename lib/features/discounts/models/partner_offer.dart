import 'package:loyallig_flutter/core/constants/api_endpoints.dart';

class PartnerOffer {
  final String id;
  final String? partnerId;
  final String? partnerName;
  final String? offerTypeId;
  final String? offerTypeName;
  final String title;
  final String? description;
  final num? discountPercent;
  final String? discountText;
  final String? fileId;
  final String? fileName;
  final String? startsAt;
  final String? endsAt;
  final bool isActive;
  final String? partnerCategoryId;
  final String? partnerCategoryName;

  const PartnerOffer({
    required this.id,
    this.partnerId,
    this.partnerName,
    this.offerTypeId,
    this.offerTypeName,
    required this.title,
    this.description,
    this.discountPercent,
    this.discountText,
    this.fileId,
    this.fileName,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
    this.partnerCategoryId,
    this.partnerCategoryName,
  });

  factory PartnerOffer.fromJson(Map<String, dynamic> json) {
    return PartnerOffer(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId']?.toString(),
      partnerName: json['partnerName']?.toString() ??
          (json['partner'] is Map ? json['partner']['name']?.toString() : null),
      offerTypeId: json['offerTypeId']?.toString(),
      offerTypeName: json['offerTypeName']?.toString() ??
          (json['offerType'] is Map
              ? json['offerType']['name']?.toString()
              : null),
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      discountPercent: json['discountPercent'] as num?,
      discountText: json['discountText']?.toString() ??
          json['discountRate']?.toString() ??
          (json['discountPercent'] != null
              ? '${json['discountPercent']}% Endirim'
              : null),
      fileId: json['fileId']?.toString() ??
          json['imageFileId']?.toString() ??
          (json['partner'] is Map
              ? json['partner']['fileId']?.toString()
              : null),
      fileName: json['fileName']?.toString(),
      startsAt: json['startsAt']?.toString(),
      endsAt: json['endsAt']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      partnerCategoryId: json['partnerCategoryId']?.toString(),
      partnerCategoryName: json['partnerCategoryName']?.toString() ??
          json['categoryName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'offerTypeId': offerTypeId,
      'offerTypeName': offerTypeName,
      'title': title,
      'description': description,
      'discountPercent': discountPercent,
      'discountText': discountText,
      'fileId': fileId,
      'fileName': fileName,
      'startsAt': startsAt,
      'endsAt': endsAt,
      'isActive': isActive,
      'partnerCategoryId': partnerCategoryId,
      'partnerCategoryName': partnerCategoryName,
    };
  }

  /// Şəklin yüklənməsi üçün URL (/api/File/download/{fileId})
  String? get imageUrl {
    if (fileId != null && fileId!.trim().isNotEmpty) {
      return '${ApiEndpoints.baseUrl}${ApiEndpoints.fileDownload(fileId!.trim())}';
    }
    return null;
  }

  /// Badge üçün mətn (məs: "10% Endirim" və ya "Xüsusi təklif")
  String get badgeText {
    if (discountText != null && discountText!.trim().isNotEmpty) {
      return discountText!.trim();
    }
    if (offerTypeName != null && offerTypeName!.trim().isNotEmpty) {
      return offerTypeName!.trim();
    }
    return title.trim();
  }
}
