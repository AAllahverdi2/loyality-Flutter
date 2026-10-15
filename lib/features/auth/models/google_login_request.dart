class GoogleLoginRequest {
  final String idToken;
  final String deviceId;
  final String deviceName;

  GoogleLoginRequest({
    required this.idToken,
    required this.deviceId,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }

  factory GoogleLoginRequest.fromJson(Map<String, dynamic> json) {
    return GoogleLoginRequest(
      idToken: json['idToken'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
    );
  }
}
