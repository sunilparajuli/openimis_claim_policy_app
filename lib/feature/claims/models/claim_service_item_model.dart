class MedicalService {
  final String code;
  final String name;
  final double price;
  final String? category;

  const MedicalService({
    required this.code,
    required this.name,
    required this.price,
    this.category,
  });

  factory MedicalService.fromJson(Map<String, dynamic> json) {
    return MedicalService(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _jsonDouble(json['price']),
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'price': price,
    'category': category,
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
        code: json['serviceCode'] as String? ?? '',
        name: json['serviceName'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'serviceCode': service.code,
    'serviceName': service.name,
    'quantity': quantity,
    'price': price,
    'total': total,
  };
}

class MedicationItem {
  final String code;
  final String name;
  final double price;
  final String? unit;

  const MedicationItem({
    required this.code,
    required this.name,
    required this.price,
    this.unit,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _jsonDouble(json['price']),
      unit: json['unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'price': price,
    'unit': unit,
  };
}

double _jsonDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
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
        code: json['itemCode'] as String? ?? '',
        name: json['itemName'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemCode': item.code,
    'itemName': item.name,
    'quantity': quantity,
    'price': price,
    'total': total,
  };
}
