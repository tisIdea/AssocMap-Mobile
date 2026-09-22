class ProjectMaterial {
  final String id, name, unit, status;
  final double quantity, unitCost;
  final DateTime? deliveryDate;
  const ProjectMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.status,
    required this.quantity,
    required this.unitCost,
    this.deliveryDate,
  });
}

class Project {
  final String id, associationId, title, commodity, component, status;
  final DateTime implementationDate;
  final List<ProjectMaterial> materials;
  const Project({
    required this.id,
    required this.associationId,
    required this.title,
    required this.commodity,
    required this.component,
    required this.status,
    required this.implementationDate,
    required this.materials,
  });
}

class TrainingParticipant {
  final String memberId, attendance;
  const TrainingParticipant(this.memberId, this.attendance);
}

class Training {
  final String id, associationId, title, component;
  final DateTime date;
  final double cost;
  final List<TrainingParticipant> participants;
  const Training({
    required this.id,
    required this.associationId,
    required this.title,
    required this.component,
    required this.date,
    required this.cost,
    required this.participants,
  });
}

class PublicLocation {
  final String id, associationId, name, associationName, municipality, barangay;
  final String commodity, program, activities;
  final double latitude, longitude;
  final bool published;
  const PublicLocation({
    required this.id,
    required this.associationId,
    required this.name,
    required this.associationName,
    required this.municipality,
    required this.barangay,
    required this.commodity,
    required this.program,
    required this.activities,
    required this.latitude,
    required this.longitude,
    required this.published,
  });
}
