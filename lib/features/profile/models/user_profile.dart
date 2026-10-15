import 'package:loyallig_flutter/core/constants/api_endpoints.dart';

class UserProfile {
  final String? id;
  final String? email;
  final String? phoneNumber;
  final String? barcode;
  final bool isPremium;
  final String? authProvider;
  final DateTime? lastLoginAt;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? birthDate;
  final dynamic gender;
  final String? genderName;
  final String? avatarFileId;
  final String? avatarFileName;

  const UserProfile({
    this.id,
    this.email,
    this.phoneNumber,
    this.barcode,
    this.isPremium = false,
    this.authProvider,
    this.lastLoginAt,
    this.firstName,
    this.lastName,
    this.fullName,
    this.birthDate,
    this.gender,
    this.genderName,
    this.avatarFileId,
    this.avatarFileName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      barcode: json['barcode'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      authProvider: json['authProvider'] as String?,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'].toString())
          : null,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      fullName: json['fullName'] as String?,
      birthDate: json['birthDate'] as String?,
      gender: json['gender'],
      genderName: json['genderName'] as String?,
      avatarFileId: json['avatarFileId'] as String?,
      avatarFileName: json['avatarFileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'barcode': barcode,
      'isPremium': isPremium,
      'authProvider': authProvider,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'birthDate': birthDate,
      'gender': gender,
      'genderName': genderName,
      'avatarFileId': avatarFileId,
      'avatarFileName': avatarFileName,
    };
  }

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    final combined = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (combined.isNotEmpty) return combined;
    if (email != null && email!.isNotEmpty) return email!;
    return 'İstifadəçi';
  }

  /// Profil şəklinin URL ünvanı (/api/File/download/{avatarFileId} və ya birbaşa URL)
  String? get avatarUrl {
    if (avatarFileName != null &&
        avatarFileName!.trim().isNotEmpty &&
        (avatarFileName!.startsWith('http://') ||
            avatarFileName!.startsWith('https://'))) {
      return avatarFileName!.trim();
    }
    if (avatarFileId != null && avatarFileId!.trim().isNotEmpty) {
      return '${ApiEndpoints.baseUrl}${ApiEndpoints.fileDownload(avatarFileId!.trim())}';
    }
    return null;
  }
}
