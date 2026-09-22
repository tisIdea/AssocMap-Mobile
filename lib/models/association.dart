class Association {
  final String id;

  final String name;
  final String municipality;
  final String barangay;
  final String address;
  final String programType;
  final int memberCount;
  final String status;

  const Association({
    this.id = "",

    required this.name,
    required this.municipality,
    required this.barangay,
    required this.address,
    required this.programType,
    required this.memberCount,
    required this.status,
  });
}
