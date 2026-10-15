class SendRegisterCodeRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String lastName;

  SendRegisterCodeRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  factory SendRegisterCodeRequest.fromJson(Map<String, dynamic> json) {
    return SendRegisterCodeRequest(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      confirmPassword: json['confirmPassword'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
    );
  }
}
