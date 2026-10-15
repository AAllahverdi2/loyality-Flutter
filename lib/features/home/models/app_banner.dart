import 'package:loyallig_flutter/core/constants/api_endpoints.dart';

class AppBanner {
  final String id;
  final String? title;
  final String? subtitle;
  final String? fileId;
  final String? fileName;
  final String? redirectUrl;
  final int sortOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  const AppBanner({
    required this.id,
    this.title,
    this.subtitle,
    this.fileId,
    this.fileName,
    this.redirectUrl,
    this.sortOrder = 0,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json) {
    return AppBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      fileId: json['fileId']?.toString(),
      fileName: json['fileName']?.toString(),
      redirectUrl: json['redirectUrl']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'].toString())
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString())
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'fileId': fileId,
      'fileName': fileName,
      'redirectUrl': redirectUrl,
      'sortOrder': sortOrder,
      'startsAt': startsAt?.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Banner şəklinin tam yüklənmə URL-i (/api/File/download/{fileId})
  String? get imageUrl {
    if (fileId != null && fileId!.trim().isNotEmpty) {
      return '${ApiEndpoints.baseUrl}${ApiEndpoints.fileDownload(fileId!.trim())}';
    }
    return null;
  }
}
