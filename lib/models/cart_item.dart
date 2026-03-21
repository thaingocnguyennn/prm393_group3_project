import 'book.dart';

class CartItem {
  final int? id;
  final int userId;
  final int bookId;
  int quantity;
  Book? book; // joined for display

  CartItem({
    this.id,
    required this.userId,
    required this.bookId,
    required this.quantity,
    this.book,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, {Book? book}) {
    return CartItem(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      bookId: map['bookId'] as int,
      quantity: map['quantity'] as int,
      book: book,
    );
  }

  CartItem copyWith({
    int? id,
    int? userId,
    int? bookId,
    int? quantity,
    Book? book,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      quantity: quantity ?? this.quantity,
      book: book ?? this.book,
    );
  }

  double get totalPrice => (book?.price ?? 0) * quantity;

  @override
  String toString() =>
      'CartItem(id: $id, bookId: $bookId, quantity: $quantity)';
}
