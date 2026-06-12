class Family {
  const Family({required this.id, required this.name, required this.createdAt});

  final String id;
  final String name;
  final DateTime createdAt;

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsert() => {'name': name};
}
