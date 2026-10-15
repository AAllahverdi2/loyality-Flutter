class ResetPasswordRequest {
  final String resetToken;
  final String newPassword;
  final String confirmNewPassword;

  ResetPasswordRequest({
    required this.resetToken,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'resetToken': resetToken,
      'newPassword': newPassword,
      'confirmNewPassword': confirmNewPassword,
    };
  }

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) {
    return ResetPasswordRequest(
      resetToken: json['resetToken'] as String? ?? '',
      newPassword: json['newPassword'] as String? ?? '',
      confirmNewPassword: json['confirmNewPassword'] as String? ?? '',
    );
  }
}
