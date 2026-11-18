class ClaimProgram {
  const ClaimProgram({required this.code, required this.name, this.id});

  final String code;
  final String name;
  final String? id;

  bool get isChequeSante {
    final normalizedCode = code.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final normalizedName = name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return normalizedCode == 'CCS' || normalizedName == 'chequesante';
  }

  factory ClaimProgram.fromJson(Map<String, dynamic> json) => ClaimProgram(
    id: (json['idProgram'] ?? json['id'])?.toString(),
    code: json['code']?.toString() ?? '',
    name: (json['nameProgram'] ?? json['name'])?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is ClaimProgram && other.code == code && other.id == id;

  @override
  int get hashCode => Object.hash(code, id);
}
