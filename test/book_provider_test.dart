import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_group3_project/models/book.dart';

// ─── PURE LOGIC UNIT TESTS ────────────────────────────────────────────────────
// These tests verify the Book model and business logic without requiring
// a device or real SQLite database.

void main() {
  group('Book Model Tests', () {
    test('Book.fromMap creates a Book correctly', () {
      final map = {
        'id': 1,
        'title': 'Clean Code',
        'author': 'Robert C. Martin',
        'price': 29.99,
        'image': 'https://example.com/image.jpg',
        'description': 'A book about clean code.',
      };

      final book = Book.fromMap(map);

      expect(book.id, 1);
      expect(book.title, 'Clean Code');
      expect(book.author, 'Robert C. Martin');
      expect(book.price, 29.99);
      expect(book.image, 'https://example.com/image.jpg');
      expect(book.description, 'A book about clean code.');
    });

    test('Book.toMap converts a Book to a map correctly', () {
      final book = Book(
        id: 2,
        title: 'The Pragmatic Programmer',
        author: 'Andrew Hunt',
        price: 34.99,
        image: 'https://example.com/pragmatic.jpg',
        description: 'Your journey to mastery.',
      );

      final map = book.toMap();

      expect(map['id'], 2);
      expect(map['title'], 'The Pragmatic Programmer');
      expect(map['author'], 'Andrew Hunt');
      expect(map['price'], 34.99);
      expect(map['image'], 'https://example.com/pragmatic.jpg');
      expect(map['description'], 'Your journey to mastery.');
    });

    test('Book.copyWith returns updated book with original values preserved', () {
      final original = Book(
        id: 3,
        title: 'Original Title',
        author: 'Original Author',
        price: 10.00,
        image: 'https://example.com/img.jpg',
        description: 'Original Description',
      );

      final updated = original.copyWith(title: 'New Title', price: 19.99);

      expect(updated.id, 3);
      expect(updated.title, 'New Title');
      expect(updated.author, 'Original Author'); // unchanged
      expect(updated.price, 19.99);
      expect(updated.image, 'https://example.com/img.jpg'); // unchanged
    });

    test('Book equality is based on id', () {
      final book1 = Book(
        id: 5,
        title: 'A',
        author: 'B',
        price: 1.0,
        image: 'img',
        description: 'desc',
      );
      final book2 = Book(
        id: 5,
        title: 'Different Title',
        author: 'Different Author',
        price: 2.0,
        image: 'other',
        description: 'other desc',
      );

      expect(book1, equals(book2));
    });

    test('Books with different ids are not equal', () {
      final book1 = Book(
        id: 1,
        title: 'A',
        author: 'B',
        price: 1.0,
        image: 'img',
        description: 'desc',
      );
      final book2 = Book(
        id: 2,
        title: 'A',
        author: 'B',
        price: 1.0,
        image: 'img',
        description: 'desc',
      );

      expect(book1, isNot(equals(book2)));
    });
  });

  group('Book Price Validation Logic', () {
    double? parsePrice(String input) {
      final parsed = double.tryParse(input.trim());
      if (parsed == null || parsed <= 0) return null;
      return parsed;
    }

    test('Valid price parses correctly', () {
      expect(parsePrice('29.99'), 29.99);
      expect(parsePrice('100'), 100.0);
      expect(parsePrice('0.01'), 0.01);
    });

    test('Invalid price returns null', () {
      expect(parsePrice('abc'), isNull);
      expect(parsePrice('-5'), isNull);
      expect(parsePrice('0'), isNull);
      expect(parsePrice(''), isNull);
    });
  });

  group('Book List Simulation Tests', () {
    late List<Book> bookList;

    setUp(() {
      bookList = [
        Book(id: 1, title: 'Book One', author: 'Alice', price: 10, image: '', description: ''),
        Book(id: 2, title: 'Book Two', author: 'Bob', price: 20, image: '', description: ''),
        Book(id: 3, title: 'Flutter in Action', author: 'Charlie', price: 30, image: '', description: ''),
      ];
    });

    test('Adding a book to list increases count', () {
      final newBook = Book(
        id: 4,
        title: 'New Book',
        author: 'Dave',
        price: 15,
        image: '',
        description: '',
      );
      bookList.insert(0, newBook);
      expect(bookList.length, 4);
      expect(bookList.first.id, 4);
    });

    test('Removing a book by id removes the correct entry', () {
      bookList.removeWhere((b) => b.id == 2);
      expect(bookList.length, 2);
      expect(bookList.any((b) => b.id == 2), isFalse);
    });

    test('Updating a book modifies correctly', () {
      final index = bookList.indexWhere((b) => b.id == 1);
      bookList[index] = bookList[index].copyWith(title: 'Updated Title');
      expect(bookList[0].title, 'Updated Title');
    });

    test('Searching books by title filters correctly', () {
      final query = 'flutter';
      final results = bookList.where(
        (b) =>
            b.title.toLowerCase().contains(query.toLowerCase()) ||
            b.author.toLowerCase().contains(query.toLowerCase()),
      ).toList();

      expect(results.length, 1);
      expect(results.first.title, 'Flutter in Action');
    });

    test('Searching books with no match returns empty list', () {
      final results = bookList.where(
        (b) => b.title.toLowerCase().contains('xyz'),
      ).toList();
      expect(results, isEmpty);
    });
  });
}
