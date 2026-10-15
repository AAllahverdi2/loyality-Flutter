class RefreshTokenRequest {
  final String accessToken;
  final String refreshToken;
  final String deviceId;
  final String deviceName;

  RefreshTokenRequest({
    required this.accessToken,
    required this.refreshToken,
    required this.deviceId,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) {
    return RefreshTokenRequest(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
    );
  }
}
