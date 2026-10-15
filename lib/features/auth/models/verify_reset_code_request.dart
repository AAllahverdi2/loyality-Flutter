class VerifyResetCodeRequest {
  final String email;
  final String code;

  VerifyResetCodeRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
    };
  }

  factory VerifyResetCodeRequest.fromJson(Map<String, dynamic> json) {
    return VerifyResetCodeRequest(
      email: json['email'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}
