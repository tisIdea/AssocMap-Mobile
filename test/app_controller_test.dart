import 'dart:async';
import 'package:assocmap_mobile_app/models/registration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assocmap_mobile_app/controllers/app_controller.dart';
import 'package:assocmap_mobile_app/repositories/assoc_repository.dart';
import 'package:assocmap_mobile_app/repositories/mock_assoc_repository.dart';

class DelayedRepository extends MockAssocRepository
    implements PersistentSessionRepository {
  Completer<MemberData>? pending;
  RepositoryException? failure;
  final events = StreamController<bool>.broadcast(sync: true);
  @override
  Stream<bool> get sessionChanges => events.stream;
  @override
  Future<Session?> restoreSession() async => null;
  @override
  Future<MemberData> getMemberData() => failure != null
      ? Future.error(failure!)
      : pending?.future ?? super.getMemberData();
}

void main() {
  test(
    'logout discards cached records and a late response cannot repopulate them',
    () async {
      final repository = DelayedRepository();
      final controller = AppController(repository);
      await controller.login('member@assocmap.test', 'AssocMap123!');
      final oldData = controller.data!;
      repository.pending = Completer<MemberData>();
      final refresh = controller.refresh();
      await controller.logout();
      expect(controller.session, isNull);
      expect(controller.data, isNull);
      repository.pending!.complete(oldData);
      await refresh;
      expect(controller.data, isNull);
      controller.dispose();
      await repository.events.close();
    },
  );

  test('external sign-out immediately removes private state', () async {
    final repository = DelayedRepository();
    final controller = AppController(repository);
    await controller.login('member@assocmap.test', 'AssocMap123!');
    expect(controller.data, isNotNull);
    repository.events.add(false);
    expect(controller.session, isNull);
    expect(controller.data, isNull);
    controller.dispose();
    await repository.events.close();
  });
  test('access revocation clears private state and returns to login', () async {
    final repository = DelayedRepository();
    final controller = AppController(repository);
    await controller.login('member@assocmap.test', 'AssocMap123!');
    repository.failure = const AccessRevokedException('Account disabled');
    await controller.refresh();
    expect(controller.session, isNull);
    expect(controller.data, isNull);
    expect(controller.error, 'Account disabled');
    controller.dispose();
    await repository.events.close();
  });

  test(
    'successful submission remains visible if subsequent refresh is offline',
    () async {
      final repository = DelayedRepository();
      final controller = AppController(repository);
      await controller.login('member@assocmap.test', 'AssocMap123!');
      repository.failure = const RepositoryException('Connection unavailable');
      final saved = await controller.register(
        Registration(
          associationId: controller.session!.associationId,
          firstName: 'Offline',
          middleName: '',
          lastName: 'Receipt',
          birthday: DateTime(1990),
          sex: 'Female',
          beneficiaryType: '',
        ),
      );
      expect(
        controller.data!.registrations.any((r) => r.id == saved.id),
        isTrue,
      );
      expect(controller.session, isNotNull);
      expect(controller.error, 'Connection unavailable');
      controller.dispose();
      await repository.events.close();
    },
  );
}
