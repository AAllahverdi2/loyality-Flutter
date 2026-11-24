class AppleLoginRequest {
  final String identityToken;
  final String? firstName;
  final String? lastName;
  final String deviceId;
  final String deviceName;

  AppleLoginRequest({
    required this.identityToken,
    this.firstName,
    this.lastName,
    required this.deviceId,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'identityToken': identityToken,
      'firstName': firstName,
      'lastName': lastName,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }
}
