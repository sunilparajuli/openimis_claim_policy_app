class MedicalService {
  final String? id;
  final String code;
  final String name;
  final double price;
  final String? category;
  final String? programCode;

  const MedicalService({
    this.id,
    required this.code,
    required this.name,
    required this.price,
    this.category,
    this.programCode,
  });

  factory MedicalService.fromJson(Map<String, dynamic> json) {
    return MedicalService(
      id: json['id']?.toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _jsonDouble(json['price']),
      category: json['category']?.toString(),
      programCode: _programCode(json['program'] ?? json['programCode']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'price': price,
    'category': category,
    'programCode': programCode,
  };
}

class ClaimedService {
  final MedicalService service;
  int quantity;
  double price;

  ClaimedService({required this.service, this.quantity = 1, double? price})
    : price = price ?? service.price;

  double get total => quantity * price;

  factory ClaimedService.fromJson(Map<String, dynamic> json) {
    return ClaimedService(
      service: MedicalService(
        id: json['serviceId']?.toString(),
        code: json['serviceCode'] as String? ?? '',
        name: json['serviceName'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        programCode: json['programCode'] as String?,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'serviceId': service.id,
    'serviceCode': service.code,
    'serviceName': service.name,
    'programCode': service.programCode,
    'quantity': quantity,
    'price': price,
    'total': total,
  };
}

class MedicationItem {
  final String? id;
  final String code;
  final String name;
  final double price;
  final String? unit;
  final String? programCode;

  const MedicationItem({
    this.id,
    required this.code,
    required this.name,
    required this.price,
    this.unit,
    this.programCode,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      id: json['id']?.toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _jsonDouble(json['price']),
      unit: json['unit']?.toString(),
      programCode: _programCode(json['program'] ?? json['programCode']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'price': price,
    'unit': unit,
    'programCode': programCode,
  };
}

double _jsonDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

String? _programCode(dynamic value) {
  if (value is Map) {
    return (value['code'] ?? value['idProgram'])?.toString();
  }
  return value?.toString();
}

class ClaimedItem {
  final MedicationItem item;
  int quantity;
  double price;

  ClaimedItem({required this.item, this.quantity = 1, double? price})
    : price = price ?? item.price;

  double get total => quantity * price;

  factory ClaimedItem.fromJson(Map<String, dynamic> json) {
    return ClaimedItem(
      item: MedicationItem(
        id: json['itemId']?.toString(),
        code: json['itemCode'] as String? ?? '',
        name: json['itemName'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        programCode: json['programCode'] as String?,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': item.id,
    'itemCode': item.code,
    'itemName': item.name,
    'programCode': item.programCode,
    'quantity': quantity,
    'price': price,
    'total': total,
  };
}
