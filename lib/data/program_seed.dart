import '../models/program.dart';
import '../models/registration.dart';

class ProgramSeed {
  static final projects = <Project>[
    Project(
      id: 'project-1',
      associationId: 'assoc-1',
      title: 'Bangus livelihood development',
      commodity: 'Bangus',
      component: 'SAAD Phase II',
      status: 'Ongoing',
      implementationDate: DateTime(2026, 2, 10),
      materials: [
        ProjectMaterial(
          id: 'material-1',
          name: 'Bangus fingerlings',
          unit: 'pieces',
          status: 'Delivered',
          quantity: 5000,
          unitCost: 5,
          deliveryDate: DateTime(2026, 2, 12),
        ),
        const ProjectMaterial(
          id: 'material-2',
          name: 'Grower feeds',
          unit: 'bags',
          status: 'Pending',
          quantity: 30,
          unitCost: 1200,
        ),
      ],
    ),
    Project(
      id: 'project-2',
      associationId: 'assoc-1',
      title: 'Seaweed culture inputs',
      commodity: 'Seaweed',
      component: 'SAAD Phase II',
      status: 'Completed',
      implementationDate: DateTime(2025, 8, 15),
      materials: [
        ProjectMaterial(
          id: 'material-3',
          name: 'Culture ropes',
          unit: 'rolls',
          status: 'Delivered',
          quantity: 20,
          unitCost: 800,
          deliveryDate: DateTime(2025, 8, 15),
        ),
      ],
    ),
  ];
  static final trainings = <Training>[
    Training(
      id: 'training-1',
      associationId: 'assoc-1',
      title: 'Bangus culture and feeding management',
      component: 'Technical training',
      date: DateTime(2026, 2, 8),
      cost: 12000,
      participants: const [
        TrainingParticipant('member-1', 'Present'),
        TrainingParticipant('member-2', 'Present'),
        TrainingParticipant('member-3', 'Absent'),
      ],
    ),
    Training(
      id: 'training-2',
      associationId: 'assoc-1',
      title: 'Association record keeping',
      component: 'Capacity building',
      date: DateTime(2026, 4, 20),
      cost: 8500,
      participants: const [
        TrainingParticipant('member-1', 'Present'),
        TrainingParticipant('member-3', 'Present'),
      ],
    ),
  ];
  static final reviewedApplications = <Registration>[
    Registration(
      id: 'application-2',
      firstName: 'Maria',
      middleName: 'Santos',
      lastName: 'Reyes',
      birthday: DateTime(1990, 9, 22),
      sex: 'Female',
      beneficiaryType: 'Fisherfolk',
      status: 'Approved',
      submittedAt: DateTime(2026, 1, 5),
      reviewedAt: DateTime(2026, 1, 8),
    ),
    Registration(
      id: 'application-3',
      firstName: 'Ramon',
      middleName: '',
      lastName: 'Bautista',
      birthday: DateTime(1988, 6, 12),
      sex: 'Male',
      beneficiaryType: 'Fisherfolk',
      status: 'Rejected',
      submittedAt: DateTime(2026, 8, 10),
      reviewedAt: DateTime(2026, 8, 14),
      rejectionReason:
          'Membership information could not be confirmed. Contact the assigned Field Officer.',
    ),
  ];
  static const locations = <PublicLocation>[
    PublicLocation(
      id: 'location-1',
      associationId: 'assoc-1',
      name: 'Bangus demonstration site',
      associationName: 'Cordova Fisherfolk Association (Demo)',
      municipality: 'Cordova',
      barangay: 'Poblacion',
      commodity: 'Bangus',
      program: 'SAAD Phase II',
      activities: 'Bangus culture and technical training',
      latitude: 10.251,
      longitude: 123.950,
      published: true,
    ),
    PublicLocation(
      id: 'location-2',
      associationId: 'assoc-1',
      name: 'Seaweed demonstration site',
      associationName: 'Cordova Fisherfolk Association (Demo)',
      municipality: 'Cordova',
      barangay: 'Poblacion',
      commodity: 'Seaweed',
      program: 'SAAD Phase II',
      activities: 'Seaweed culture inputs and capacity building',
      latitude: 10.240,
      longitude: 123.945,
      published: true,
    ),
    PublicLocation(
      id: 'location-3',
      associationId: 'assoc-1',
      name: 'Unverified site',
      associationName: 'Cordova Fisherfolk Association (Demo)',
      municipality: 'Cordova',
      barangay: 'Poblacion',
      commodity: 'Tilapia',
      program: 'SAAD Phase II',
      activities: 'Unpublished draft',
      latitude: 10.260,
      longitude: 123.955,
      published: false,
    ),
  ];
}
