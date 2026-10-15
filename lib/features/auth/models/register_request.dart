class RegisterRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String lastName;
  final String otpCode;
  final String deviceId;
  final String deviceName;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
    required this.otpCode,
    required this.deviceId,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'firstName': firstName,
      'lastName': lastName,
      'otpCode': otpCode,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      confirmPassword: json['confirmPassword'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      otpCode: json['otpCode'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? 'mobile_device',
      deviceName: json['deviceName'] as String? ?? 'Flutter Mobile',
    );
  }
}
