class Diagnosis {
  final String code;
  final String name;

  const Diagnosis({required this.code, required this.name});

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? json['display']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  @override
  String toString() => '$code - $name';
}
