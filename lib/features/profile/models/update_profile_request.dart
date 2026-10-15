class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? birthDate;
  final int? gender;
  final String? avatarFileId;
  final String? phoneNumber;

  const UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.birthDate,
    this.gender,
    this.avatarFileId,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'birthDate': birthDate,
      'gender': gender,
      'avatarFileId': avatarFileId,
      'phoneNumber': phoneNumber,
    };
  }
}
