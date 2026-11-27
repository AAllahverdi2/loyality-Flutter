/// Google Sign-In Konfiqurasiyası
///
/// Backend-in Google idToken-i yoxlaya (verify edə) bilməsi üçün Google Cloud Console-da
/// yaradılmış "Web Application" tipli OAuth 2.0 Client ID-ni (serverClientId)
/// mütləq aşağıdakı sahəyə daxil edin.
class GoogleAuthConfig {
  /// [VACİB] Backend / Google Cloud Console tərəfindən verilən "Web Client ID":
  static const String webClientId =
      '64040398606-ajafqaibi0vvbd38d649kvecb9hn42bi.apps.googleusercontent.com';

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
      '64040398606-nbai3eq756196or5pe8138lqvmcgt6r4.apps.googleusercontent.com';
}
