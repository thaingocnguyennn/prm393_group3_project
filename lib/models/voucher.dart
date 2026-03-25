class Voucher {
  final int? id;
  final String code;
  final String description;
  final double discountPercent;
  final double minOrderAmount;
  final bool isActive;

  Voucher({
    this.id,
    required this.code,
    required this.description,
    required this.discountPercent,
    required this.minOrderAmount,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code.trim().toUpperCase(),
      'description': description,
      'discountPercent': discountPercent,
      'minOrderAmount': minOrderAmount,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'] as int?,
      code: map['code'] as String,
      description: map['description'] as String,
      discountPercent: (map['discountPercent'] as num).toDouble(),
      minOrderAmount: (map['minOrderAmount'] as num).toDouble(),
      isActive: (map['isActive'] as int) == 1,
    );
  }

  Voucher copyWith({
    int? id,
    String? code,
    String? description,
    double? discountPercent,
    double? minOrderAmount,
    bool? isActive,
  }) {
    return Voucher(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      isActive: isActive ?? this.isActive,
    );
  }
}