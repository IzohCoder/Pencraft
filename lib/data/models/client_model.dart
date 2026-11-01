class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.taxId,
    required this.notes,
    required this.createdAt,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String taxId;
  final String notes;
  final int createdAt;
  final int? deletedAt;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
