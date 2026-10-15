/// Google Sign-In Konfiqurasiyası
///
/// Backend-in Google idToken-i yoxlaya (verify edə) bilməsi üçün Google Cloud Console-da
/// yaradılmış "Web Application" tipli OAuth 2.0 Client ID-ni (serverClientId)
/// mütləq aşağıdakı sahəyə daxil edin.
class GoogleAuthConfig {
  /// [VACİB] Backend / Google Cloud Console tərəfindən verilən "Web Client ID":
  static const String webClientId =
      '642188098259-91mrb7212dme9ukd50h9e5rsrsa5em7e.apps.googleusercontent.com';

  /// Client ID-ni təmizlənmiş şəkildə qaytarır (əgər https:// və ya son slash əlavə olunubsa onları təmizləyir)
  static String get cleanWebClientId {
    String cleaned = webClientId.trim();
    if (cleaned.startsWith('https://')) {
      cleaned = cleaned.substring('https://'.length);
    } else if (cleaned.startsWith('http://')) {
      cleaned = cleaned.substring('http://'.length);
    }
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  /// iOS üçün xüsusi Client ID:
  static const String iosClientId =
      '642188098259-3me4972c2bmq0r4nl9d6vk142i06pie8.apps.googleusercontent.com';
}
