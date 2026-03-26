class OrderHistory {
  final int? id;
  final double totalPrice;
  final String date;
  final String fullName;
  final String address;
  final String paymentMethod;
  final String cardNumber;

  OrderHistory({
    this.id,
    required this.totalPrice,
    required this.date,
    required this.fullName,
    required this.address,
    required this.paymentMethod,
    required this.cardNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalPrice': totalPrice,
      'date': date,
      'fullName': fullName,
      'address': address,
      'paymentMethod': paymentMethod,
      'cardNumber': cardNumber,
    };
  }

  factory OrderHistory.fromMap(Map<String, dynamic> map) {
    return OrderHistory(
      id: map['id'],
      totalPrice: (map['totalPrice'] as num).toDouble(),
      date: map['date'] ?? '',
      fullName: map['fullName'] ?? '',
      address: map['address'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
    );
  }
}