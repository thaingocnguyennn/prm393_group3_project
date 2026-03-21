import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_group3_project/models/book.dart';
import 'package:prm393_group3_project/models/cart_item.dart';

void main() {
  group('CartItem Model Tests', () {
    late Book sampleBook;

    setUp(() {
      sampleBook = Book(
        id: 1,
        title: 'Clean Code',
        author: 'Robert C. Martin',
        price: 29.99,
        image: 'https://example.com/img.jpg',
        description: 'A great book',
      );
    });

    test('CartItem.fromMap creates correctly', () {
      final map = {
        'id': 10,
        'userId': 1,
        'bookId': 1,
        'quantity': 3,
      };

      final item = CartItem.fromMap(map, book: sampleBook);

      expect(item.id, 10);
      expect(item.userId, 1);
      expect(item.bookId, 1);
      expect(item.quantity, 3);
      expect(item.book, sampleBook);
    });

    test('CartItem.toMap converts correctly', () {
      final item = CartItem(
        id: 5,
        userId: 2,
        bookId: 1,
        quantity: 2,
        book: sampleBook,
      );

      final map = item.toMap();

      expect(map['id'], 5);
      expect(map['userId'], 2);
      expect(map['bookId'], 1);
      expect(map['quantity'], 2);
      // book is not part of toMap (only DB columns)
      expect(map.containsKey('book'), isFalse);
    });

    test('totalPrice calculates correctly', () {
      final item = CartItem(
        id: 1,
        userId: 1,
        bookId: 1,
        quantity: 3,
        book: sampleBook,
      );

      expect(item.totalPrice, closeTo(89.97, 0.001));
    });

    test('totalPrice is 0 when book is null', () {
      final item = CartItem(
        id: 1,
        userId: 1,
        bookId: 1,
        quantity: 5,
        book: null,
      );

      expect(item.totalPrice, 0.0);
    });

    test('CartItem.copyWith preserves unchanged fields', () {
      final item = CartItem(
        id: 1,
        userId: 1,
        bookId: 1,
        quantity: 2,
        book: sampleBook,
      );

      final updated = item.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(updated.id, 1);
      expect(updated.userId, 1);
      expect(updated.book, sampleBook);
    });
  });

  group('Cart Total Calculation Tests', () {
    test('Total price sums all cart items', () {
      final book1 = Book(
          id: 1,
          title: 'A',
          author: 'X',
          price: 10.00,
          image: '',
          description: '');
      final book2 = Book(
          id: 2,
          title: 'B',
          author: 'Y',
          price: 20.00,
          image: '',
          description: '');

      final items = [
        CartItem(id: 1, userId: 1, bookId: 1, quantity: 2, book: book1),
        CartItem(id: 2, userId: 1, bookId: 2, quantity: 1, book: book2),
      ];

      final total =
          items.fold<double>(0.0, (sum, item) => sum + item.totalPrice);

      expect(total, closeTo(40.00, 0.001));
    });

    test('Item count sums all quantities', () {
      final items = [
        CartItem(id: 1, userId: 1, bookId: 1, quantity: 3),
        CartItem(id: 2, userId: 1, bookId: 2, quantity: 2),
        CartItem(id: 3, userId: 1, bookId: 3, quantity: 1),
      ];

      final count = items.fold<int>(0, (sum, item) => sum + item.quantity);

      expect(count, 6);
    });
  });
}
