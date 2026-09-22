class Registration {
  final String id;
  final String associationId;

  final String firstName;
  final String middleName;
  final String lastName;
  final DateTime birthday;
  final String sex;
  final String beneficiaryType;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const Registration({
    this.id = "",
    this.associationId = "assoc-1",

    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
    required this.sex,
    required this.beneficiaryType,
    this.status = 'Pending',
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].where((part) => part.trim().isNotEmpty).join(' ');
}
