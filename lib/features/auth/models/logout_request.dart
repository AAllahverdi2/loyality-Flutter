class LogoutRequest {
  final String refreshToken;

  LogoutRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }

  factory LogoutRequest.fromJson(Map<String, dynamic> json) {
    return LogoutRequest(
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }
}
