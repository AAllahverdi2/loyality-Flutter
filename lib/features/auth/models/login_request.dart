class LoginRequest {
  final String email;
  final String password;
  final String deviceId;
  final String deviceName;

  LoginRequest({
    required this.email,
    required this.password,
    required this.deviceId,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? 'mobile_device',
      deviceName: json['deviceName'] as String? ?? 'Flutter Mobile',
    );
  }
}
