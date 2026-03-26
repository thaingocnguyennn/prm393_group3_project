class OrderHistoryItem {
  final int? id;
  final int orderId;
  final int bookId;
  final String title;
  final double price;
  final int quantity;
  final String image;

  OrderHistoryItem({
    this.id,
    required this.orderId,
    required this.bookId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.image,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'bookId': bookId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'image': image,
    };
  }

  factory OrderHistoryItem.fromMap(Map<String, dynamic> map) {
    return OrderHistoryItem(
      id: map['id'],
      orderId: map['orderId'],
      bookId: map['bookId'],
      title: map['title'] ?? '',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      image: map['image'] ?? '',
    );
  }
}