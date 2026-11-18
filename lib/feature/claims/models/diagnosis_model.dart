class Diagnosis {
  final String? id;
  final String code;
  final String name;

  const Diagnosis({this.id, required this.code, required this.name});

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id']?.toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? json['display']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name': name};

  @override
  String toString() => '$code - $name';
}
