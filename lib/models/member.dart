class Member {
  final String id;
  final String associationId;

  final String firstName;
  final String middleName;
  final String lastName;
  final DateTime birthday;
  final String sex;
  final String roleInAssociation;
  final String beneficiaryType;
  final String status;

  const Member({
    this.id = "",
    this.associationId = "assoc-1",

    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
    required this.sex,
    required this.roleInAssociation,
    required this.beneficiaryType,
    required this.status,
  });

  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].where((part) => part.trim().isNotEmpty).join(' ');
}
