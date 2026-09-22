import '../models/association.dart';
import '../models/member.dart';
import '../models/registration.dart';

class MockSeed {
  static const Association association = Association(
    id: 'assoc-1',
    name: 'Cordova Fisherfolk Association (Demo)',
    municipality: 'Cordova',
    barangay: 'Poblacion',
    address: 'Poblacion, Cordova, Cebu',
    programType: 'SAAD Phase II',
    memberCount: 3,
    status: 'Active',
  );

  static final List<Member> members = [
    Member(
      id: 'member-1',
      firstName: 'Juan',
      middleName: 'Dela',
      lastName: 'Cruz',
      birthday: DateTime(1985, 5, 14),
      sex: 'Male',
      roleInAssociation: 'Member',
      beneficiaryType: 'Fisherfolk',
      status: 'Active',
    ),
    Member(
      id: 'member-2',
      firstName: 'Maria',
      middleName: 'Santos',
      lastName: 'Reyes',
      birthday: DateTime(1990, 9, 22),
      sex: 'Female',
      roleInAssociation: 'Member',
      beneficiaryType: 'Fisherfolk',
      status: 'Active',
    ),
    Member(
      id: 'member-3',
      firstName: 'Pedro',
      middleName: '',
      lastName: 'Garcia',
      birthday: DateTime(1978, 2, 8),
      sex: 'Male',
      roleInAssociation: 'Treasurer',
      beneficiaryType: 'Fisherfolk',
      status: 'Active',
    ),
  ];

  static final List<Registration> registrations = [
    Registration(
      id: 'application-1',
      submittedAt: DateTime(2026, 9, 1),
      firstName: 'Ana',
      middleName: 'Lopez',
      lastName: 'Cruz',
      birthday: DateTime(1994, 3, 18),
      sex: 'Female',
      beneficiaryType: 'Fisherfolk',
    ),
  ];
}
