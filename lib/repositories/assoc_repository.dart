import '../models/association.dart';
import '../models/member.dart';
import '../models/registration.dart';
import '../models/program.dart';

class MemberData {
  final Association association;
  final List<Member> members;
  final List<Registration> registrations;
  final List<Project> projects;
  final List<Training> trainings;
  const MemberData({
    required this.association,
    required this.members,
    required this.registrations,
    required this.projects,
    required this.trainings,
  });
}

class Session {
  final String id, name, email, associationId;
  const Session({
    required this.id,
    required this.name,
    required this.email,
    required this.associationId,
  });
}

class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);
  @override
  String toString() => message;
}

// Replace with API/database implementation at the app composition root.
abstract interface class AssocRepository {
  Future<Session> login(String email, String password);
  Future<void> logout();
  Future<MemberData> getMemberData();
  Future<Registration> submitRegistration(Registration registration);
  Future<List<PublicLocation>> getPublicLocations();
}
