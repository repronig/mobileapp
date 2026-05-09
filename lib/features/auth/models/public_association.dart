class PublicAssociation {
  const PublicAssociation({required this.id, required this.name});

  factory PublicAssociation.fromJson(Map<String, dynamic> json) {
    return PublicAssociation(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  final int id;
  final String name;
}
